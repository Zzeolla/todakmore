import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/model/album_member_model.dart';
import 'package:todakmore/model/album_member_with_user_model.dart';
import 'package:todakmore/model/album_model.dart';
import 'package:todakmore/model/album_with_my_info_model.dart';

class AlbumProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  List<AlbumWithMyInfoModel> _albums = [];
  AlbumWithMyInfoModel? _selectedAlbum;
  bool _isLoading = false;
  String? _errorMessage;

  // ───────── getters ─────────
  List<AlbumWithMyInfoModel> get albums => List.unmodifiable(_albums);
  AlbumWithMyInfoModel? get selectedAlbum => _selectedAlbum;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedAlbumId => _selectedAlbum?.id;
  String? get selectedAlbumName => _selectedAlbum?.name;
  List<AlbumWithMyInfoModel> get manageAlbums => _albums.where(_isManageRole).toList(growable: false);

  bool _isManageRole(AlbumWithMyInfoModel album) {
    return album.myRole == 'owner' || album.myRole == 'manager';
  }
  // 🔥 albumId로 내가 owner/manager 인지 바로 판단
  bool canManageAlbumId(String albumId) {
    try {
      final album = _albums.firstWhere((a) => a.id == albumId);
      return _isManageRole(album);
    } catch (_) {
      return false;
    }
  }

  // ───────── 내부 상태 업데이트 헬퍼 ─────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // ───────── 1) 앨범 목록 불러오기 ─────────
  Future<void> loadAlbums({String? preferredAlbumId}) async {
    _setLoading(true);
    _setError(null);

    try {
      // RLS 때문에 현재 auth.uid() 기준으로만 자동 필터됨
      final List<dynamic> data = await _client
          .from('albums_with_my_info')
          .select()
          .order('created_at', ascending: false);

      _albums = data
          .map((row) => AlbumWithMyInfoModel.fromMap(row as Map<String, dynamic>))
          .toList();

      if (_albums.isEmpty) {
        _selectedAlbum = null;
      } else {
        if (preferredAlbumId != null) {
          try {
            _selectedAlbum = _albums.firstWhere((a) => a.id == preferredAlbumId);
          } catch (_) {
            _selectedAlbum ??= _albums.first;
          }
        } else {
          _selectedAlbum ??= _albums.first;
        }
      }

      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        print('loadAlbums error: $e\n$st');
      }
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ───────── 2) 앨범 생성 ─────────
  Future<AlbumWithMyInfoModel?> createAlbum({
    required String name,
    String? ownerLabel,
    Uint8List? coverBytes,
  }) async {
    _setError(null);

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('로그인된 유저가 없습니다.');
      }

      // 1) 우선 앨범 row만 생성 (cover_url 없이)
      final Map<String, dynamic> insertResult = await _client
          .from('albums')
          .insert({
            'created_by': user.id,
            'name': name,
          })
          .select()
          .single();

      var baseAlbum = AlbumModel.fromMap(insertResult);
      final String albumId = baseAlbum.id;

      // 2) 커버 파일이 있으면 스토리지 업로드 후 cover_url 업데이트
      String? coverUrl;

      if (coverBytes != null) {
        final storage = _client.storage.from('todak-media');

        // 파일 이름: {albumId}/cover_타임스탬프.jpg
        final fileName =
            'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'album_covers/$albumId/$fileName'; // ✅ 지금 사용 중인 경로 구조

        // 업로드
        await storage.uploadBinary(
          filePath,
          coverBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg', // 필요하면 확장자 보고 동적으로 바꿔도 됨
          ),
        );

        // public URL 생성 (버킷이 public이라는 전제)
        coverUrl = storage.getPublicUrl(filePath);

        // DB에 cover_url 업데이트 후 최신 데이터 다시 가져오기
        final Map<String, dynamic> updatedMap = await _client
            .from('albums')
            .update({'cover_url': coverUrl})
            .eq('id', albumId)
            .select()
            .single();

        baseAlbum = AlbumModel.fromMap(updatedMap);
      }

      // 3) album_members 에 owner 추가 (한 번만!)
      final ownerMember = AlbumMemberModel(
        albumId: baseAlbum.id,
        userId: user.id,
        role: 'owner',
        label: ownerLabel,
      );

      await _client.from('album_members').insert(ownerMember.toInsertMap());

      // 4) Provider 내부 상태 업데이트
      final wrapped = AlbumWithMyInfoModel(
        album: baseAlbum,
        myRole: 'owner',
        myLabel: ownerLabel,
      );

      // 리스트 맨 앞에 추가 (최근 생성 앨범이 위로 오게)
      _albums.insert(0, wrapped);
      // 첫 앨범일 경우 자동 선택
      _selectedAlbum ??= wrapped;

      notifyListeners();
      return wrapped;
    } catch (e, st) {
      if (kDebugMode) {
        print('createAlbum error: $e\n$st');
      }
      _setError(e.toString());
      return null;
    }
  }

  // ───────── 3) 앨범 선택 ─────────
  Future<void> selectAlbum(AlbumWithMyInfoModel album) async {
    _selectedAlbum = album;
    notifyListeners();
  }

  void selectAlbumById(String id) {
    try {
      final found = _albums.firstWhere((a) => a.id == id);
      _selectedAlbum = found;
      notifyListeners();
    } catch (_) {
      // 못 찾으면 아무 것도 안 바꿈 (혹은 null로 초기화하고 싶으면 여기서 처리)
    }
  }

  // ───────── 4) 대표 이미지 변경 ─────────
  Future<void> updateAlbumCover({
    required String albumId,
    String? coverUrl,
    Uint8List? coverBytes,
  }) async {
    _setError(null);

    try {
      String? finalUrl = coverUrl;

      // 1) coverBytes가 넘어오면 먼저 업로드
      if (coverBytes != null) {
        final storage = _client.storage.from('todak-media');

        final fileName =
            'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'album_covers/$albumId/$fileName';

        await storage.uploadBinary(
          filePath,
          coverBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

        finalUrl = storage.getPublicUrl(filePath);
      }

      if (finalUrl == null) {
        throw Exception('coverUrl 또는 coverBytes 중 하나는 반드시 필요합니다.');
      }

      // 2) albums.cover_url 업데이트
      final Map<String, dynamic> result = await _client
          .from('albums')
          .update({'cover_url': finalUrl})
          .eq('id', albumId)
          .select()
          .single();

      final updatedAlbum = AlbumModel.fromMap(result);

      final index = _albums.indexWhere((a) => a.id == albumId);
      if (index != -1) {
        final old = _albums[index];
        _albums[index] = old.copyWith(album: updatedAlbum);
      }

      if (_selectedAlbum?.id == albumId) {
        _selectedAlbum = _albums[index];
      }

      notifyListeners();

    } catch (e, st) {
      if (kDebugMode) {
        print('updateAlbumCover error: $e\n$st');
      }
      _setError(e.toString());
    }
  }

// AlbumProvider 안에 추가
  Future<List<AlbumMemberWithUserModel>> fetchAlbumMembers(String albumId) async {
    try {
      final List<dynamic> rows = await _client
          .from('album_members')
          .select('''
          id,
          album_id,
          user_id,
          role,
          label,
          joined_at,
          updated_at,
          users (
            id,
            display_name,
            created_at,
            last_album_id
          )
        ''')
          .eq('album_id', albumId)
          .order('joined_at', ascending: true);

      return rows
          .map((row) =>
          AlbumMemberWithUserModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      if (kDebugMode) {
        print('fetchAlbumMembers error: $e\n$st');
      }
      _setError(e.toString());
      rethrow; // 다이얼로그 쪽에서 처리할 수 있게
    }
  }

  Future<void> updateMemberRole({
    required String albumId,
    required String memberId, // album_members.id
    required String newRole,  // 'manager' 또는 'viewer'
  }) async {
    try {
      await _client
          .from('album_members')
          .update({'role': newRole})
          .eq('id', memberId)
          .eq('album_id', albumId);

      // 내부 _albums 갱신할 필요는 없음 (myRole 은 그 앨범에 대한 "나"의 역할이라
      // 다른 멤버 권한 변경과는 무관함)
    } catch (e, st) {
      if (kDebugMode) {
        print('updateMemberRole error: $e\n$st');
      }
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> removeMember({
    required String albumId,
    required String memberId, // album_members.id
  }) async {
    try {
      await _client
          .from('album_members')
          .delete()
          .eq('id', memberId)
          .eq('album_id', albumId);

      // _albums 자체는 안 건드려도 됨.
      // (앨범 멤버 목록은 다이얼로그에서 fetch 한 리스트를 setState 로 관리)
    } catch (e, st) {
      if (kDebugMode) {
        print('removeMember error: $e\n$st');
      }
      _setError(e.toString());
      rethrow;
    }
  }

  // ───────── 5) 앨범 삭제 ─────────
  Future<void> deleteAlbum(String albumId) async {
    _setError(null);

    try {
      await _client.from('albums').delete().eq('id', albumId);

      _albums.removeWhere((a) => a.id == albumId);

      if (_selectedAlbum?.id == albumId) {
        _selectedAlbum = _albums.isNotEmpty ? _albums.first : null;
      }

      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        print('deleteAlbum error: $e\n$st');
      }
      _setError(e.toString());
    }
  }

  Future<AlbumWithMyInfoModel?> ensureUploadableAlbumSelected() async {
    if (_albums.isEmpty) return null;

    final manageAlbums = this.manageAlbums;
    if (manageAlbums.isEmpty) return null;

    if (_selectedAlbum != null && _isManageRole(_selectedAlbum!)) {
      return _selectedAlbum;
    }

    _selectedAlbum = manageAlbums.first;
    notifyListeners();
    return _selectedAlbum;
  }

  // ───────── 6) 강제 새로고침 ─────────
  Future<void> refresh() async {
    await loadAlbums();
  }

  // 필요하면 에러 상태만 리셋하고 싶을 때
  void clearError() {
    _setError(null);
  }
}
