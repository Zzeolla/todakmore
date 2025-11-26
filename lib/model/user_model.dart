class UserModel {
  final String id;
  final String? displayName;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    this.displayName,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      createdAt: json['created_ad'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}