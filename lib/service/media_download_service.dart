// lib/service/media_download_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:todakmore/model/media_item.dart';

enum MediaDownloadResult {
  savedImage,
  savedVideo,
  permissionDenied,
  failed,
}

class MediaDownloadService {
  MediaDownloadService._();

  /// 실제 다운로드 + 갤러리 저장 로직
  static Future<MediaDownloadResult> downloadMedia(MediaItem item) async {
    try {
      // 1) 권한 요청
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        return MediaDownloadResult.permissionDenied;
      }

      // 2) Supabase Storage URL에서 바이트 다운로드
      final uri = Uri.parse(item.url); // 원본 URL 사용
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return MediaDownloadResult.failed;
      }

      final bytes = response.bodyBytes;

      // 3) 타입에 따라 저장
      if (item.isVideo) {
        // ✅ 3-1. 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final filePath = p.join(tempDir.path, 'todak_${item.id}.mp4');
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // ✅ 3-2. PhotoManager를 이용해 영상 저장
        await PhotoManager.editor.saveVideo(file);
        return MediaDownloadResult.savedVideo;
      } else {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'todak_${item.albumName}_$timestamp.jpg';

        await PhotoManager.editor.saveImage(
          bytes,
          filename: filename,
        );
        return MediaDownloadResult.savedImage;
      }
    } catch (_) {
      return MediaDownloadResult.failed;
    }
  }
}
