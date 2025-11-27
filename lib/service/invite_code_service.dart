import 'dart:math';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteCodeService {
  static final client = Supabase.instance.client;

  /// 1. 초대코드 생성 (예: 938271)
  static String generateInviteCode([int length = 6]) {
    const chars = '123456789'; // 0, O 등 헷갈리는 건 제외
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// 만료 안 된 코드들 중에 이미 존재하는지 체크
  static Future<bool> _isCodeInUse(String code) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = await client
        .from('album_invite_codes')
        .select('id')
        .eq('invite_code', code)
        .gt('expires_at', now)
        .limit(1);

    return rows.isNotEmpty;
  }

  /// 2. 앨범용 초대코드 생성 & DB 저장 (유효기간 20분)
  static Future<String> createInviteCodeForAlbum(String albumId) async {
    String code;

    // 중복 없는 코드 나올 때까지 반복
    while (true) {
      code = generateInviteCode();
      if (!await _isCodeInUse(code)) break;
    }

    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(minutes: 20));

    await client.from('album_invite_codes').insert({
      'album_id': albumId,
      'invite_code': code,
      'created_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    });

    return code;
  }

  /// 3. 초대코드 유효성 확인 + 앨범 찾기
  static Future<Map<String, dynamic>?> verifyInviteCode(String code) async {
    final client = Supabase.instance.client;
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = await client
        .from('album_invite_codes')
        .select('album_id, expires_at')
        .eq('invite_code', code)
        .gt('expires_at', now) // 아직 안 만료된 것만
        .limit(1);

    if (rows.isEmpty) return null; // 코드 없거나 만료됨

    return rows.first;
  }

  /// 4. 초대코드 공유 (링크 + 코드)
  static void shareInviteCode(String code) async {
    // TODO: 나중에 todakmore 딥링크로 바꿔도 됨: todakmore://invite?code=$code
    final link = 'https://todakmore.app/invite?code=$code';

    final params = ShareParams(
      text: '토닥모아 앨범에 초대드려요 😊\n\n'
          '초대코드: $code\n'
          '👇 아래 링크를 눌러 바로 참여해 주세요\n'
          '$link',
    );

    await SharePlus.instance.share(params);
  }
}
