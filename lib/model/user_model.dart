class UserModel {
  final String id;
  final String? displayName;
  final DateTime? createdAt;
  final String? lastAlbumId;
  final bool? notificationsEnabled;

  UserModel({
    required this.id,
    this.displayName,
    this.createdAt,
    this.lastAlbumId,
    this.notificationsEnabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      lastAlbumId: json['last_album_id'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'created_at': createdAt?.toIso8601String(),
      'last_album_id': lastAlbumId,
      'notifications_enabled': notificationsEnabled,
    };
  }

  UserModel copyWith({
    String? id,
    String? displayName,
    DateTime? createdAt,
    String? lastAlbumId,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastAlbumId: lastAlbumId ?? this.lastAlbumId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}