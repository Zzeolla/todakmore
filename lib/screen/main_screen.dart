import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/screen/feed_screen.dart';
import 'package:todakmore/screen/more_screen.dart';
import 'package:todakmore/screen/todak_screen.dart';
import 'package:todakmore/widget/common_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 나중에 각각 별도 파일로 분리해도 됨 (FeedScreen, TodakScreen, MoreScreen)
  final List<Widget> _screens = [
    FeedScreen(),
    TodakScreen(),
    MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(),
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
              icon: Text(
                '🏠',
                style: TextStyle(fontSize: 22),
              ),
              activeIcon: Text(
                '🏠',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              label: '일상',
            ),
            BottomNavigationBarItem(
              icon: Text(
                '👋',
                style: TextStyle(fontSize: 22),
              ),
              activeIcon: Text(
                '👋',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              label: '토닥',
            ),
            BottomNavigationBarItem(
              icon: Text(
                '⋯',
                style: TextStyle(fontSize: 22),
              ),
              activeIcon: Text(
                '⋯',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              label: '더보기',
            ),
          ],
      ),
    );
  }
}
