import 'package:supabase_flutter/supabase_flutter.dart';
import 'drive_oauth_service.dart';

class DriveConnectionService {
  static final _client = Supabase.instance.client;

  static Future<void> connectGoogleDrive({
    required String albumId,
  }) async {
    final refreshToken = await DriveOauthService.ensureGoogleDriveRefreshToken();

    final res = await _client.functions.invoke(
      'google-drive-connect',
      body: {
        'album_id': albumId,
        'provider': 'google_drive',
        'refresh_token': refreshToken,
      },
    );

    // invoke는 status가 200대가 아니어도 data로 에러가 올 수 있어서 방어
    if (res.status < 200 || res.status >= 300) {
      throw Exception('google-drive-connect 실패: ${res.data}');
    }
  }
}
