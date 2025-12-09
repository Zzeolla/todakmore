import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';

class AppSettingPanel extends StatefulWidget {
  const AppSettingPanel({super.key});

  @override
  State<AppSettingPanel> createState() => _AppSettingPanelState();
}

class _AppSettingPanelState extends State<AppSettingPanel> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    final bool notificationsEnabled =
        userProvider.notificationsEnabled; // 예시

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱 설정',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.04),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF4CAF81),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림 받기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '새 사진 업로드, 초대 등 소식을 푸시 알림으로 받아요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: notificationsEnabled,
                    onChanged: _isSaving
                        ? null
                        : (value) async {
                      setState(() {
                        _isSaving = true;
                      });

                      try {
                        await context
                            .read<UserProvider>()
                            .setNotificationsEnabled(value);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
