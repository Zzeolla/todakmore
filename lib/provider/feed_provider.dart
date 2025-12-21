import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/model/media_item.dart';

class FeedProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  final List<MediaItem> _items = [];
  List<MediaItem> get items => List.unmodifiable(_items);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  static const int _pageSize = 20;
  int _page = 0;

  // ▷ 처음 로딩
  Future<void> loadInitial() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    notifyListeners();

    await _loadPage(reset: true);
  }

  // ▷ 추가 로딩 (무한 스크롤)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadPage();
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final from = _page * _pageSize;
      final to = from + _pageSize - 1;

      final response = await _client
          .from('album_medias')
          .select('''
            id,
            album_id,
            media_type,
            url,
            thumb_url,
            width,
            height,
            duration,
            created_at,
            expire_at,
            is_deleted,
            album_media_tags ( tag ),
            albums (
              id,
              name,
              cover_url
            )
          ''')
          // .eq('media_type', 'photo')                 // 일단 사진만
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> data = response;

      if (data.isEmpty) {
        _hasMore = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final now = DateTime.now();
      final List<MediaItem> newItems = [];

      for (final row in data) {
        // 소프트 삭제된 건 무시
        final isDeleted = row['is_deleted'] as bool? ?? false;
        if (isDeleted) continue;

        // expire_at 지난 건 무시 (null이면 항상 보이게)
        final expireAtStr = row['expire_at'] as String?;
        if (expireAtStr != null) {
          final expireAt = DateTime.parse(expireAtStr);
          if (!expireAt.isAfter(now)) {
            continue;
          }
        }

        final album = row['albums'];
        if (album == null) continue; // 혹시라도 조인 실패 시

        final createdAt = DateTime.parse(row['created_at'] as String).toLocal();

        final tagRows = (row['album_media_tags'] as List?) ?? const [];
        final tags = tagRows
            .map((e) => (e as Map)['tag']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();

        newItems.add(
          MediaItem(
            id: row['id'] as String,
            albumId: album['id'] as String,
            albumName: album['name'] as String? ?? '이름 없는 앨범',
            albumCoverUrl: album['cover_url'] as String? ?? '',
            mediaType: row['media_type'] as String,
            url: row['url'] as String,
            thumbUrl: row['thumb_url'] as String?,
            width: row['width'] as int?,
            height: row['height'] as int?,
            duration: (row['duration'] as num?)?.toDouble(),
            createdAt: createdAt,
            tags: tags,
          ),
        );
      }

      if (newItems.length < _pageSize) {
        _hasMore = false;
      }

      _items.addAll(newItems);
      if (newItems.isNotEmpty) {
        _page += 1;
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('FeedProvider _loadPage error: $e');
        print(st);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTags({
    required String mediaId,
    required List<String> tags,
  }) async {
    try {
      // 1) 기존 태그 전부 삭제
      await _client
          .from('album_media_tags')
          .delete()
          .eq('media_id', mediaId); // ⚠️ 컬럼명이 다르면 여기만 바꿔줘 (album_media_id 등)

      // 2) 새 태그 삽입 (비어있으면 삽입 생략 = "태그 없음" 처리)
      final cleaned = tags
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .map((t) => t.startsWith('#') ? t.substring(1) : t)
          .toSet()
          .toList();

      if (cleaned.isNotEmpty) {
        final rows = cleaned
            .map((t) => {
          'media_id': mediaId, // ⚠️ 여기도 동일
          'tag': t,
        })
            .toList();

        await _client.from('album_media_tags').insert(rows);
      }

      // 3) 로컬 리스트 갱신 (UI 즉시 반영)
      final idx = _items.indexWhere((e) => e.id == mediaId);
      if (idx != -1) {
        final old = _items[idx];
        _items[idx] = MediaItem(
          id: old.id,
          albumId: old.albumId,
          albumName: old.albumName,
          albumCoverUrl: old.albumCoverUrl,
          mediaType: old.mediaType,
          url: old.url,
          thumbUrl: old.thumbUrl,
          width: old.width,
          height: old.height,
          duration: old.duration,
          createdAt: old.createdAt,
          tags: cleaned,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('updateTags error: $e');
      rethrow;
    }
  }


  Future<void> deleteItem(String mediaId) async {
    try {
      // 1) Supabase에서 삭제 (실제로는 soft-delete or RLS 정책에 맞게)
      await _client
          .from('album_medias')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mediaId);

      // 2) 로컬 리스트에서도 제거
      _items.removeWhere((e) => e.id == mediaId);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteItem error: $e');
      // TODO: 에러 스낵바 같은 것 띄워도 좋음
    }
  }
}
