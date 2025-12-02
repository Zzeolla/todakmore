import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/widget/album_invite_share_sheet.dart';
import 'package:todakmore/widget/more_item_widget.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final albumProvider = context.watch<AlbumProvider>();
    final useProvider = context.watch<UserProvider>();
    final hasPermission = useProvider.hasAnyOwnerOrManager;   // 👈 추가
    final selectedAlbumId = albumProvider.selectedAlbumId;

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
          // ─────────────────────────────
          // 초대코드 생성하기 → 바텀시트 호출
          // ─────────────────────────────
          if (hasPermission)
            MoreItemWidget(
              icon: Icons.settings_outlined,
              title: '초대코드 생성하기',
              subtitle: '초대코드 생성하여 가족에게 공유하기',
              onTap: () {
                final albumProvider = context.read<AlbumProvider>();
                final albumId = albumProvider.selectedAlbumId; // 말한 그대로 사용

                if (albumId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('먼저 앨범을 선택해 주세요.'),
                    ),
                  );
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) {
                    return AlbumInviteShareSheet(albumId: albumId);
                  },
                );
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
