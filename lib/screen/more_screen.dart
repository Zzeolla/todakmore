import 'package:flutter/material.dart';
import 'package:todakmore/screen/more/app_setting_panel.dart';
import 'package:todakmore/screen/more/my_profile_panel.dart';
import 'package:todakmore/widget/common_app_bar.dart';
import 'package:todakmore/widget/more_item_widget.dart';
import 'package:todakmore/screen/more/album_manage_panel.dart';

enum MorePage {
  main,
  myProfile,
  albumManage,
  appSetting,
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
      case MorePage.appSetting:
        return const AppSettingPanel();
    }
  }

  // ─────────────────────────────
  // 1) 기본 더보기 화면
  // ─────────────────────────────
  Widget _buildMoreMainBody(BuildContext context) {
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
          MoreItemWidget(
            icon: Icons.settings_outlined,
            title: '앱 설정',
            subtitle: '알림 등',
            // TODO: 나중에 수정 필요
            onTap: () {
              _goTo(MorePage.appSetting);
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
          MoreItemWidget(
            icon: Icons.code_outlined,
            title: '오픈소스',
            subtitle: '오픈소스 라이선스',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '토닥 모아',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'assets/icon/splash_icon.png',
                  width: 64,
                  height: 64,
                ),
                children: const [
                  Text('토닥모아는 아기의 순간 모습을 가족들과 함께 공유하여 볼 수 있는 가족 앱입니다.'),
                  SizedBox(height: 16),
                  Text('개발: Zlabo'),
                  SizedBox(height: 16),
                  Text('※ 본 앱은 Google에서 제공하는 광고 SDK를 포함하고 있으며, '
                      '해당 SDK는 Google Play Services 약관(https://developers.google.com/admob/terms)에 따라 사용됩니다.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
