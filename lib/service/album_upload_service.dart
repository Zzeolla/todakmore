// lib/service/album_upload_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlbumUploadService {
  AlbumUploadService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

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
    String bucketName = 'album_medias',
  }) async {
    // 우선 파일/바이트 확보
    final File? file = await asset.file;
    if (file == null) {
      throw Exception('파일을 가져올 수 없습니다.');
    }

    // DB에 기본 메타데이터 insert (id 만들기)
    final insertRes = await _supabase
        .from('album_medias')
        .insert({
      'album_id': albumId,
      'uploaded_by': uploadedBy,
      'media_type': 'photo', // 현재는 사진만, 나중에 video 추가
      'width': asset.width,
      'height': asset.height,
      'expire_at':
      DateTime.now().add(const Duration(days: 14)).toIso8601String(),
    })
        .select()
        .single();

    final String id = insertRes['id'] as String;

    // Storage 경로 설정
    final String path = '$albumId/$id.jpg';

    final Uint8List bytes = await file.readAsBytes();

    // Storage 업로드
    await _supabase.storage.from(bucketName).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
      ),
    );

    // public URL
    final String publicUrl =
    _supabase.storage.from(bucketName).getPublicUrl(path);

    // DB url 업데이트
    final updated = await _supabase
        .from('album_medias')
        .update({
      'url': publicUrl,
    })
        .match({'id': id})
        .select()
        .single();

    return updated;
  }
}
