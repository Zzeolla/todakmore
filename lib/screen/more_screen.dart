import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/screen/more/my_profile_panel.dart';
import 'package:todakmore/widget/album_invite_share_sheet.dart';
import 'package:todakmore/widget/common_app_bar.dart';
import 'package:todakmore/widget/more_item_widget.dart';
import 'package:todakmore/screen/more/album_manage_panel.dart';

enum MorePage {
  main,
  myProfile,
  albumManage,

}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  MorePage _currentPage = MorePage.main;

  bool get _isRootPage => _currentPage == MorePage.main;

  void _goTo(MorePage page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        showBackButton: !_isRootPage,
        onBack: () {
          setState(() {
            _currentPage = MorePage.main;
          });
        },
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentPage) {
      case MorePage.main:
        return _buildMoreMainBody(context);
      case MorePage.myProfile:
        return const MyProfilePanel();
      case MorePage.albumManage:
        return const AlbumManagePanel();
    }
  }

  // ─────────────────────────────
  // 1) 기본 더보기 화면
  // ─────────────────────────────
  Widget _buildMoreMainBody(BuildContext context) {
    final albumProvider = context.watch<AlbumProvider>();
    final userProvider = context.watch<UserProvider>();
    final hasPermission = userProvider.hasAnyOwnerOrManager;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          MoreItemWidget(
            icon: Icons.person_outline_rounded,
            title: '내 프로필',
            subtitle: '이름, 계정 정보',
            onTap: () {
              _goTo(MorePage.myProfile);
            },
          ),

          MoreItemWidget(
            icon: Icons.photo_album_outlined,
            title: '앨범 관리',
            subtitle: '가족 앨범 초대 / 나가기',
            onTap: () {
              _goTo(MorePage.albumManage);
            },
          ),

          if (hasPermission)
            MoreItemWidget(
              icon: Icons.settings_outlined,
              title: '초대코드 생성하기',
              subtitle: '초대코드 생성하여 가족에게 공유하기',
              onTap: () {
                final albumId = albumProvider.selectedAlbumId;

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
            // TODO: 나중에 수정 필요
            onTap: () {
              _goTo(MorePage.albumManage);
            },
          ),

          MoreItemWidget(
            icon: Icons.help_outline_rounded,
            title: '도움말 / 문의',
            subtitle: '문의하기, 사용 방법',
            // TODO: 나중에 수정 필요
            onTap: () {
              _goTo(MorePage.albumManage);
            },
          ),
        ],
      ),
    );
  }
}
