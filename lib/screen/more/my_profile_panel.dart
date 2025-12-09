import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/widget/name_edit_bottom_sheet.dart';

class MyProfilePanel extends StatelessWidget {
  const MyProfilePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    // TODO: UserProvider에서 실제 필드 이름에 맞게 수정해줘
    final user = userProvider.currentUser; // 예시
    final name = user?.displayName ?? '이름을 설정해 주세요';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 타이틀
          Row(
            children: [
              const Text('🙂', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text(
                '내 프로필',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _openEditNameSheet(context, name == '이름을 설정해 주세요' ? null : name);
                },
                child: const Text(
                  '이름 수정',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF81),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 이름 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 동그라미 아바타 (이니셜)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                alignment: Alignment.center,
                child: Text(
                  _buildInitial(name),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF81),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 계정 정보 영역
          const Text(
            '계정 정보',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  String _buildInitial(String name) {
    if (name.isEmpty || name == '이름을 설정해 주세요') return '?';
    // 한글/영어 첫 글자만
    return name.characters.first;
  }

  void _openEditNameSheet(BuildContext context, String? currentName) async {
    final newName = await showNameEditBottomSheet(
      context: context,
      title: '이름을 입력해 주세요',
      hintText: '예: 홍길동',
      initialText: currentName,
    );

    if (newName == null) return;

    final userProvider = context.read<UserProvider>();
    await userProvider.updateDisplayName(newName);
  }
}