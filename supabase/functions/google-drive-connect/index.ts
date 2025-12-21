import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type ReqBody = {
  albumId: string;
  authCode: string;
  redirectUri: string; // Flutter에서 사용한 redirectUri 그대로
  rootFolderId?: string | null; // 선택: 이미 만들어둔 폴더가 있으면 전달
};

function json(status: number, data: unknown) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "Method Not Allowed" });

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
  const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const GOOGLE_CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID")!;
  const GOOGLE_CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET")!;

  // 1) 로그인 유저 식별(요청 Authorization 헤더 필요)
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) return json(401, { error: "Unauthorized" });
  const userId = userData.user.id;

  // 2) body 파싱
  const body = (await req.json()) as ReqBody;
  const { albumId, authCode, redirectUri } = body;
  if (!albumId || !authCode || !redirectUri) {
    return json(400, { error: "albumId/authCode/redirectUri required" });
  }

  // 3) 권한 체크(owner/manager만 연결 가능)
  const { data: member, error: memErr } = await userClient
    .from("album_members")
    .select("role")
    .eq("album_id", albumId)
    .eq("user_id", userId)
    .maybeSingle();

  if (memErr) return json(500, { error: memErr.message });
  if (!member || (member.role !== "owner" && member.role !== "manager")) {
    return json(403, { error: "Not allowed" });
  }

  // 4) Google token 교환 (auth code -> tokens)
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code: authCode,
      client_id: GOOGLE_CLIENT_ID,
      client_secret: GOOGLE_CLIENT_SECRET,
      redirect_uri: redirectUri,
      grant_type: "authorization_code",
    }),
  });

  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok) {
    return json(400, { error: "google_token_exchange_failed", detail: tokenJson });
  }

  const refreshToken = tokenJson.refresh_token as string | undefined;
  if (!refreshToken) {
    // 흔한 케이스: 이미 동의했던 계정이면 refresh_token이 안 내려올 수 있음
    // -> prompt=consent / access_type=offline 로 재요청해야 함
    return json(400, {
      error: "no_refresh_token",
      hint: "Need access_type=offline and prompt=consent to get refresh_token",
    });
  }

  // 5) DB upsert (앨범당 1개 연결)
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

  const { error: upErr } = await admin
    .from("album_drive_connection")
    .upsert({
      album_id: albumId,
      provider: "google",
      refresh_token: refreshToken,
      root_folder_id: body.rootFolderId ?? null,
      connected_by: userId,
      connected_at: new Date().toISOString(),
    });

  if (upErr) return json(500, { error: upErr.message });

  return json(200, { ok: true, provider: "google", albumId });
});
