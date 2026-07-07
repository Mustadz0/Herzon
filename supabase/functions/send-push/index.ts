import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

interface NotificationPayload {
  user_id: string;
  title: string;
  body: string;
  data: Record<string, string>;
}

serve(async (req) => {
  const authHeader = req.headers.get("Authorization")!;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const payload: NotificationPayload = await req.json();

  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("fcm_token")
    .eq("user_id", payload.user_id);

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
  }

  const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmServerKey) {
    return new Response(JSON.stringify({ error: "FCM not configured" }), { status: 200 });
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
          data: payload.data,
          priority: "high",
        }),
      });
      if (res.ok) sent++;
    } catch (_) {}
  }

  return new Response(JSON.stringify({ sent }), { status: 200 });
});
