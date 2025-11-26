import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/model/user_model.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoaded = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoaded => _isLoaded;
  String? get userId => _currentUser?.id;
  String? get displayName => _currentUser?.displayName;

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
      );
    } else {
      // 3) 있으면 UserModel로 파싱
      _currentUser = UserModel.fromJson(data);
    }

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

    // 로컬 상태 업데이트
    _currentUser = UserModel(
      id: uid,
      displayName: name,
      createdAt: _currentUser?.createdAt,
    );

    notifyListeners();
  }

  /// 로그아웃 시 초기화 (옵션)
  void clear() {
    _currentUser = null;
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    clear();

  }
}
