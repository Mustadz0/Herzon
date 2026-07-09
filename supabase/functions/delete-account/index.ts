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

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing authorization" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);

  await removeUserStorage(admin, user.id);

  const { error: profileError } = await admin
    .from("profiles")
    .delete()
    .eq("id", user.id);
  if (profileError) {
    return jsonResponse({ error: profileError.message }, 500);
  }

  const { error: deleteUserError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteUserError) {
    return jsonResponse({ error: deleteUserError.message }, 500);
  }

  return jsonResponse({ deleted: true });
});
