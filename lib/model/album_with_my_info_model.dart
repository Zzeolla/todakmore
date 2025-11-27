import 'album_model.dart';

class AlbumWithMyInfoModel {
  final AlbumModel album;
  final String myRole;   // 'owner', 'manager', 'viewer'
  final String? myLabel; // '엄마', '아빠' 등 (nullable)

  bool get isOwner => myRole == 'owner';
  bool get isManager => myRole == 'manager';
  bool get isViewer => myRole == 'viewer';
  bool get canManage => isOwner || isManager;

  String get id => album.id;
  String get name => album.name;
  String? get coverUrl => album.coverUrl;

  AlbumWithMyInfoModel({
    required this.album,
    required this.myRole,
    this.myLabel,
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
    );
  }

  AlbumWithMyInfoModel copyWith({
    AlbumModel? album,
    String? myRole,
    String? myLabel,
  }) {
    return AlbumWithMyInfoModel(
      album: album ?? this.album,
      myRole: myRole ?? this.myRole,
      myLabel: myLabel ?? this.myLabel,
    );
  }
}