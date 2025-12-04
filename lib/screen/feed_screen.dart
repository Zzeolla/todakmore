import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/feed_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/widget/common_app_bar.dart';
import 'package:todakmore/widget/feed_card.dart';
import 'package:todakmore/model/feed_item.dart';
import 'package:http/http.dart' as http;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}
// TODO : 광고 추가할 예정이며 광고 추가하면 반드시 구글플레이콘솔에서 정보 바꿔야함
class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _downloadingId;

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
      appBar: CommonAppBar(),
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
                  date: item.formattedDateTime,
                  imageUrl: item.displayUrl,
                  coverUrl: item.albumCoverUrl,
                  didTodak: false,
                  isDownloading: _downloadingId == item.id,
                  onTodak: () {
                    // TODO: 나중에 토닥 기능 붙이기
                  },
                  onDownload: () async {
                    if (_downloadingId == item.id) return;

                    setState(() {
                      _downloadingId = item.id;
                    });

                    try {
                      // 1) 권한 요청
                      final permission = await PhotoManager.requestPermissionExtend();
                      if (!permission.isAuth) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('갤러리 접근 권한을 허용해 주세요.')),
                          );
                        }
                        return;
                      }

                      // 2) Supabase Storage URL에서 바이트 다운로드
                      final uri = Uri.parse(item.url); // 원본 URL 사용
                      final response = await http.get(uri);

                      if (response.statusCode != 200) {
                        throw Exception('다운로드 실패: ${response.statusCode}');
                      }

                      final bytes = response.bodyBytes;

                      // 3) 타입에 따라 저장
                      if (item.isVideo) {
                        // 👉 영상 저장 (원하면 나중에 구현)
                        // final tempDir = await getTemporaryDirectory();
                        // final filePath = p.join(tempDir.path, '${item.id}.mp4');
                        // final file = File(filePath);
                        // await file.writeAsBytes(bytes);
                        // await PhotoManager.editor.saveVideo(file);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('영상 저장은 나중에 지원할 예정이에요.')),
                          );
                        }
                      } else {
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final filename = 'todak_${item.albumName}_$timestamp.jpg';
                        // 👉 사진 저장
                        await PhotoManager.editor.saveImage(
                          bytes,
                          filename: filename,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('갤러리에 저장됐어요. 😊')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('다운로드 중 오류가 발생했어요: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _downloadingId = null;
                        });
                      }
                    }
                  },
                  onDelete: canUpload
                      ? () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('사진 삭제'),
                          content: const Text('정말 이 사진을 삭제하시겠어요?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text(
                                '삭제',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm == true) {
                      await context.read<FeedProvider>().deleteItem(item.id);
                    }
                  }
                      : null, // 권한 없으면 메뉴 안 보임
                );
              },
            ),
          );
        },
      ),
    );
  }
}

