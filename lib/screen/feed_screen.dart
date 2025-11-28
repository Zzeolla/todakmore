import 'package:flutter/material.dart';
import 'package:todakmore/widget/feed_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});
  // TODO: 추후 필터링도 추가하는건 어떨까 앨범 필터링

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9), // 아주 옅은 배경
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: 10, // 임시
        itemBuilder: (context, index) {
          return const FeedCard();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/upload-select');
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
