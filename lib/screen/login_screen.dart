import 'dart:async';
import 'dart:io' show Platform;        // 지금 기기가 iOS 인지, Android 인지 확인 용
import 'dart:convert';                // Apple 로그인용 SHA256 계산에 필요 (utf8.encode)
import 'dart:math';                   // Apple 로그인용 nonce(랜덤 문자열) 생성용

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    // 이미 세션이 있으면 바로 넘기기 (앱 재시작 등)
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _goToSplashScreen();
    }

    // 로그인/로그아웃 상태 변화 감지
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _goToSplashScreen();
      }
    });
  }

  void _goToSplashScreen() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // ─────────────────────────────────
  // build: 실제 로그인 화면 UI
  // ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 현재 기기가 iOS인지 여부 (Apple 로그인 버튼 표시 여부 결정)
    final bool isIOS = Platform.isIOS;

    return Scaffold(
      // 로그인 화면은 전체 풀 스크린으로 사용 (AppBar 없이)
      backgroundColor: const Color(0xFFFFF9F4), // Cream White
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1) 상단 로고 영역
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6B6FF), // Todak Lavender
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.child_friendly,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // 2) 앱 이름
              const Text(
                '토닥모아',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 8),

              // 3) 서브 타이틀
              const Text(
                '우리 가족만 보는 아기 사진 앨범',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9A9A9A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 4) 로그인 버튼 카드
              Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─ Google 로그인 버튼 ─
                      RoundedLoginButton(
                        label: 'Google로 계속하기',
                        iconAsset: 'assets/img/g-logo.png',
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        onPressed: () => _signInWithOAuth(
                          OAuthProvider.google,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─ Apple 로그인 버튼 (iOS에서만 표시) ─
                      if (isIOS)
                        SignInWithAppleButton(
                          onPressed: _signInWithAppleNative,
                          style: SignInWithAppleButtonStyle.black,
                          text: 'Apple로 계속하기',
                        ),

                      if (isIOS) const SizedBox(height: 16),

                      // ─ Kakao 로그인 버튼 ─
                      RoundedLoginButton(
                        label: '카카오로 계속하기',
                        iconAsset: 'assets/img/kakao_bubble.png',
                        backgroundColor: const Color(0xFFFEE500),
                        textColor: Colors.black,
                        textOpacity: 0.9,
                        onPressed: () => _signInWithOAuth(
                          OAuthProvider.kakao,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 5) 하단 안내 문구
              const Text(
                '로그인하면 개인정보 처리방침과 이용약관에 동의한 것으로 간주됩니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9A9A9A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // [공통] Supabase OAuth 로그인 시작
  //  - Google / Kakao 모두 여기서 처리
  // ─────────────────────────────────
  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    try {
      // Supabase가 브라우저(또는 외부 앱)를 열어서
      // 해당 Provider(Google/Kakao) 로그인 페이지로 이동시키고,
      // 로그인 완료 후 redirectTo 주소로 다시 앱을 열어준다.
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'todakmore://login-callback',
      );

      // 여기에서는 "로그인 요청만 보낸 상태"
      // 실제로 로그인 성공 후 앱이 다시 열리면,
      // SplashScreen에서 Supabase 세션을 확인하고 다음 화면으로 넘기는 구조로 만들 예정.
    } catch (e) {
      // 에러 발생 시 간단하게 스낵바로 표시
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
  }
  // TODO: 추후 Apple 로그인을 위해서 identifiers 등록 해주어야 한다(Sign in with apple 체크 필수!)
  // ─────────────────────────────────
  // Apple 로그인에 필요한 helper 함수들
  //   - nonce(랜덤 문자열) 생성
  //   - sha256 해시
  // ─────────────────────────────────
  String _randomNonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ─────────────────────────────────
  // [iOS 전용] Apple 네이티브 로그인
  //   1) iOS의 Apple 로그인 창을 띄우고
  //   2) 얻은 idToken을 Supabase에 전달
  // ─────────────────────────────────
  Future<void> _signInWithAppleNative() async {
    try {
      // 1. nonce 준비 (원본 + SHA256 해시)
      final rawNonce = _randomNonce();
      final hashedNonce = _sha256(rawNonce);

      // 2. iOS 네이티브 Apple 로그인 창 호출
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce, // 해시된 nonce를 Apple에 보냄
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple identityToken is null');
      }

      // 3. Supabase에 idToken 전달해서 로그인 처리
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce, // Supabase에는 해시 전 원본 nonce를 전달
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple 로그인 실패: $e')),
      );
    }
  }
}

class RoundedLoginButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final double textOpacity;
  final double iconSize;
  final double borderRadius;

  const RoundedLoginButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.textOpacity = 1.0,
    this.iconSize = 20,
    this.borderRadius = 6,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              height: iconSize,
              width: iconSize,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(textOpacity),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}