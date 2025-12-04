import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  static final _supabase = Supabase.instance.client;

  /// 앨범에 새 사진 추가 알림
  ///
  /// - created_by: 업로더 (현재 유저)
  /// - target_user_id: 해당 앨범의 다른 모든 멤버 (나 제외)
  /// - title/body: 앨범 이름 포함
  /// - data: { albumId: ... }
  static Future<void> sendNewPhotoAdded({
    required String albumId,
    required String albumName,
    required String createdByUserId,
  }) async {
    // 1) 이 앨범에 속한 멤버 전부 조회 (owner/manager/viewer 포함)
    final membersRes = await _supabase
        .from('album_members')
        .select('user_id')
        .eq('album_id', albumId);

    // 2) 나를 제외한 유저들만 타겟
    final targetUserIds = <String>[];
    for (final row in membersRes as List) {
      final userId = row['user_id'] as String?;
      if (userId != null && userId != createdByUserId) {
        targetUserIds.add(userId);
      }
    }

    if (targetUserIds.isEmpty) {
      // 나 혼자 있는 앨범이면 알림 보낼 필요 없음
      return;
    }

    // 3) 여러 명에게 한 번에 insert
    final rows = targetUserIds.map((targetId) {
      return {
        'created_by': createdByUserId,
        'target_user_id': targetId,
        'title': '새 사진 추가!',
        'body': '[$albumName] 앨범에 새 사진이 추가되었어요 😊',
      };
    }).toList();

    await _supabase.from('notification_requests').insert(rows);
  }
}
