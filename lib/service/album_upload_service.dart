// lib/service/album_upload_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class AlbumUploadService {
  AlbumUploadService._();

  static final SupabaseClient _supabase = Supabase.instance.client;
  static final _uuid = const Uuid();

  /// 한 개 AssetEntity 업로드
  ///
  /// 1) album_medias insert (id 생성)
  /// 2) Storage에 {albumId}/{id}.jpg 업로드
  /// 3) public URL을 url 컬럼에 update
  ///
  /// 반환: 업로드된 row (id, url 등)
  static Future<Map<String, dynamic>> uploadSingleAsset({
    required AssetEntity asset,
    required String albumId,
    required String uploadedBy, // auth.uid()
    String bucketName = 'todak-media',
  }) async {
    // 우선 파일/바이트 확보
    final File? file = await asset.file;
    if (file == null) {
      throw Exception('파일을 가져올 수 없습니다.');
    }

    final Uint8List bytes = await file.readAsBytes();

    // 2) 클라이언트에서 id 생성 (DB id와 Storage 파일명 같이 쓰기)
    final String id = _uuid.v4();

    // 확장자 맞춰서 (jpg, png 등)
    final ext = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path).toLowerCase();

    // 3) Storage 경로
    final String path = '$albumId/$id$ext';

    // 4) Storage 업로드
    await _supabase.storage.from(bucketName).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _guessContentType(ext), // 아래 helper 참고
      ),
    );

    // 5) public URL
    final String publicUrl =
    _supabase.storage.from(bucketName).getPublicUrl(path);

    // 6) DB insert (url 포함해서 한 번에)
    final insertRes = await _supabase
        .from('album_medias')
        .insert({
      'id': id,              // 직접 넣어줌 (gen_random_uuid 대신)
      'album_id': albumId,
      'uploaded_by': uploadedBy,
      'media_type': 'photo',
      'width': asset.width,
      'height': asset.height,
      'expire_at': DateTime.now()
          .add(const Duration(days: 14))
          .toIso8601String(),
      'url': publicUrl,      // ★ 여기서 바로 넣기 때문에 NOT NULL 위반 없음
    })
        .select()
        .single();

    return insertRes;
  }

  static String _guessContentType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
