import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { verifyAppCheck } from "../_shared/appcheck.ts";
import { sendFcmV1 } from "../_shared/fcm.ts";

interface JeSuisLaPayload {
  zoneName: string;
}

function isValidPayload(obj: unknown): obj is JeSuisLaPayload {
  if (typeof obj !== "object" || obj === null) return false;
  const p = obj as Record<string, unknown>;
  return typeof p.zoneName === "string" && p.zoneName.trim().length > 0;
}

serve(async (req) => {
  const appCheck = await verifyAppCheck(req);
  if (!appCheck.ok) return appCheck.response;

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing authorization" }), { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

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

  const userId = user.id;
  const zoneName = payload.zoneName.trim().slice(0, 80);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: profile, error: userErr } = await admin
    .from("profiles")
    .select("id, display_name, username")
    .eq("id", userId)
    .maybeSingle();

  if (userErr || !profile) {
    return new Response(JSON.stringify({ error: "Invalid user" }), { status: 403 });
  }

  const userName = profile.display_name || profile.username || "Quelqu'un";

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

  const { data: devices, error: deviceErr } = await admin
    .from("device_tokens")
    .select("fcm_token, platform")
    .in("user_id", Array.from(targetIds));

  if (deviceErr) {
    return new Response(JSON.stringify({ error: deviceErr.message }), { status: 500 });
  }

  const tokens = (devices ?? []).map((d: any) => d.fcm_token).filter(Boolean);

  const notifications = Array.from(targetIds).map((targetId) => ({
    user_id: targetId,
    type: "je_suis_la",
    title: `${userName} est a ${zoneName}`,
    body: `${userName} est a ${zoneName} maintenant - venez !`,
    data: { user_id: userId },
  }));
  await admin.from("notifications").insert(notifications);

  let sent = 0;
  for (const token of tokens) {
    try {
      const ok = await sendFcmV1(
        token,
        { title: `${userName} est la !`, body: `${userName} est a ${zoneName} maintenant - venez !` },
        { type: "je_suis_la", user_id: userId },
      );
      if (ok) sent++;
    } catch (_) {}
  }

  return new Response(
    JSON.stringify({ notified: targetIds.size, pushSent: sent }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
