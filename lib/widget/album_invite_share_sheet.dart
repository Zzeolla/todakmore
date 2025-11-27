import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todakmore/service/invite_code_service.dart'; // 경로는 프로젝트에 맞게 수정

class AlbumInviteShareSheet extends StatefulWidget {
  final String albumId;

  const AlbumInviteShareSheet({
    super.key,
    required this.albumId,
  });

  @override
  State<AlbumInviteShareSheet> createState() => _AlbumInviteShareSheetState();
}

class _AlbumInviteShareSheetState extends State<AlbumInviteShareSheet> {
  String? _inviteCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createCode();
  }

  Future<void> _createCode() async {
    try {
      final code = await InviteCodeService.createInviteCodeForAlbum(widget.albumId);
      if (!mounted) return;
      setState(() {
        _inviteCode = code;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대 코드를 만들지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
      Navigator.of(context)..pop();
    }
  }

  Future<void> _copyCode() async {
    if (_inviteCode == null) return;
    await Clipboard.setData(ClipboardData(text: _inviteCode!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드가 복사되었어요')),
    );
  }

  Future<void> _shareCode() async {
    if (_inviteCode == null) return;
    InviteCodeService.shareInviteCode(_inviteCode!);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF1F1FD);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _isLoading
            ? const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          ),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            Row(
              children: const [
                Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 26)),
                SizedBox(width: 8),
                Text(
                  '가족에게 초대 코드를 보내볼까요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '이 코드는 20분 후 만료됩니다',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const SizedBox(height: 20),

            // 코드 박스
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _inviteCode ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('코드 복사'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareCode,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('공유하기'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('나중에 할게요'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
