import 'package:flutter/material.dart';
import 'package:todakmore/widget/hashtag_pill.dart';

class CommonHashtagInput extends StatelessWidget {
  final bool enabled;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String title;
  final String? helperText;
  final bool compact;

  const CommonHashtagInput({
    super.key,
    required this.enabled,
    required this.controller,
    required this.focusNode,
    required this.tags,
    required this.onChanged,
    this.title = '해시태그',
    this.helperText,
    this.compact = false,
  });

  static const int _maxTags = 3;
  static const int _maxLen = 8;

  String _normalize(String raw) {
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.toLowerCase();
    return s;
  }

  void _commit(BuildContext context, String raw) {
    if (!enabled) return;
    if (tags.length >= _maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해시태그는 최대 3개까지 가능해요.')),
      );
      return;
    }

    final tag = _normalize(raw);
    if (tag.isEmpty) return;

    if (tag.length > _maxLen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해시태그는 8글자 이하만 가능해요.')),
      );
      return;
    }

    if (tags.contains(tag)) {
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 추가된 해시태그예요.')),
      );
      return;
    }

    onChanged([...tags, tag]);
    controller.clear();
    focusNode.requestFocus();
  }

  void _handleChanged(BuildContext context, String v) {
    if (v.contains(' ') || v.contains('\n')) {
      final parts = v.split(RegExp(r'[\s\n]+')).where((e) => e.isNotEmpty).toList();
      for (final p in parts) {
        if (tags.length >= _maxTags) break;
        _commit(context, p);
      }
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    const lavender = Color(0xFFC6B6FF);
    const bg = Color(0xFFFFF9F4);
    const text = Color(0xFF444444);

    final canType = enabled && tags.length < _maxTags;

    final radius = compact ? 22.0 : 24.0;
    final pad = compact ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: lavender.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: lavender.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.tag_rounded, size: 18, color: text),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: lavender.withOpacity(0.18)),
                ),
                child: Text(
                  '${tags.length}/$_maxTags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          if (helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              helperText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── 태그 목록
          if (tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      HashtagPill(tag: t),
                      if (enabled)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: GestureDetector(
                            onTap: () {
                              final next = [...tags]..remove(t);
                              onChanged(next);
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: lavender.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                    color: Colors.black.withOpacity(0.12),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── 입력 영역 (고정폭 제거 + 버튼)
          Opacity(
            opacity: canType ? 1.0 : 0.55,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lavender.withOpacity(0.16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Text(
                    '#',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: canType,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: text,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: canType ? '예) 첫돌, 가족여행, 첫걸음' : '최대 $_maxTags개까지 가능해요',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      onChanged: (v) => _handleChanged(context, v),
                      onSubmitted: (v) => _commit(context, v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: canType ? () => _commit(context, controller.text) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: lavender,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                            color: Colors.black.withOpacity(0.12),
                          ),
                        ],
                      ),
                      child: const Text(
                        '추가',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── 하단 안내 (톤 맞게)
          Text(
            '최대 $_maxTags개 · 태그당 $_maxLen글자 · 엔터/스페이스로 확정',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
