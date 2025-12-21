import 'package:flutter/material.dart';

class HashtagPill extends StatelessWidget {
  final String tag;
  final double fontSize;

  const HashtagPill({
    super.key,
    required this.tag,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    const lavender = Color(0xFFC6B6FF);
    const text = Color(0xFF3F3F46);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // ✅ 유리알(글래스) 느낌: 아주 연한 라벤더 톤
        color: lavender.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: lavender.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ #을 따로 스타일링 (더 고급스러움)
          Text(
            '#',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: lavender.withOpacity(0.9),
              height: 1.0,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
              color: text,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
