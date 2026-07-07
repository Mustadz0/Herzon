import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { verifyAppCheck } from "../_shared/appcheck.ts";

interface NotificationPayload {
  user_id: string;
  title: string;
  body: string;
  data: Record<string, string>;
}

serve(async (req) => {
  // 1. Verify App Check token (anti-abuse)
  const appCheck = await verifyAppCheck(req);
  if (!appCheck.ok) return appCheck.response;

  // 2. Verify Supabase auth
  const authHeader = req.headers.get("Authorization")!;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers: { "Content-Type": "application/json" } }
    );
  }

  // 3. Parse and validate payload
  const payload: NotificationPayload = await req.json();
  if (!payload.user_id || !payload.title || !payload.body) {
    return new Response(
      JSON.stringify({ error: "Missing required fields: user_id, title, body" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  // 4. Get device tokens
  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("fcm_token")
    .eq("user_id", payload.user_id);

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0, reason: "no_tokens" }), { status: 200 });
  }

  // 5. Send via FCM Legacy API
  const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmServerKey) {
    return new Response(JSON.stringify({ error: "FCM not configured" }), { status: 500 });
  }

  let sent = 0;
  for (const { fcm_token } of tokens) {
    try {
      const res = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          to: fcm_token,
          notification: {
            title: payload.title,
            body: payload.body,
            sound: "default",
            badge: 1,
          },
          data: payload.data ?? {},
          priority: "high",
        }),
      });
      if (res.ok) sent++;
    } catch (_) {}
  }

  // 6. Log notification to database
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
