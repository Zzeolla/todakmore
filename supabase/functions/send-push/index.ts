// 타입 보완(자동완성 도움)
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// TODO: 나중에 토큰당 하나씩 보내는걸 여러개 보내는 구조로 변경 + 함수 호출마다 getAccessToken() 돌아가는거 캐싱??

/** Base64 문자열을 Uint8Array로 */
function b64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const arr = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}

/** 객체를 base64url 로 인코딩 */
function toBase64Url(obj: unknown): string {
  const json = JSON.stringify(obj);
  const b64 = btoa(json);
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string; // -----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----
}

/** 서비스계정으로 OAuth2 access_token 발급 (scope: firebase.messaging) */
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600, // 1시간
  };

  const headerB64 = toBase64Url(header);
  const payloadB64 = toBase64Url(payload);
  const unsigned = `${headerB64}.${payloadB64}`;

  // PEM → PKCS8 DER bytes
  const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\r|\n/g, "");
  const der = b64ToBytes(pem);

  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");

  const jwt = `${unsigned}.${sigB64}`;

  // JWT → access_token 교환
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const json = await res.json();
  if (!json.access_token) throw new Error("Failed to get access token: " + JSON.stringify(json));
  return json.access_token as string;
}

Deno.serve(async (req) => {
  // DB 트리거가 보내는 간단 인증
  const requiredKey = Deno.env.get("TODAKMORE_SECRET");
  if (!requiredKey || req.headers.get("x-api-key") !== requiredKey) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    // DB에서 넘어오는 페이로드
    const { tokens = [], title = "토닥모아", body = "", data = {} } = await req.json();
    if (!Array.isArray(tokens) || tokens.length === 0) {
      return new Response(JSON.stringify({ ok: true, sent: 0 }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 서비스 계정 JSON(Base64) 읽기 & 파싱
    const saB64 = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON_BASE64");
    if (!saB64) return new Response("Missing GOOGLE_SERVICE_ACCOUNT_JSON_BASE64", { status: 500 });
    const sa: ServiceAccount = JSON.parse(new TextDecoder().decode(b64ToBytes(saB64)));

    // OAuth 토큰 발급
    const accessToken = await getAccessToken(sa);

    // FCM v1 엔드포인트
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    const results: any[] = [];

    // 토큰별로 1건씩 발송 (간단/확실)
    for (const token of tokens) {
      const payload = {
        message: {
          token,
          notification: { title, body },
          data, // 앱에서 추가 데이터 핸들링
        },
      };

      const res = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${accessToken}`,
        },
        body: JSON.stringify(payload),
      });

      const json = await res.json().catch(() => ({}));
      results.push({ token, status: res.status, res: json });
    }

    return new Response(JSON.stringify({ ok: true, sent: results.length, results }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
