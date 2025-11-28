import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/feed_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/widget/feed_card.dart';
import 'package:todakmore/model/feed_item.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 첫 진입 시 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().refreshAlbumManagePermission();
      context.read<FeedProvider>().loadInitial();
    });

    // 무한스크롤 감지
    _scrollController.addListener(() {
      final provider = context.read<FeedProvider>();
      if (!provider.hasMore || provider.isLoading) return;

      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        provider.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = context.watch<UserProvider>().hasAnyOwnerOrManager;

    return Scaffold(
      floatingActionButton: canUpload
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/upload-select');
        },
        backgroundColor: const Color(0xFFC6B6FF), // Todak Lavender
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      )
          : null,

      body: Consumer<FeedProvider>(
        builder: (context, feedProvider, _) {
          final items = feedProvider.items;

          if (feedProvider.isLoading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return const Center(
              child: Text(
                '아직 올려진 사진이 없어요.\n첫 사진을 올려볼까요?',
                textAlign: TextAlign.center,
              ),
            );
          }

          // ✅ 항상 RefreshIndicator로 감싸기
          return RefreshIndicator(
            onRefresh: () async {
              await feedProvider.loadInitial();
              await context.read<UserProvider>().refreshAlbumManagePermission();
            },
            child: items.isEmpty
            // ✅ 비어 있을 때도 당겨서 새로고침 가능하도록 ListView + AlwaysScrollableScrollPhysics
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    '아직 올려진 사진이 없어요.\n첫 사진을 올려볼까요?',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
            // ✅ 기존 목록 있는 경우는 그대로 유지
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: items.length + (feedProvider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  // 하단 로딩 인디케이터
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final FeedItem item = items[index];

                return FeedCard(
                  albumName: item.albumName,
                  date: item.formattedDate,
                  imageUrl: item.url,
                  coverUrl: item.albumCoverUrl,
                  didTodak: false,
                  onTodak: () {
                    // TODO: 나중에 토닥 기능 붙이기
                  },
                  onDownload: () {
                    // TODO: 갤러리 저장 기능 나중에
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

