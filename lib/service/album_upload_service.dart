// lib/service/album_upload_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';
// TODO : 원하면 나중에 video_thumbnail을 교체해주는 리팩토링도 같이 도와줄게!
class AlbumUploadService {
  AlbumUploadService._();

  static final SupabaseClient _supabase = Supabase.instance.client;
  static final _uuid = const Uuid();

  /// 🔥 EXIF 회전이 반영된 실제 width/height 계산 함수
  static Future<(int width, int height)> getImageSizeWithOrientation(File file) async {
    final Uint8List bytes = await file.readAsBytes();

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return (image.width, image.height);
  }

  /// 한 개 AssetEntity 업로드
  ///
  /// 1) album_medias insert (id 생성)
  /// 2) Storage에 {albumId}/{id}.jpg 업로드
  /// 3) public URL을 url 컬럼에 update
  ///
  /// 반환: 업로드된 row (id, url 등)
  /// - 동영상: video_thumbnail 로 썸네일 생성 + video 업로드
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

    final storage = _supabase.storage.from(bucketName);
    final String id = _uuid.v4();

    if (asset.type == AssetType.video) {
      return _uploadVideoAsset(
        asset: asset,
        file: file,
        storage: storage,
        albumId: albumId,
        uploadedBy: uploadedBy,
        id: id,
      );
    } else {
      return _uploadPhotoAsset(
        asset: asset,
        file: file,
        storage: storage,
        albumId: albumId,
        uploadedBy: uploadedBy,
        id: id,
      );
    };
  }

  // ───────────────── 사진 업로드 (기존 로직) ─────────────────
  static Future<Map<String, dynamic>> _uploadPhotoAsset({
    required AssetEntity asset,
    required File file,
    required StorageFileApi storage,
    required String albumId,
    required String uploadedBy,
    required String id,
  }) async {
    // 1) 원본 bytes 읽기
    final Uint8List originalBytes = await file.readAsBytes();

    // 2) orientation 적용된 실제 width/height 계산
    final (int realW, int realH) = await getImageSizeWithOrientation(file);

    final ext = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path).toLowerCase();

    // 3) 원본/썸네일 경로
    final String originalPath = '$albumId/$id$ext';
    final String thumbPath = '$albumId/thumb_$id.jpg';

    // 4) 썸네일용으로 리사이즈 + 압축 (피드에서 쓸 것)
    final Uint8List thumbBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: 900,
      minHeight: 900,
      quality: 70,
    );

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
    final String thumbUrl = storage.getPublicUrl(thumbPath);

    // 8) DB insert: url + thumb_url 둘 다 저장
    final insertRes = await _supabase
        .from('album_medias')
        .insert({
      'id': id,
      'album_id': albumId,
      'uploaded_by': uploadedBy,
      'media_type': 'photo',
      'width': realW,
      'height': realH,
      'expire_at': DateTime.now()
          .add(const Duration(days: 14))
          .toIso8601String(),
      'url': originalUrl,
      'thumb_url': thumbUrl,
    })
        .select()
        .single();

    return insertRes;
  }

  // ───────────────── 동영상 업로드 ─────────────────
  static Future<Map<String, dynamic>> _uploadVideoAsset({
    required AssetEntity asset,
    required File file,
    required StorageFileApi storage,
    required String albumId,
    required String uploadedBy,
    required String id,
  }) async {
    // duration: 초 단위 (이미 15초 이내만 들어오게 필터된 상태)
    final int durationSec = asset.duration;

    // 확장자 (기본 mp4)
    final ext = p.extension(file.path).isEmpty
        ? '.mp4'
        : p.extension(file.path).toLowerCase();

    final String videoPath = '$albumId/$id$ext';
    final String thumbPath = '$albumId/thumb_$id.jpg';

    // 1) 동영상 파일 업로드
    final Uint8List videoBytes = await file.readAsBytes();

    await storage.uploadBinary(
      videoPath,
      videoBytes,
      fileOptions: FileOptions(
        contentType: _guessContentType(ext),
      ),
    );

    final String videoUrl = storage.getPublicUrl(videoPath);

    // 2) 썸네일 생성
    Uint8List? thumbBytes = await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 900, // 사진 썸네일과 맞춰줌
      quality: 80,
    );

    String? thumbUrl;

    if (thumbBytes != null) {
      await storage.uploadBinary(
        thumbPath,
        thumbBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
        ),
      );
      thumbUrl = storage.getPublicUrl(thumbPath);
    }

    // 4) DB insert
    final insertRes = await _supabase
        .from('album_medias')
        .insert({
      'id': id,
      'album_id': albumId,
      'uploaded_by': uploadedBy,
      'media_type': 'video',
      'width': asset.width,
      'height': asset.height,
      'duration': durationSec,
      'expire_at': DateTime.now()
          .add(const Duration(days: 14))
          .toIso8601String(),
      'url': videoUrl,     // 🔥 동영상 URL
      'thumb_url': thumbUrl, // 🔥 썸네일 URL (피드에서 사용)
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
