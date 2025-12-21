import 'album_model.dart';

class AlbumWithMyInfoModel {
  final AlbumModel album;
  final String myRole;   // 'owner', 'manager', 'viewer'
  final String? myLabel; // '엄마', '아빠' 등 (nullable)
  final String? driveProvider;

  bool get isOwner => myRole == 'owner';
  bool get isManager => myRole == 'manager';
  bool get isViewer => myRole == 'viewer';
  bool get canManage => isOwner || isManager;

  bool get isDriveConnected => driveProvider != null;

  String get id => album.id;
  String get name => album.name;
  String? get coverUrl => album.coverUrl;

  String get driveProviderLabel {
    switch (driveProvider) {
      case 'google_drive':
        return 'Google Drive';
      case 'onedrive':
        return 'OneDrive';
      default:
        return '';
    }
  }

  String get driveStatusLabel =>
      isDriveConnected ? '$driveProviderLabel 연결됨' : '';

  AlbumWithMyInfoModel({
    required this.album,
    required this.myRole,
    this.myLabel,
    this.driveProvider,
  });

  factory AlbumWithMyInfoModel.fromMap(Map<String, dynamic> map) {
    final album = AlbumModel(
      id: map['id'] as String,
      createdBy: map['created_by'] as String,
      name: map['name'] as String,
      coverUrl: map['cover_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );

    return AlbumWithMyInfoModel(
      album: album,
      myRole: map['my_role'] as String,
      myLabel: map['my_label'] as String?,
      driveProvider: map['drive_provider'] as String?,
    );
  }

  AlbumWithMyInfoModel copyWith({
    AlbumModel? album,
    String? myRole,
    String? myLabel,
    String? driveProvider,
  }) {
    return AlbumWithMyInfoModel(
      album: album ?? this.album,
      myRole: myRole ?? this.myRole,
      myLabel: myLabel ?? this.myLabel,
      driveProvider: driveProvider ?? this.driveProvider,
    );
  }

  static const Map<String, String> roleKoLabel = {
    'owner': '소유자',
    'manager': '관리자',
    'viewer': '구성원',
  };

  String get myRoleLabel => roleKoLabel[myRole] ?? '알 수 없음';
}