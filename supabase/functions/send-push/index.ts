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

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function isInternalRequest(req: Request) {
  const expected = Deno.env.get("INTERNAL_FUNCTION_SECRET");
  const provided = req.headers.get("X-Internal-Function-Secret");
  return Boolean(expected && provided && provided === expected);
}

serve(async (req) => {
  const internal = isInternalRequest(req);

  if (!internal) {
    const appCheck = await verifyAppCheck(req);
    if (!appCheck.ok) return appCheck.response;
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (!internal && (authError || !user)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const payload: NotificationPayload = await req.json();
  if (!payload.user_id || !payload.title || !payload.body) {
    return jsonResponse({ error: "Missing required fields: user_id, title, body" }, 400);
  }

  if (!internal && payload.user_id !== user?.id) {
    return jsonResponse({ error: "Cannot send notifications to another user" }, 403);
  }

  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("fcm_token")
    .eq("user_id", payload.user_id);

  if (!tokens || tokens.length === 0) {
    return jsonResponse({ sent: 0, reason: "no_tokens" });
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

  return jsonResponse({ sent, internal });
});
