/**
 * FCM HTTP v1 API helper for Supabase Edge Functions.
 * Replaces the deprecated FCM Legacy API (fcm/send).
 *
 * Usage:
 *   import { sendFcmV1 } from "../_shared/fcm.ts";
 *   await sendFcmV1(token, { title, body }, { type: "message", ... });
 */

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "hoyzen-7fad5";
const FCM_SERVICE_ACCOUNT = Deno.env.get("FCM_SERVICE_ACCOUNT");

interface FcmNotification {
  title: string;
  body: string;
  image?: string;
}

interface FcmData {
  [key: string]: string;
}

let _cachedToken: { token: string; expiresAt: number } | null = null;

async function getAccessToken(): Promise<string> {
  if (_cachedToken && _cachedToken.expiresAt > Date.now()) {
    return _cachedToken.token;
  }

  if (!FCM_SERVICE_ACCOUNT) {
    throw new Error("FCM_SERVICE_ACCOUNT environment variable not set");
  }

  const sa = JSON.parse(FCM_SERVICE_ACCOUNT);
  const { client_email, private_key } = sa;
  const now = Math.floor(Date.now() / 1000);
  const jwtHeader = { alg: "RS256", typ: "JWT" };
  const jwtPayload = {
    iss: client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const base64 = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const header = base64(jwtHeader);
  const payload = base64(jwtPayload);
  const signingInput = `${header}.${payload}`;

  const keyData = private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    await crypto.subtle.importKey("pkcs8", binaryKey, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]),
    new TextEncoder().encode(signingInput),
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const jwt = `${signingInput}.${signatureB64}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(`OAuth2 error: ${data.error} - ${data.error_description}`);

  _cachedToken = { token: data.access_token, expiresAt: now + data.expires_in * 1000 - 300 };
  return data.access_token;
}

export async function sendFcmV1(
  token: string,
  notification: FcmNotification,
  data?: FcmData,
): Promise<boolean> {
  try {
    const accessToken = await getAccessToken();

    const message: Record<string, unknown> = {
      token,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channel_id: "herzon_default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    if (notification.image) {
      (message.notification as Record<string, string>).image = notification.image;
    }

    if (data && Object.keys(data).length > 0) {
      message.data = data;
    }

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({ message }),
      },
    );

    if (!res.ok) {
      const errText = await res.text();
      console.error(`FCM v1 error: ${res.status} - ${errText}`);
      return false;
    }
    return true;
  } catch (e) {
    console.error(`FCM v1 exception:`, e);
    return false;
  }
}
