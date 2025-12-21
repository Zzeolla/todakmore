import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/model/album_with_my_info_model.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/widget/album_create_sheet.dart';
import 'package:todakmore/widget/album_invite_join_sheet.dart';
import 'package:todakmore/widget/album_member_manage_dialog.dart';
import 'package:todakmore/widget/name_edit_bottom_sheet.dart';

class AlbumManagePanel extends StatefulWidget {
  const AlbumManagePanel({super.key});

  @override
  State<AlbumManagePanel> createState() => _AlbumManagePanelState();
}

class _AlbumManagePanelState extends State<AlbumManagePanel> {
  @override
  Widget build(BuildContext context) {
    final albumProvider = context.watch<AlbumProvider>();
    final albums = [...albumProvider.albums]
      ..sort((a, b) {
        // 여기서 a.myRole / b.myRole 은 실제 모델 필드명에 맞게 수정
        final aRole = a.myRole;  // 예시: 'owner' / 'manager' / 'viewer'
        final bRole = b.myRole;

        return _rolePriority(aRole).compareTo(_rolePriority(bRole));
      });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 참여 중인 앨범',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // 앨범 리스트
          Expanded(
            child: albums.isEmpty
                ? const Center(
              child: Text(
                '참여 중인 앨범이 없어요.\n새 앨범을 만들거나 초대코드로 참여해 주세요.',
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];

                // ✅ Album 모델에 맞게 필드명 수정
                final title = album.name;
                final subtitle = album.myLabel ?? '';
                final trailing = album.myRoleLabel;
                final coverUrl = album.coverUrl;
                final role = album.myRole;
                final canManage = role == 'owner' || role == 'manager';

                final borderColor = canManage
                    ? const Color(0xFFE3E0FF)       // 관리 가능 → 연보라 보더
                    : const Color(0xFFECECEC);      // viewer → 연회색 보더

                final bgColor = canManage
                    ? Colors.white
                    : Colors.white.withOpacity(0.8); // viewer는 살짝 흐리게

                final trailingColor = canManage
                    ? const Color(0xFF3DA043)       // 초록
                    : Colors.grey[600];             // 회색

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (coverUrl == null || coverUrl.isEmpty)
                          ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1FD), // 연보라 톤 (토닥모아 테마)
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '👶',                   // 원하는 이모지로 변경 가능
                            style: TextStyle(fontSize: 22),
                          ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                        Text(
                          trailing, // 소유자 / 관리자 / 구성원
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: trailingColor,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: Color(0xFF3DA043),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      if (canManage) {
                        _onAlbumManageTap(album);
                      } else {
                        _onViewerAlbumTap(album);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 하단 버튼 2개 (초대코드로 참여 / 새 앨범 만들기)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔑 초대 코드로 앨범 추가
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _onJoinAlbumPressed(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFF1F1FD), // 연보라 톤
                    foregroundColor: const Color(0xFF4A4A4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔑', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        '초대 코드로 앨범 추가하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 📸 새 앨범 만들기
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _onCreateAlbumPressed(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A4A4A),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFE0D9FF), // 아주 연한 라벤더 보더
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('📸', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text(
                        '+ 새 앨범 만들기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onJoinAlbumPressed(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,          // 키보드 올라올 때 높이 확보
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AlbumInviteJoinSheet();
      },
    );
    // join 시트 안에서 Navigator.pushNamedAndRemoveUntil('/', ...) 호출하니까
    // 여기서는 별도 처리 필요 없음
  }

  Future<void> _onCreateAlbumPressed(BuildContext context) async {
    // 1. 앨범 생성 바텀시트 띄우기
    final formData = await showModalBottomSheet<AlbumCreateFormData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AlbumCreateSheet();
      },
    );

    // 사용자가 취소한 경우
    if (formData == null) return;


    // 2. Provider 통해 앨범 + 커버 생성
    final userProvider = context.read<UserProvider>();
    final albumProvider = context.read<AlbumProvider>();

    final created = await albumProvider.createAlbum(
      name: formData.name,
      ownerLabel: formData.label,
      coverBytes: formData.coverImageBytes, // ← File? 타입이라고 가정
    );

    if (created != null) {
      await userProvider.updateLastAlbumId(created.id);
    }

    if (created == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앨범 생성 중 오류가 발생했습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    if (!mounted) return;

    // 3. 메인 화면으로 이동
    Navigator.pushReplacementNamed(
      context,
      '/main',
      arguments: created.id, // 필요하면 albumId 넘기기
    );
  }

  void _onAlbumManageTap(AlbumWithMyInfoModel album) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlbumMemberManageDialog(album: album);
      },
    );
  }

  Future<void> _onViewerAlbumTap(AlbumWithMyInfoModel album) async {
    final albumProvider = context.read<AlbumProvider>();

    // 1) 바텀시트로 새 라벨 입력 받기
    final newLabel = await showNameEditBottomSheet(
      context: context,
      title: '앨범에서 사용할 이름',
      hintText: '예: 엄마, 아빠, 할머니',
      initialText: album.myLabel ?? '',
    );

    if (newLabel == null) return; // 취소 or 뒤로가기

    final userId = context.read<UserProvider>().userId;

    await albumProvider.updateMemberLabel(
      albumId: album.id,
      memberId: userId!,
      newLabel: newLabel,
    );

    // AlbumProvider.updateMemberLabel 안에서
    // _albums + _selectedAlbum 업데이트하고 notifyListeners()
    // 하도록 이미 만들어 두었으니 여기서 따로 setState 할 필요 없음.
  }


  int _rolePriority(String? role) {
    switch (role) {
      case 'owner':
        return 0;
      case 'manager':
        return 1;
      case 'viewer':
        return 2;
      default:
        return 3;
    }
  }
}
