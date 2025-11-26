import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {

  const CommonAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF1F1FD),
      elevation: 0,
      centerTitle: true,
      leading: const SizedBox(width: 40),
      title: const Text(
        '토닥 모아',
        style: TextStyle(
          fontFamily: 'Cafe24Ssukssuk',
          fontSize: 30,
          color: Colors.black87,   // ← 이제 가독성 GOOD
          fontWeight: FontWeight.w800
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            size: 30,
            color: Colors.black87,
          ),
          onPressed: () => _handleLogout(context),
          tooltip: '로그아웃',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    await userProvider.signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}
