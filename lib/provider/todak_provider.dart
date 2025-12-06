import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/model/media_item.dart';
import 'package:todakmore/model/media_todak_model.dart';

class TodakProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  List<MediaTodakModel> _todakRecords = [];
  final Set<String> _todakMediaIds = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<MediaTodakModel> get todakRecords => List.unmodifiable(_todakRecords);
  bool didTodak(String mediaId) => _todakMediaIds.contains(mediaId);

  void _setInitial(List<MediaTodakModel> items) {
    _todakRecords = items;
    _todakMediaIds
      ..clear()
      ..addAll(items.map((e) => e.mediaId));
    _isLoaded = true;
    notifyListeners();
  }

  /// Splash에서 호출: 현재 앨범 기준으로 내가 토닥한 목록 로드
  Future<void> loadMyTodakRecords({
    required String userId,
  }) async {
    final rows = await _client
        .from('media_todaks')
        .select() // 전체 컬럼
        .eq('user_id', userId)
        .eq('is_deleted', false);

    final items = (rows as List)
        .map((row) => MediaTodakModel.fromMap(row as Map<String, dynamic>))
        .toList();

    _todakRecords = items;
    _todakMediaIds
      ..clear()
      ..addAll(items.map((e) => e.mediaId));
    _isLoaded = true;
    notifyListeners();
  }

  /// 로컬 상태만 토글 (UI용)
  void toggleLocal(String mediaId) {
    if (_todakMediaIds.contains(mediaId)) {
      _todakMediaIds.remove(mediaId);
      _todakRecords.removeWhere((m) => m.mediaId == mediaId);
    } else {
      _todakMediaIds.add(mediaId);
      // 필요한 최소 정보만 가진 dummy 모델 추가 (createdAt 등은 서버 기준으로 나중에 다시 로드해도 됨)
      _todakRecords.add(
        MediaTodakModel(
          id: null,
          albumId: '',   // 실제 값은 toggleTodak에서 처리하니까 여기선 비워둬도 됨
          mediaId: mediaId,
          userId: '',
          isDeleted: false,
        ),
      );
      // _todakMediaItems는 서버 응답 기반으로만 채워도 됨
    }
    notifyListeners();
  }

  /// 실제 토글 동작 (FeedCard 등에서 호출)
  /// - didTodak == false → is_deleted=false로 upsert
  /// - didTodak == true  → is_deleted=true로 update
  Future<void> toggleTodak({
    required String albumId,
    required String mediaId,
    required String userId,
    required int maxTodaks,
  }) async {
    final currentlyDid = didTodak(mediaId);

    // 🔥 토닥 ON 전 제한 체크
    if (!currentlyDid && _todakMediaIds.length >= maxTodaks) {
      throw Exception('TODAK_LIMIT_REACHED');
    }

    // 1) Optimistic UI — 즉각 반영
    if (currentlyDid) {
      _todakMediaIds.remove(mediaId);
      _todakRecords.removeWhere((m) => m.mediaId == mediaId);
    } else {
      _todakMediaIds.add(mediaId);
    }
    notifyListeners();


    try {
      if (!currentlyDid) {
        // 토닥 ON
        final row = await _client
            .from('media_todaks')
            .upsert(
              {
                'album_id': albumId,
                'media_id': mediaId,
                'user_id': userId,
                'is_deleted': false,
              },
              onConflict: 'media_id, user_id',
            )
            .select()
            .single();
        final model = MediaTodakModel.fromMap(row);

        _todakRecords.removeWhere((m) => m.mediaId == mediaId);
        _todakRecords.add(model);
      } else {
        // 토닥 OFF
        await _client
            .from('media_todaks')
            .update({'is_deleted': true})
            .eq('album_id', albumId)
            .eq('media_id', mediaId)
            .eq('user_id', userId);
      }
    } catch (e) {
      // 3) 실패 시 롤백
      if (currentlyDid) {
        _todakMediaIds.add(mediaId);
      } else {
        _todakMediaIds.remove(mediaId);
        _todakRecords.removeWhere((m) => m.mediaId == mediaId);
      }

      notifyListeners();
      rethrow;
    }
  }

  Future<List<MediaItem>> fetchTodakMediaItems({
    required String userId,
  }) async {
    final rows = await _client
        .from('media_todaks')
        .select('''
        *,
        album_medias (
          id,
          album_id,
          url,
          thumb_url,
          media_type,
          width,
          height,
          duration,
          created_at,
          albums (
            name,
            cover_url
          )
        )
      ''')
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    final List<MediaItem> items = [];

    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final media = map['album_medias'] as Map<String, dynamic>?;

      // 혹시 조인된 media가 null인 데이터는 스킵
      if (media == null) continue;

      final album = media['albums'] as Map<String, dynamic>?;

      items.add(MediaItem(
        id: media['id'],
        albumId: media['album_id'],
        albumName: (album?['name'] as String?) ?? '',
        albumCoverUrl: (album?['cover_url'] as String?) ?? '',
        mediaType: media['media_type'],
        url: media['url'],
        thumbUrl: media['thumb_url'],
        width: media['width'],
        height: media['height'],
        duration: (media['duration'] as num?)?.toDouble(),
        createdAt: DateTime.parse(media['created_at']),
      ));
    }

    return items;
  }


  /// 앨범 변경될 때 호출해서 상태 초기화
  void reset() {
    _todakRecords = [];
    _todakMediaIds.clear();
    _isLoaded = false;
    notifyListeners();
  }
}
