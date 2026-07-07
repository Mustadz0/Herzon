/**
 * Firebase App Check Token Verification Middleware
 * 
 * Verifies Firebase App Check tokens (Play Integrity) before
 * allowing access to protected Edge Functions.
 * 
 * Usage in any Edge Function:
 *   import { verifyAppCheck } from "../_shared/appcheck.ts";
 *   const verification = await verifyAppCheck(req);
 *   if (!verification.ok) return verification.response;
 */

const APP_CHECK_DEBUG = Deno.env.get("APP_CHECK_DEBUG") === "true";

interface AppCheckPayload {
  sub: string;
  app_id: string;
  token_verification: {
    play_integrity?: {
      token_result?: string;
    };
  };
}

/**
 * Verify Firebase App Check token from request header.
 * Returns { ok: true } if valid, or { ok: false, response } if invalid.
 */
export async function verifyAppCheck(
  req: Request
): Promise<{ ok: boolean; response?: Response; userId?: string }> {
  const appCheckToken = req.headers.get("X-Firebase-AppCheck");

  if (!appCheckToken) {
    if (APP_CHECK_DEBUG) {
      console.log("App Check: No token provided, allowing in debug mode");
      return { ok: true };
    }
    return {
      ok: false,
      response: new Response(
        JSON.stringify({ error: "App Check token required" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      ),
    };
  }

  try {
    // Verify the App Check token via Firebase App Check API
    const projectId = Deno.env.get("FCM_PROJECT_ID") ?? "hoyzen-7fad5";
    const verifyRes = await fetch(
      `https://firebaseappcheck.googleapis.com/v1/projects/${projectId}/apps:exchangeToken`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          app_check_token: appCheckToken,
          missing_resource_types: [],
        }),
      }
    );

    if (!verifyRes.ok) {
      const errorText = await verifyRes.text();
      console.error(`App Check verification failed: ${verifyRes.status} - ${errorText}`);
      return {
        ok: false,
        response: new Response(
          JSON.stringify({ error: "Invalid App Check token" }),
          { status: 403, headers: { "Content-Type": "application/json" } }
        ),
      };
    }

    const payload: AppCheckPayload = await verifyRes.json();
    console.log(`App Check verified for app: ${payload.app_id}`);
    return { ok: true, userId: payload.sub };
  } catch (e) {
    console.error(`App Check error: ${e}`);
    if (APP_CHECK_DEBUG) {
      return { ok: true };
    }
    return {
      ok: false,
      response: new Response(
        JSON.stringify({ error: "App Check verification failed" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      ),
    };
  }
}

/**
 * Get Supabase user from Authorization header.
 */
export async function getSupabaseUser(req: Request): Promise<{ userId: string } | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  try {
    const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        Authorization: authHeader,
        apikey: supabaseAnonKey,
      },
    });
    if (!res.ok) return null;
    const user = await res.json();
    return { userId: user.id };
  } catch {
    return null;
  }
}
