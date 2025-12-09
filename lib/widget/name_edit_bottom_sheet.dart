import 'package:flutter/material.dart';

/// 공용 이름/라벨 입력 바텀시트
///
/// 사용 예:
/// final result = await showNameEditBottomSheet(
///   context: context,
///   title: '앨범에서 사용할 이름',
///   hintText: '예: 엄마, 아빠, 할머니',
///   initialText: currentLabel,
/// );
/// if (result != null) { ... 저장 ... }
Future<String?> showNameEditBottomSheet({
  required BuildContext context,
  String title = '이름을 입력해 주세요',
  String hintText = '예: 홍길동',
  String confirmText = '확인',
  String cancelText = '취소',
  String? initialText,
}) {
  return showModalBottomSheet<String>(
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
        child: _NameEditSheet(
          title: title,
          hintText: hintText,
          confirmText: confirmText,
          cancelText: cancelText,
          initialText: initialText,
        ),
      );
    },
  );
}

class _NameEditSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String confirmText;
  final String cancelText;
  final String? initialText;

  const _NameEditSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.confirmText,
    required this.cancelText,
    this.initialText,
  });

  @override
  State<_NameEditSheet> createState() => _NameEditSheetState();
}

class _NameEditSheetState extends State<_NameEditSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSave() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        _errorText = '이름을 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final hasInitial = (widget.initialText?.isNotEmpty ?? false);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🖊️', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onSave(),
              decoration: InputDecoration(
                hintText: widget.hintText,
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
                if (hasInitial)
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _isSaving
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
                      child: Text(
                        widget.cancelText,
                        style: const TextStyle(
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
                    onPressed: _isSaving ? null : _onSave,
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
                    child: _isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      widget.confirmText,
                      style: const TextStyle(
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
