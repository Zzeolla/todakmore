import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todakmore/model/album_with_my_info_model.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/service/drive_connect_service.dart';

enum DriveProviderType { googleDrive, oneDrive }

class DriveConnectPanel extends StatefulWidget {
  const DriveConnectPanel({super.key});

  @override
  State<DriveConnectPanel> createState() => _DriveConnectPanelState();
}

class _DriveConnectPanelState extends State<DriveConnectPanel> {
  @override
  Widget build(BuildContext context) {
    final albumProvider = context.watch<AlbumProvider>();

    // ✅ owner/manager 앨범만
    final albums = albumProvider.albums
        .where((a) => a.myRole == 'owner' || a.myRole == 'manager')
        .toList()
      ..sort((a, b) => _rolePriority(a.myRole).compareTo(_rolePriority(b.myRole)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '드라이브 연결할 앨범 선택',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: albums.isEmpty
                ? const Center(
              child: Text(
                '관리 가능한 앨범이 없어요.\n(소유자/관리자 앨범만 연결할 수 있어요)',
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];

                final title = album.name;
                final subtitle = album.myLabel ?? '';
                final coverUrl = album.coverUrl;
                final trailing = album.myRoleLabel; // 소유자/관리자 라벨

                final driveProvider = album.driveProvider; // 'google_drive' | 'onedrive' | null
                final isConnected = driveProvider != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE3E0FF), // 연보라
                      width: 1.2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (coverUrl == null || coverUrl.isEmpty)
                          ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('👶', style: TextStyle(fontSize: 22)),
                        ),
                      )
                          : SizedBox(
                        width: 40,
                        height: 40,
                        child: CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFF1F1FD),
                          ),
                          errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, size: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: subtitle.isNotEmpty
                        ? Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConnected) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1FD), // soft lavender
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE3E0FF), width: 1),
                            ),
                            child: Text(
                              driveProvider == 'google_drive'
                                  ? 'Google Drive 연결됨'
                                  : 'OneDrive 연결됨',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF9A9A9A),
                          ),
                        ] else ...[
                          Text(
                            trailing, // 소유자/관리자
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3DA043),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF3DA043),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      if (isConnected) {
                        _showConnectedOptions(album); // 변경/해제 옵션 시트
                      } else {
                        _onTapAlbum(album); // 기존: Google/OneDrive 선택 시트
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTapAlbum(AlbumWithMyInfoModel album) async {
    final selected = await _showDriveProviderSheet(context);

    if (selected == null) return;

    // ✅ 다음 단계(연결 시작)
    // - selected == googleDrive → google oauth → google-drive-connect function 호출  - 완료
    // - selected == oneDrive   → ms oauth → onedrive-connect function 호출
    //

    try {
      // (선택) 로딩 UX: 간단히 스낵바 or setState 로딩
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('드라이브 연결 중...')),
      );

      if (selected == DriveProviderType.googleDrive) {
        await DriveConnectionService.connectGoogleDrive(albumId: album.id);
      } else {
        // TODO: OneDrive 연결 함수 붙일 자리
        throw Exception('OneDrive는 아직 준비 중');
      }

      if (!mounted) return;
      await context.read<AlbumProvider>().refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('드라이브 연결 완료!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $e')),
      );
    }
  }

  Future<DriveProviderType?> _showDriveProviderSheet(BuildContext context) {
    return showModalBottomSheet<DriveProviderType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF9F4), // Cream White (토닥모아 톤)
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '어떤 드라이브로 백업할까요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '앨범당 1개만 연결할 수 있어요.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),

                _providerTile(
                    leading: Image.asset(
                      'assets/img/google_drive_img.png',
                      width: 22,
                      height: 22,
                    ),
                  title: 'Google Drive',
                  subtitle: '구글 드라이브로 자동 백업',
                  onTap: () => Navigator.pop(ctx, DriveProviderType.googleDrive),
                ),
                const SizedBox(height: 10),
                _providerTile(
                  leading: Image.asset(
                    'assets/img/onedrive_img.png',
                    width: 22,
                    height: 22,
                  ),
                  title: 'OneDrive',
                  subtitle: '원드라이브로 자동 백업',
                  onTap: () => Navigator.pop(ctx, DriveProviderType.oneDrive),
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A4A4A),
                      side: const BorderSide(color: Color(0xFFE0D9FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _providerTile({
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E0FF), width: 1.1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: leading),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A9A9A)),
          ],
        ),
      ),
    );
  }

  Future<void> _showConnectedOptions(AlbumWithMyInfoModel album) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final provider = album.driveProvider;
        final label = provider == 'google_drive' ? 'Google Drive' : 'OneDrive';

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF9F4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$label 연결됨',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '앨범당 1개만 연결할 수 있어요.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),

                _actionTile(
                  title: '다른 드라이브로 변경',
                  subtitle: 'Google Drive 또는 OneDrive로 다시 연결',
                  icon: Icons.sync_alt_rounded,
                  onTap: () {
                    Navigator.pop(ctx);
                    _onTapAlbum(album); // provider 선택 시트 재사용
                  },
                ),
                const SizedBox(height: 10),
                _actionTile(
                  title: '드라이브 연결 해제',
                  subtitle: '자동 백업이 중단돼요',
                  icon: Icons.link_off_rounded,
                  isDanger: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDisconnect(album); // 다음 단계에서 delete 붙이기
                  },
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A4A4A),
                      side: const BorderSide(color: Color(0xFFE0D9FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDisconnect(AlbumWithMyInfoModel album) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('드라이브 연결 해제'),
        content: Text('정말 "${album.name}" 앨범의 드라이브 연결을 해제할까요?\n자동 백업이 중단됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // ✅ 1) 연결 해제 (row delete)
      final client = Supabase.instance.client;

      await client
          .from('album_drive_connection')
          .delete()
          .eq('album_id', album.id);

      // ✅ 2) 앨범 목록 다시 로드(뷰에 drive_provider가 있으니 자동 갱신)
      if (!mounted) return;
      await context.read<AlbumProvider>().refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('드라이브 연결이 해제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 해제 실패: $e')),
      );
    }
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E0FF), width: 1.1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDanger ? Colors.redAccent : const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A9A9A)),
          ],
        ),
      ),
    );
  }

  Future<String?> ensureGoogleDriveRefreshToken() async {
    final client = Supabase.instance.client;

    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 1) 이미 세션에 provider_refresh_token이 있다면 바로 사용
    // (구글로 로그인/연결을 이미 했고 offline 동의를 받았던 케이스)
    final existing = session?.providerRefreshToken;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // 2) 없으면: Google identity 연결(동의창 뜰 수 있음)
    // 완료되면 onAuthStateChange가 발생하면서 session이 갱신될 수 있음
    final completer = Completer<String?>();

    late final StreamSubscription sub;
    sub = client.auth.onAuthStateChange.listen((data) async {
      final s = data.session;
      final token = s?.providerRefreshToken;
      if (token != null && token.isNotEmpty && !completer.isCompleted) {
        completer.complete(token);
        await sub.cancel();
      }
    });

    await client.auth.linkIdentity(
      OAuthProvider.google,
      redirectTo: 'todakmore://login-callback', // 너가 쓰는 딥링크 그대로 사용 가능
      scopes: 'https://www.googleapis.com/auth/drive.file',
      queryParams: {
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );

    // 3) 링크 완료 후 refresh token 반환
    // (완료되면 위 listener가 completer를 완료시킴)
    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () async {
        await sub.cancel();
        return null;
      },
    );
  }

  Future<void> connectGoogleDriveToAlbum(String albumId) async {
    final client = Supabase.instance.client;

    final refreshToken = await ensureGoogleDriveRefreshToken();
    if (refreshToken == null) {
      throw Exception('Google 인증이 완료되지 않았습니다.');
    }

    final res = await client.functions.invoke(
      'google-drive-connect',
      body: {
        'album_id': albumId,
        'provider': 'google_drive',
        'refresh_token': refreshToken,
      },
    );

    if (res.status != 200) {
      throw Exception('google-drive-connect 실패: ${res.data}');
    }
  }

  int _rolePriority(String? role) {
    switch (role) {
      case 'owner':
        return 0;
      case 'manager':
        return 1;
      default:
        return 9;
    }
  }
}
