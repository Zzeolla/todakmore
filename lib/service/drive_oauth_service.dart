import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriveOauthService {
  static final _client = Supabase.instance.client;

  /// ✅ 구글 드라이브 백업을 위한 refresh_token 확보
  /// - 이미 있으면 즉시 반환
  /// - 없으면 Google identity link(OAuth 동의창) 수행 후 반환
  static Future<String> ensureGoogleDriveRefreshToken() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');

    // 1) 이미 세션에 refresh token이 있으면 바로 사용
    final existing = _client.auth.currentSession?.providerRefreshToken;
    if (existing != null && existing.isNotEmpty) return existing;

    // 2) 없으면 Google identity 연결 (필요하면 동의창 뜸)
    final completer = Completer<String>();

    late final StreamSubscription sub;
    sub = _client.auth.onAuthStateChange.listen((data) async {
      final token = data.session?.providerRefreshToken;
      if (token != null && token.isNotEmpty && !completer.isCompleted) {
        completer.complete(token);
        await sub.cancel();
      }
    });

    await _client.auth.linkIdentity(
      OAuthProvider.google,
      redirectTo: 'todakmore://login-callback',
      scopes: 'https://www.googleapis.com/auth/drive.file',
      queryParams: const {
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );

    // 동의/리다이렉트 완료되면 onAuthStateChange에서 token을 받음
    final token = await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () async {
        await sub.cancel();
        throw Exception('Google 인증이 완료되지 않았습니다. (timeout)');
      },
    );

    return token;
  }
}
