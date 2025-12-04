import 'album_member_model.dart';
import 'user_model.dart';

class AlbumMemberWithUserModel {
  final AlbumMemberModel member;
  final UserModel? user;

  AlbumMemberWithUserModel({
    required this.member,
    required this.user,
  });

  String get memberId => member.id ?? '';
  String get userId => member.userId;
  String get name => user?.displayName ?? member.label ?? '이름 없음';
  String get role => member.role;
  String? get label => member.label;

  factory AlbumMemberWithUserModel.fromMap(Map<String, dynamic> map) {
    // map 은 album_members 컬럼 + users(...) 조인 결과가 같이 들어 있음
    final member = AlbumMemberModel.fromMap(map);
    // 🔥 여기서 null 체크
    final rawUser = map['users'];
    UserModel? user;
    if (rawUser != null) {
      user = UserModel.fromJson(rawUser as Map<String, dynamic>);
    } else {
      // RLS 등으로 users 를 못 가져온 경우: 최소한 id 정도만 세팅
      user = null;
    }

    return AlbumMemberWithUserModel(
      member: member,
      user: user,
    );
  }
}
