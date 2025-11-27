class AlbumModel {
  final String id;
  final String createdBy;
  final String name;
  final String? coverUrl;
  final DateTime createdAt;

  AlbumModel({
    required this.id,
    required this.createdBy,
    required this.name,
    this.coverUrl,
    required this.createdAt,
  });

  // Supabase에서 가져온 Map → Album
  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      id: map['id'] as String,
      createdBy: map['created_by'] as String,
      name: map['name'] as String,
      coverUrl: map['cover_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // 앱에서 Supabase로 보낼 때 사용 (insert/update)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_by': createdBy,
      'name': name,
      'cover_url': coverUrl,
      // created_at은 DB default now() 쓰면 보통 안 보냄
    };
  }

  AlbumModel copyWith({
    String? id,
    String? createdBy,
    String? name,
    String? coverUrl,
    DateTime? createdAt,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}