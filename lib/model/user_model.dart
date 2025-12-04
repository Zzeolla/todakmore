class UserModel {
  final String id;
  final String? displayName;
  final DateTime? createdAt;
  final String? lastAlbumId;

  UserModel({
    required this.id,
    this.displayName,
    this.createdAt,
    this.lastAlbumId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      lastAlbumId: json['last_album_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'created_at': createdAt?.toIso8601String(),
      'last_album_id': lastAlbumId,
    };
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    DateTime? createdAt,
    String? lastAlbumId,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastAlbumId: lastAlbumId ?? this.lastAlbumId,
    );
  }
}