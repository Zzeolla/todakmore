class VideoPolicy {
  // 기본값 (백업용)
  static const int defaultMaxSecondsFree = 15;
  static const int defaultMaxSecondsPro = 30;

  /// 유저 상태에 따라 허용 길이 결정
  static int maxSeconds({required bool isPro}) {
    return isPro ? defaultMaxSecondsPro : defaultMaxSecondsFree;
  }
}