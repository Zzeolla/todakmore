class VideoPolicy {
  // 기본값 (백업용)
  static const int defaultMaxSecondsFree = 60;
  static const int defaultMaxSecondsPro = 90;

  /// 유저 상태에 따라 허용 길이 결정
  static int maxSeconds({required bool isPro}) {
    return isPro ? defaultMaxSecondsPro : defaultMaxSecondsFree;
  }
}