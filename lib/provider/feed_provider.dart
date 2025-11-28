import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/model/feed_item.dart';

class FeedProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  final List<FeedItem> _items = [];
  List<FeedItem> get items => List.unmodifiable(_items);

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
            albums (
              id,
              name,
              cover_url
            )
          ''')
          .eq('media_type', 'photo')                 // 일단 사진만
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
      final List<FeedItem> newItems = [];

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

        final createdAt = DateTime.parse(row['created_at'] as String);

        newItems.add(
          FeedItem(
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
}
