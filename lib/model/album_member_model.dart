class AlbumMemberModel {
  final String? id;        // DB에서 생성된 uuid
  final String albumId;
  final String userId;
  final String role;      // 'owner', 'manager', 'viewer'
  final String? label;    // 엄마, 아빠, 할머니...
  final DateTime? joinedAt;
  final DateTime? updatedAt;

  AlbumMemberModel({
    this.id,
    required this.albumId,
    required this.userId,
    required this.role,
    this.label,
    this.joinedAt,
    this.updatedAt,
  });

  // Supabase에서 가져온 Map → Album
  factory AlbumMemberModel.fromMap(Map<String, dynamic> map) {
    return AlbumMemberModel(
      id: map['id'] as String,
      albumId: map['album_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      label: map['label'] as String?,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'album_id': albumId,
      'user_id': userId,
      'role': role,
      if (label != null) 'label': label,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// insert에 쓸 때는 DB default 컬럼은 안 보냄
  Map<String, dynamic> toInsertMap() {
    return {
      'album_id': albumId,
      'user_id': userId,
      'role': role,
      if (label != null) 'label': label,
    };
  }

  AlbumMemberModel copyWith({
    String? id,
    String? albumId,
    String? userId,
    String? role,
    String? label,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return AlbumMemberModel(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      label: label ?? this.label,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}