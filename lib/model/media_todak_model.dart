class MediaTodakModel {
  final String? id;        // DB에서 생성된 uuid
  final String albumId;
  final String mediaId;
  final String userId;      // 'owner', 'manager', 'viewer'
  final bool isDeleted;    // 엄마, 아빠, 할머니...
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MediaTodakModel({
    this.id,
    required this.albumId,
    required this.mediaId,
    required this.userId,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  // Supabase에서 가져온 Map → Album
  factory MediaTodakModel.fromMap(Map<String, dynamic> map) {
    return MediaTodakModel(
      id: map['id'] as String,
      albumId: map['album_id'] as String,
      mediaId: map['media_id'] as String,
      userId: map['user_id'] as String,
      isDeleted: map['is_deleted'] as bool,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'album_id': albumId,
      'media_id': mediaId,
      'user_id': userId,
      'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  MediaTodakModel copyWith({
    String? id,
    String? albumId,
    String? mediaId,
    String? userId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaTodakModel(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      mediaId: mediaId ?? this.mediaId,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}