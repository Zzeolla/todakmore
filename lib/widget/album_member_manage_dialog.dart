import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/model/album_with_my_info_model.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/screen/album_edit_screen.dart';
import 'package:todakmore/widget/album_invite_share_sheet.dart';
import 'package:todakmore/widget/name_edit_bottom_sheet.dart';
// TODO: 나중에 디자인 다시 바꾸자 너무 별로다
class AlbumMemberManageDialog extends StatefulWidget {
  final AlbumWithMyInfoModel album;

  const AlbumMemberManageDialog({
    super.key,
    required this.album,
  });

  @override
  State<AlbumMemberManageDialog> createState() =>
      _AlbumMemberManageDialogState();
}

class _AlbumMemberManageDialogState extends State<AlbumMemberManageDialog> {
  bool _isLoading = true;
  bool _isUpdating = false; // 서버 업데이트 중 로딩 표시용
  List<AlbumMemberUiModel> _members = [];

  late String _albumName;

  @override
  void initState() {
    super.initState();
    _albumName = widget.album.name;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final albumProvider = context.read<AlbumProvider>();
      final userProvider = context.read<UserProvider>();
      final myUserId = userProvider.userId; // 실제 필드명에 맞게 수정

      final rawMembers = await albumProvider.fetchAlbumMembers(widget.album.id);

      final members = rawMembers.map((m) {
        return AlbumMemberUiModel(
          id: m.memberId,
          userId: m.userId,
          name: m.name,           // user.displayName or label
          role: m.role,           // 'owner' / 'manager' / 'viewer'
          label: m.label ?? '',
          isMe: m.userId == myUserId,
        );
      }).toList();

      // 정렬: owner → manager → viewer
      members.sort((a, b) => _rolePriority(a.role).compareTo(
        _rolePriority(b.role),
      ));

      setState(() {
        _members = members;
      });
    } catch (e) {
      print("❌ fetchAlbumMembers error: $e");   // 이 라인 추가!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구성원 정보를 불러오지 못했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _amIOwner => widget.album.myRole == 'owner';
  bool get _amIManager => widget.album.myRole == 'manager';
  bool get _canEditAlbum => widget.album.myRole == 'owner' || widget.album.myRole == 'manager';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color(0xFFF3FDF6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 480,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ───────── 상단 핸들 + 타이틀 ─────────
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ───────── 앨범 제목 + 수정 버튼 ─────────
              SizedBox(
                height: 32, // 높이는 상황에 맞춰 조절
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 가운데 정렬된 앨범명
                    Center(
                      child: Text(
                        _albumName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // 오른쪽 상단에 붙는 수정 버튼 (owner만)
                    if (_canEditAlbum)
                      Positioned(
                        right: 0,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF4CAF81)),
                          onPressed: _openAlbumEditScreen,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ───────── 초대 코드 공유 버튼 ─────────
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _onInviteSharePressed(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF4CAF81),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '🔑  초대 코드 공유하기',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '앨범 구성원',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              if (_amIOwner)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '· 체크하면 매니저 권한을 줄 수 있어요.\n· 자신을 제외한 모든 구성원을 강퇴할 수 있어요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else if (_amIManager)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '· 구성원(viewer)만 강퇴할 수 있어요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _members.isEmpty
                    ? const Center(
                  child: Text(
                    '구성원이 없습니다.',
                    style: TextStyle(fontSize: 13),
                  ),
                )
                    : Stack(
                  children: [
                    ListView.separated(
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 0.4,
                      ),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return _buildMemberTile(member);
                      },
                    ),
                    if (_isUpdating)
                      Container(
                        color: Colors.white.withOpacity(0.5),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ───────── 닫기 버튼 ─────────
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberTile(AlbumMemberUiModel member) {
    final isOwner = member.role == 'owner';
    final isManager = member.role == 'manager';
    final isViewer = member.role == 'viewer';
    final isMe  = member.isMe;

    // 체크박스 활성 여부: owner만 매니저 권한 변경 가능, owner 행은 체크박스 없음
    final canToggleManager = _amIOwner && !isOwner;

    // 강퇴 가능 여부:
    // - owner: 자기 자신 제외 모두 가능
    // - manager: viewer 만 가능 (자기 자신은 보통 제외)
    final canKick = _canKick(member, isOwner, isManager, isViewer);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: isOwner
          ? const Icon(
        Icons.star_rounded,
        color: Color(0xFFFFB300),
      )
          : Checkbox(
        value: isManager,
        onChanged: canToggleManager
            ? (value) {
          _onToggleManager(member, value ?? false);
        }
            : null,
      ),
      title: Text(
        member.label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        member.name,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
      trailing: isMe
          ? IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF4CAF81),
              ),
              onPressed: () => _onEditMemberLabel(member),
            )
          : (canKick
              ? IconButton(
                  icon: const Icon(
                    Icons.person_remove_rounded,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _onKickMember(member),
                )
              : null),
    );
  }

  bool _canKick(
      AlbumMemberUiModel member,
      bool isOwner,
      bool isManager,
      bool isViewer,
      ) {
    if (_amIOwner) {
      // 소유자는 자기 자신만 강퇴 불가
      return !member.isMe;
    }

    if (_amIManager) {
      // 매니저는 viewer 만 강퇴 가능 (자기 자신은 강퇴X)
      return isViewer && !member.isMe;
    }

    // viewer 는 누구도 강퇴 불가
    return false;
  }

  Future<void> _onToggleManager(
      AlbumMemberUiModel member, bool makeManager) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final albumProvider = context.read<AlbumProvider>();

      final newRole = makeManager ? 'manager' : 'viewer';

      // 🔻 실제 API/메서드에 맞게 수정
      await albumProvider.updateMemberRole(
        albumId: widget.album.id,
        memberId: member.id,
        newRole: newRole,
      );

      setState(() {
        member.role = newRole;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('권한 변경 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _onKickMember(AlbumMemberUiModel member) async {
    // TODO: 내보내기 후 토닥리스트도 전부 is_deleted = true 처리 필요
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('구성원 내보내기'),
          content: Text('"${member.name}" 님을 앨범에서 내보낼까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                '내보내기',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final albumProvider = context.read<AlbumProvider>();

      // 🔻 실제 API/메서드에 맞게 수정
      await albumProvider.removeMember(
        albumId: widget.album.id,
        memberId: member.id,
      );

      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구성원 내보내기 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _onInviteSharePressed(BuildContext context) async {
    // 초대 코드 공유 바텀시트
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AlbumInviteShareSheet(albumId: widget.album.id);
      },
    );
  }

  int _rolePriority(String role) {
    switch (role) {
      case 'owner':
        return 0;
      case 'manager':
        return 1;
      case 'viewer':
      default:
        return 2;
    }
  }

  Future<void> _onEditMemberLabel(AlbumMemberUiModel member) async {
    final newLabel = await showNameEditBottomSheet(
      context: context,
      title: '앨범에서 사용할 이름',
      hintText: '예: 엄마, 아빠, 할머니',
      initialText: member.label.isNotEmpty ? member.label : member.name,
    );

    if (newLabel == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final albumProvider = context.read<AlbumProvider>();

      await albumProvider.updateMemberLabel(
        albumId: widget.album.id,
        memberId: member.id,
        newLabel: newLabel,
      );

      setState(() {
        member.label = newLabel;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _openAlbumEditScreen() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumEditScreen(album: widget.album),
      ),
    );

    // changed == true 면 다이얼로그 타이틀도 즉시 반영되게 새로고침
    if (changed == true) {
      final albumProvider = context.read<AlbumProvider>();
      final updated = albumProvider.albums.firstWhere((a) => a.id == widget.album.id);

      if (!mounted) return;
      setState(() {
        _albumName = updated.name;
      });
    }
  }


}

// ─────────────────────────────────
// UI 에서만 쓰는 멤버 모델 (필드명은 실제 DB/모델에 맞춰 매핑)
// ─────────────────────────────────
class AlbumMemberUiModel {
  final String id;      // album_members PK
  final String userId;  // users.id
  String name;
  String role;          // 'owner' / 'manager' / 'viewer'
  String label;
  final bool isMe;

  AlbumMemberUiModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
    required this.label,
    required this.isMe,
  });
}