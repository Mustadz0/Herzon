import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { verifyAppCheck } from "../_shared/appcheck.ts";
import { sendFcmV1 } from "../_shared/fcm.ts";

interface NotificationPayload {
  user_id: string;
  title: string;
  body: string;
  data: Record<string, string>;
}

serve(async (req) => {
  const appCheck = await verifyAppCheck(req);
  if (!appCheck.ok) return appCheck.response;

  const authHeader = req.headers.get("Authorization")!;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { "Content-Type": "application/json" } });
  }

  const payload: NotificationPayload = await req.json();
  if (!payload.user_id || !payload.title || !payload.body) {
    return new Response(JSON.stringify({ error: "Missing required fields: user_id, title, body" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("fcm_token")
    .eq("user_id", payload.user_id);

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0, reason: "no_tokens" }), { status: 200 });
  }

  let sent = 0;
  for (const { fcm_token } of tokens) {
    try {
      const ok = await sendFcmV1(fcm_token, { title: payload.title, body: payload.body }, payload.data);
      if (ok) sent++;
    } catch (_) {}
  }

  try {
    await supabase.from("notifications").insert({
      user_id: payload.user_id,
      title: payload.title,
      body: payload.body,
      type: payload.data?.type ?? "general",
    });
  } catch (_) {}

  return new Response(JSON.stringify({ sent, app_check: appCheck.ok }), { status: 200 });
});
