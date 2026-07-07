import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

interface JeSuisLaPayload {
  userId: string;
  userName: string;
  zoneName: string;
}

function isValidPayload(obj: unknown): obj is JeSuisLaPayload {
  if (typeof obj !== "object" || obj === null) return false;
  const p = obj as Record<string, unknown>;
  return (
    typeof p.userId === "string" &&
    p.userId.length > 0 &&
    typeof p.userName === "string" &&
    typeof p.zoneName === "string"
  );
}

serve(async (req) => {
  // 1. Get auth header
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization" }), { status: 401 });
  }

  // 2. Create client with user JWT
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  // 3. Verify the user is authenticated
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  // 4. Validate request body
  let payload: JeSuisLaPayload;
  try {
    const body = await req.json();
    if (!isValidPayload(body)) {
      return new Response(JSON.stringify({ error: "Invalid payload" }), { status: 400 });
    }
    payload = body;
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400 });
  }

  const { userId, userName, zoneName } = payload;

  // 5. Use service role for privileged queries
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // 6. Verify the user exists
  const { data: userExists, error: userErr } = await admin
    .from("profiles")
    .select("id")
    .eq("id", userId)
    .maybeSingle();

  if (userErr || !userExists) {
    return new Response(JSON.stringify({ error: "Invalid user" }), { status: 403 });
  }

  // 7. Get all followers (Fans) and following (Cercle)
  const { data: follows, error: followErr } = await admin
    .from("follows")
    .select("follower_id, following_id")
    .or(`follower_id.eq.${userId},following_id.eq.${userId}`);

  if (followErr) {
    return new Response(JSON.stringify({ error: followErr.message }), { status: 500 });
  }

  const targetIds = new Set<string>();
  for (const row of follows ?? []) {
    if (row.follower_id !== userId) targetIds.add(row.follower_id);
    if (row.following_id !== userId) targetIds.add(row.following_id);
  }

  if (targetIds.size === 0) {
    return new Response(JSON.stringify({ notified: 0 }), { status: 200 });
  }

  // 8. Get device tokens
  const { data: devices, error: deviceErr } = await admin
    .from("device_tokens")
    .select("fcm_token, platform")
    .in("user_id", Array.from(targetIds));

  if (deviceErr) {
    return new Response(JSON.stringify({ error: deviceErr.message }), { status: 500 });
  }

  const tokens = (devices ?? []).map((d: any) => d.fcm_token).filter(Boolean);

  // 9. Insert in-app notifications
  const notifications = Array.from(targetIds).map((targetId) => ({
    user_id: targetId,
    type: "je_suis_la",
    title: `${userName} est à ${zoneName}`,
    body: `${userName} est à ${zoneName} maintenant — venez !`,
    data: { user_id: userId },
  }));
  await admin.from("notifications").insert(notifications);

  // 10. Send FCM push notifications
  const fcmKey = Deno.env.get("FCM_SERVER_KEY");
  if (fcmKey && tokens.length > 0) {
    for (const token of tokens) {
      try {
        await fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `key=${fcmKey}`,
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title: `${userName} est là !`,
              body: `${userName} est à ${zoneName} maintenant — venez !`,
              sound: "default",
            },
            data: {
              type: "je_suis_la",
              user_id: userId,
            },
          }),
        });
      } catch (_) {}
    }
  }

  return new Response(
    JSON.stringify({ notified: targetIds.size, pushSent: tokens.length }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
