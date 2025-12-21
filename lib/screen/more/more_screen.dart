import 'package:flutter/material.dart';
import 'package:todakmore/screen/more/widget/album_manage_panel.dart';
import 'package:todakmore/screen/more/widget/app_setting_panel.dart';
import 'package:todakmore/screen/more/widget/drive_connect_panel.dart';
import 'package:todakmore/screen/more/widget/my_profile_panel.dart';
import 'package:todakmore/widget/common_app_bar.dart';
import 'package:todakmore/widget/more_item_widget.dart';
import 'package:url_launcher/url_launcher.dart';

enum MorePage {
  main,
  myProfile,
  albumManage,
  driveConnect,
  appSetting,
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => MoreScreenState();
}

class MoreScreenState extends State<MoreScreen> {
  MorePage _currentPage = MorePage.main;

  bool get _isRootPage => _currentPage == MorePage.main;

  bool handleBack() {
    if (!_isRootPage) {
      setState(() => _currentPage = MorePage.main);
      return true; // 내가 처리했음 (부모는 더 이상 처리 X)
    }
    return false; // root라서 처리할 게 없음
  }

  void _goTo(MorePage page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isRootPage,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (!_isRootPage) {
          setState(() {
            _currentPage = MorePage.main;
          });
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          showBackButton: !_isRootPage,
          onBack: () {
            setState(() {
              _currentPage = MorePage.main;
            });
          },
        ),
        body: _buildBody(context),
      ),
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
      case MorePage.driveConnect:
        return const DriveConnectPanel();
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
            icon: Icons.cloud_sync_outlined,
            title: '드라이브 연결하기',
            subtitle: 'GoogleDrive / OneDrive 연결',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('기능 개발 중 입니다')),
              );
              // TODO: 구글 계정 연결 이슈로 추후 진행 예정
              // _goTo(MorePage.driveConnect);
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
            title: '도움말',
            subtitle: '사용 방법',
            // TODO: 나중에 수정 필요
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('기능 개발 중 입니다')),
              );
            },
          ),
          MoreItemWidget(
            icon: Icons.feedback_outlined,
            title: '피드백 / 문의',
            subtitle: '기능 제안, 오류 신고 등 기타 문의',
            onTap: () async {
              final url = Uri.parse('https://forms.gle/usrMp1MchNyzCszX7');

              final success = await launchUrl(url, mode: LaunchMode.externalApplication);
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('링크를 열 수 없습니다.')),
                );
              }
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
