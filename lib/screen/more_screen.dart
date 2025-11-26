import 'package:flutter/material.dart';
import 'package:todakmore/widget/more_item_widget.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            '더보기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          MoreItemWidget(
            icon: Icons.person_outline_rounded,
            title: '내 프로필',
            subtitle: '닉네임, 계정 정보',
            onTap: () {
              // TODO: 상세 페이지 연결
            },
          ),
          MoreItemWidget(
            icon: Icons.photo_album_outlined,
            title: '앨범 관리',
            subtitle: '가족 앨범 초대 / 나가기',
            onTap: () {
              // TODO: 상세 페이지 연결
            },
          ),
          MoreItemWidget(
            icon: Icons.settings_outlined,
            title: '앱 설정',
            subtitle: '알림, 자동삭제 기간 등',
            onTap: () {
              // TODO: 상세 페이지 연결
            },
          ),
          MoreItemWidget(
            icon: Icons.help_outline_rounded,
            title: '도움말 / 문의',
            subtitle: '문의하기, 사용 방법',
            onTap: () {
              // TODO: 상세 페이지 연결
            },
          ),
        ],
      ),
    );
  }
}
