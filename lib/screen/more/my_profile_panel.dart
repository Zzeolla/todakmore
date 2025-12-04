import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';

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

  void _openEditNameSheet(BuildContext context, String? currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: const _EditNameSheet(),
        );
      },
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  final String? initialName;

  const _EditNameSheet({super.key, this.initialName});

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _nameController;
  bool _isSavingName = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = '이름을 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isSavingName = true;
      _errorText = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.updateDisplayName(name);

      if (!mounted) return;
      Navigator.of(context).pop(); // 바텀시트 닫기
    } catch (e) {
      setState(() {
        _errorText = '이름 저장 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasName = (widget.initialName?.isNotEmpty ?? false);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE9FCEF), // Mint Breeze
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, -4),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목 + 아이콘
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('👋', style: TextStyle(fontSize: 20)),
                SizedBox(width: 6),
                Text(
                  '이름을 입력해 주세요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveName(),
              decoration: InputDecoration(
                hintText: '예: 홍길동',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB0B0B0),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorText!,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasName)
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _isSavingName
                          ? null
                          : () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F2F2),
                        foregroundColor: const Color(0xFF4A4A4A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide.none,
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSavingName ? null : _saveName,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF4CAF81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSavingName
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
