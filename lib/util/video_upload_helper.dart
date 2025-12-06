import 'package:photo_manager/photo_manager.dart';
import 'package:todakmore/util/video_policy.dart';

class VideoUploadHelper {
  /// 동영상 길이가 업로드 가능한지 검사
  /// - entity.duration: 동영상 길이 (초 단위, int)
  /// - maxSeconds: 허용되는 최대 길이 (초)
  static bool canUploadVideo({
    required AssetEntity entity,
    required int maxSeconds,
  }) {
    final duration = entity.duration;
    return duration <= maxSeconds;
  }

  // TODO: TodakVideoPolicy를 여기 안에서 바로 써도 되지만,
  // “유저 상태(UserProvider → isPro 여부)”가 필요한 순간이라
  // 위에서 userProvider로 isPro 구하고 → maxSeconds 계산 → helper에 넘기는 구조가 더 깔끔해.
}