import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/model/user_model.dart';
import 'package:todakmore/service/fcm_token_service.dart';

// TODO : retention을 permission할 때 추가 필요(삭제 기간임)
class UserProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoaded = false;
  bool _hasAnyOwnerOrManager = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoaded => _isLoaded;
  String? get userId => _currentUser?.id;
  String? get displayName => _currentUser?.displayName;
  String? get lastAlbumId => _currentUser?.lastAlbumId;
  bool get hasAnyOwnerOrManager => _hasAnyOwnerOrManager;

  /// 로그인된 유저 기준으로 users row 불러오거나 생성
  Future<void> loadOrCreateUser() async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      _currentUser = null;
      _isLoaded = true;
      notifyListeners();
      return;
    }

    final uid = authUser.id;

    // 1) users 테이블 조회
    final data = await _client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) {
      // 2) 없으면 생성
      await _client.from('users').insert({'id': uid});

      _currentUser = UserModel(
        id: uid,
        displayName: null,
        createdAt: DateTime.now(),
        lastAlbumId: null,
      );
    } else {
      // 3) 있으면 UserModel로 파싱
      _currentUser = UserModel.fromJson(data);
    }

    await refreshAlbumManagePermission();

    _isLoaded = true;
    notifyListeners();
  }

  /// display_name 업데이트
  Future<void> updateDisplayName(String name) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    final uid = authUser.id;

    await _client
        .from('users')
        .update({'display_name': name})
        .eq('id', uid);

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(displayName: name);
    } else {
      _currentUser = UserModel(
        id: uid,
        displayName: name,
        createdAt: DateTime.now(),
        lastAlbumId: null,
      );
    }

    notifyListeners();
  }

  Future<void> updateLastAlbumId(String albumId) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return;

    final uid = authUser.id;

    await _client
        .from('users')
        .update({'last_album_id': albumId})
        .eq('id', uid);

    if (_currentUser != null) {
      // copyWith 있으면 이렇게
      _currentUser = _currentUser!.copyWith(lastAlbumId: albumId);
    }

    notifyListeners();
  }

  // 내 계정 기준으로 owner/manager 앨범이 하나라도 있는지 체크
  Future<void> refreshAlbumManagePermission() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      _hasAnyOwnerOrManager = false;
      notifyListeners();
      return;
    }
    // TODO: 이거 나중에 내가 manager 권한 줄 때도 꼭 refresh 해줘야 하는데 상대방이 refresh가 되어야 하네 ㅎㅎ

    final uid = authUser.id;

    try {
      final result = await _client
          .from('album_members')
          .select('id')
          .eq('user_id', uid)
          .inFilter('role', ['owner', 'manager'])
          .limit(1); // 하나만 있으면 되니까

      _hasAnyOwnerOrManager = result.isNotEmpty;
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        print('refreshAlbumManagePermission error: $e');
        print(st);
      }
      _hasAnyOwnerOrManager = false;
      notifyListeners();
    }
  }

  /// 로그아웃 시 초기화 (옵션)
  void clear() {
    _currentUser = null;
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    final authUser = _client.auth.currentUser;

    if (authUser != null) {
      final userId = authUser.id;

      final fcmTokenService = FcmTokenService(_client);
      await fcmTokenService.unregister(userId);
    }

    await _client.auth.signOut();
    clear();

  }
}
