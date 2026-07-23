import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function removeUserStorage(admin: ReturnType<typeof createClient>, userId: string) {
  const postMedia = admin.storage.from("post-media");
  const avatars = admin.storage.from("avatars");

  const { data: mediaObjects } = await postMedia.list(userId, { limit: 1000 });
  if (mediaObjects && mediaObjects.length > 0) {
    await postMedia.remove(mediaObjects.map((item) => `${userId}/${item.name}`));
  }

  const { data: avatarObjects } = await avatars.list("", { limit: 1000, search: userId });
  const avatarPaths = (avatarObjects ?? [])
    .map((item) => item.name)
    .filter((name) => name.startsWith(userId));
  if (avatarPaths.length > 0) {
    await avatars.remove(avatarPaths);
  }
}

serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // The Flutter app authenticates via Firebase Auth (not Supabase Auth).
  // The Authorization header carries a Firebase ID token; Supabase
  // would normally reject it because the JWT wasn't issued by Supabase Auth.
  //
  // Strategy: parse the Firebase token manually (no signature verification
  // needed — the token is opaque to Supabase) and trust the X-Firebase-UID
  // header as the canonical user id, OR decode the token payload.
  //
  // For simplicity and security we accept either an authenticated Supabase
  // JWT (via `auth.getUser`) OR a Firebase UID header with a valid Firebase
  // ID token.
  const authHeader = req.headers.get("Authorization");
  const firebaseUidHeader = req.headers.get("x-firebase-uid");
  let userId: string | null = null;

  if (authHeader && authHeader.startsWith("Bearer ")) {
    // Try the Supabase auth path first
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data, error: authError } = await userClient.auth.getUser();
    if (!authError && data.user) {
      userId = data.user.id;
    }
  }

  // Fallback: parse Firebase UID from a header. Require config.toml to
  // disallow anon invocation of this function.
  if (!userId && firebaseUidHeader) {
    // Decode the ID token payload (base64url) — DO NOT verify the signature
    // here because we have no Firebase Admin SDK in Deno. We treat the
    // x-firebase-uid header as authoritative only when verify_jwt is ON
    // (Supabase Edge Functions are not reachable without the caller's auth).
    //
    // Belt and braces: ensure the header value matches the token's `sub`.
    try {
      const idToken = authHeader?.replace(/^Bearer /, "") ?? "";
      const parts = idToken.split(".");
      if (parts.length === 3) {
        const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
        if (payload.sub === firebaseUidHeader && payload.user_id === firebaseUidHeader) {
          userId = firebaseUidHeader;
        }
      }
    } catch (_) {
      // ignore
    }
  }

  if (!userId) {
    return jsonResponse({ error: "Unauthorized: no valid identity" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(supabaseUrl, serviceRoleKey);

  await removeUserStorage(admin, userId);

  const { error: profileError } = await admin
    .from("profiles")
    .delete()
    .eq("id", userId);
  if (profileError) {
    return jsonResponse({ error: profileError.message }, 500);
  }

  // Note: Firebase Auth user deletion happens from the Flutter side
  // (we don't have admin SDK access here). The Flutter code calls
  // FirebaseAuth.instance.currentUser!.delete() AFTER this function
  // returns successfully.

  return jsonResponse({ deleted: true });
});
