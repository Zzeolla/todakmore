// lib/service/album_upload_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
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
    required String uploadedBy,
    String bucketName = 'todak-media',
  }) async {
    final File? file = await asset.file;
    if (file == null) {
      throw Exception('파일을 가져올 수 없습니다.');
    }

    // 1) 원본 bytes 읽기
    final Uint8List originalBytes = await file.readAsBytes();

    // 2) 클라이언트에서 id 생성
    final String id = _uuid.v4();

    final ext = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path).toLowerCase();

    // 3) 원본/썸네일 경로
    final String originalPath = '$albumId/$id$ext';
    final String thumbPath    = '$albumId/thumb_$id.jpg';

    // 4) 썸네일용으로 리사이즈 + 압축 (피드에서 쓸 것)
    final Uint8List thumbBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: 900,  // 피드 1:1 카드 기준이면 800~1000 정도면 충분
      minHeight: 900,
      quality: 70,    // 용량 확 줄이기 (대략 수백 KB)
    );

    final storage = _supabase.storage.from(bucketName);

    // 5) 원본 업로드 (백업/원본 보기용)
    await storage.uploadBinary(
      originalPath,
      originalBytes,
      fileOptions: FileOptions(
        contentType: _guessContentType(ext),
      ),
    );

    // 6) 썸네일 업로드 (피드용)
    await storage.uploadBinary(
      thumbPath,
      thumbBytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
      ),
    );

    // 7) URL 만들기
    final String originalUrl = storage.getPublicUrl(originalPath);
    final String thumbUrl    = storage.getPublicUrl(thumbPath);

    // 8) DB insert: url + thumb_url 둘 다 저장
    final insertRes = await _supabase
        .from('album_medias')
        .insert({
      'id': id,
      'album_id': albumId,
      'uploaded_by': uploadedBy,
      'media_type': 'photo',
      'width': asset.width,
      'height': asset.height,
      'expire_at': DateTime.now()
          .add(const Duration(days: 14))
          .toIso8601String(),
      'url': originalUrl,      // 원본
      'thumb_url': thumbUrl,   // ✅ 피드에서 쓸 작은 이미지
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
