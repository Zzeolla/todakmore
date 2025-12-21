import 'package:flutter/material.dart';
import 'package:todakmore/screen/feed_screen.dart';
import 'package:todakmore/screen/more/more_screen.dart';
import 'package:todakmore/screen/todak_screen.dart';
import 'package:todakmore/widget/album_invite_share_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey<MoreScreenState> _moreKey = GlobalKey<MoreScreenState>();


  bool _initialized = false;
  String? _initialAlbumId;

  // 나중에 각각 별도 파일로 분리해도 됨 (FeedScreen, TodakScreen, MoreScreen)
  late final List<Widget> _screens = [
    FeedScreen(),
    TodakScreen(),
    MoreScreen(key: _moreKey),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;

      // 1) 라우트 arguments에서 albumId 가져오기
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _initialAlbumId = args;

        // 2) 프레임 그려진 뒤에 바텀시트 띄우기
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInviteSheetIfNeeded();
        });
      }
    }
  }

  Future<void> _showInviteSheetIfNeeded() async {
    if (!mounted) return;
    if (_initialAlbumId == null) return;

    final albumId = _initialAlbumId!;
    // 한 번만 쓰고 지워버리기
    _initialAlbumId = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AlbumInviteShareSheet(albumId: albumId),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ 더보기 탭에서 서브 페이지라면: 더보기 메인으로만 이동
        if (_selectedIndex == 2) {
          final handled = _moreKey.currentState?.handleBack() ?? false;
          if (handled) return false; // pop 막기
        }

        // ✅ 그 외: 탭이 0이 아니면 피드로
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }

        // ✅ 피드 탭이면 앱 종료 허용
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9F4), // Cream White
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0, // ★ 자간 추가
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5, // ★ 자간 추가
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: const Color(0xFF4CAF81),
          unselectedItemColor: const Color(0xFF9A9A9A), // Warm Gray
          backgroundColor: const Color(0xFFF3FDF6),
          elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Text('🏠', style: TextStyle(fontSize: 22)),
                activeIcon: Text('🏠', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                label: '일상',
              ),
              BottomNavigationBarItem(
                icon: Text('👋', style: TextStyle(fontSize: 22)),
                activeIcon: Text('👋', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                label: '토닥',
              ),
              BottomNavigationBarItem(
                icon: Text('⋯', style: TextStyle(fontSize: 22)),
                activeIcon: Text('⋯', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                label: '더보기',
              ),
            ],
        ),
      ),
    );
  }
}
