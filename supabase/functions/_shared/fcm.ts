const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "hoyzen-7fad5";
const FCM_SERVICE_ACCOUNT = Deno.env.get("FCM_SERVICE_ACCOUNT");
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY");

interface FcmNotification {
  title: string;
  body: string;
  image?: string;
}

interface FcmData {
  [key: string]: string;
}

let _cachedToken: { token: string; expiresAt: number } | null = null;

async function _getAccessTokenV1(): Promise<string> {
  if (!FCM_SERVICE_ACCOUNT) {
    throw new Error("no_service_account");
  }

  if (_cachedToken && _cachedToken.expiresAt > Date.now()) {
    return _cachedToken.token;
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

async function _sendV1(
  token: string,
  notification: FcmNotification,
  data?: FcmData,
): Promise<boolean> {
  const accessToken = await _getAccessTokenV1();

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
}

async function _sendLegacy(
  token: string,
  notification: FcmNotification,
  data?: FcmData,
): Promise<boolean> {
  const body: Record<string, unknown> = {
    to: token,
    priority: "high",
    notification: {
      title: notification.title,
      body: notification.body,
      sound: "default",
      channel_id: "herzon_default",
    },
  };

  if (data && Object.keys(data).length > 0) {
    body.data = data;
  }

  const res = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `key=${FCM_SERVER_KEY}`,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`FCM legacy error: ${res.status} - ${errText}`);
    return false;
  }
  return true;
}

export async function sendFcmV1(
  token: string,
  notification: FcmNotification,
  data?: FcmData,
): Promise<boolean> {
  if (FCM_SERVICE_ACCOUNT) {
    try {
      return await _sendV1(token, notification, data);
    } catch (e) {
      console.error("FCM v1 failed, falling back to legacy:", e);
    }
  }

  if (FCM_SERVER_KEY) {
    return await _sendLegacy(token, notification, data);
  }

  console.error("No FCM credentials configured (neither FCM_SERVICE_ACCOUNT nor FCM_SERVER_KEY)");
  return false;
}
