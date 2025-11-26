import 'package:flutter/material.dart';

class TodakScreen extends StatelessWidget {
  const TodakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '토닥 모아보기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '내가 토닥한 사진들을 한눈에 볼 수 있어요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9A9A9A),
            ),
          ),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(
              child: Text('📷 그리드 갤러리는 나중에 구현!'),
            ),
          ),
        ],
      ),
    );
  }
}
