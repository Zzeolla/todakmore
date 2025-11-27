import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/provider/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // 화면이 만들어지자마자 로그인/세션 체크 시작
    _checkAuthAndNavigate();
  }

  // ─────────────────────────────────
  // 1) 현재 Supabase 세션 확인
  // 2) 로그인 여부에 따라 다음 화면으로 이동
  // ─────────────────────────────────
  Future<void> _checkAuthAndNavigate() async {
    // 살짝 로고가 보이도록 500ms 정도 딜레이 (선택사항)
    await Future.delayed(const Duration(milliseconds: 500));

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (!mounted) return;

    // 1) 로그인 안 되어 있으면 → 로그인 화면
    if (session == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // 2) 로그인 되어 있으면 → users 테이블 로드/생성
    final userProvider = context.read<UserProvider>();
    await userProvider.loadOrCreateUser();

    if (!mounted) return;

    // 3) 앨범 불러오기
    final albumProvider = context.read<AlbumProvider>();
    await albumProvider.loadAlbums();

    if (!mounted) return;

    // 4) 앨범 존재 여부에 따라 분기
    if (albumProvider.albums.isNotEmpty) {
      // 앨범 있음 → 메인으로
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // 앨범 없음 → 앨범 시작 화면(초대코드 입력 or 새 앨범 생성)
      Navigator.of(context).pushReplacementNamed('/album-start');
    }
  }

  // ─────────────────────────────────
  // 화면 UI (로고 + 로딩 스피너)
  // ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4), // Cream White
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC6B6FF), // Todak Lavender
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.child_friendly,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '토닥모아',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '우리 가족만 보는 아기 사진 앨범',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9A9A9A),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
