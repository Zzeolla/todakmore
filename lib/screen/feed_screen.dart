import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/provider/feed_provider.dart';
import 'package:todakmore/provider/todak_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/screen/media_full_screen.dart';
import 'package:todakmore/service/media_download_service.dart';
import 'package:todakmore/widget/common_app_bar.dart';
import 'package:todakmore/widget/common_hashtag_input.dart';
import 'package:todakmore/widget/feed_card.dart';
import 'package:todakmore/model/media_item.dart';

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
        onPressed: () => _onUploadPressed(context),
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
            return RefreshIndicator(
              onRefresh: () async {
                await feedProvider.loadInitial();
                await context
                    .read<UserProvider>()
                    .refreshAlbumManagePermission();
              },
              child: ListView(
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
              ),
            );
          }

          // ✅ 항상 RefreshIndicator로 감싸기
          return RefreshIndicator(
            onRefresh: () async {
              await feedProvider.loadInitial();
              await context
                  .read<UserProvider>()
                  .refreshAlbumManagePermission();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: items.length + (feedProvider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  // 하단 로딩 인디케이터
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final MediaItem item = items[index];
                final canManageThisItem = context.read<AlbumProvider>().canManageAlbumId(item.albumId);

                return _FeedCardWithTodak(
                  item: item,
                  isDownloading: _downloadingId == item.id,
                  onDownload: () => _handleDownload(item),
                  onDelete: canManageThisItem ? () => _handleDelete(item) : null,
                  onEdit: canManageThisItem ? () => _openEditTagsSheet(context, item) : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _onUploadPressed(BuildContext context) async {
    final albumProvider = context.read<AlbumProvider>();
    final userProvider = context.read<UserProvider>();

    final uploadAlbum = await albumProvider.ensureUploadableAlbumSelected();

    if (uploadAlbum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('업로드할 수 있는 앨범이 없어요.\n내가 만든 앨범을 먼저 만들어 주세요.'),
        ),
      );
      return;
    }

    // 👉 바뀌었는지 따지지 말고, 그냥 매번 동기화해도 됨
    await userProvider.updateLastAlbumId(uploadAlbum.id);

    if (!mounted) return;
    Navigator.pushNamed(context, '/upload-select');
  }

// ───────────────── 다운로드 처리 ─────────────────
  Future<void> _handleDownload(MediaItem item) async {
    if (_downloadingId == item.id) return;

    setState(() {
      _downloadingId = item.id;
    });

    try {
      final result = await MediaDownloadService.downloadMedia(item);

      if (!mounted) return;

      switch (result) {
        case MediaDownloadResult.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('갤러리 접근 권한을 허용해 주세요.')),
          );
          break;
        case MediaDownloadResult.savedImage:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('갤러리에 저장됐어요. 😊')),
          );
          break;
        case MediaDownloadResult.savedVideo:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('영상이 갤러리에 저장됐어요. 🎬')),
          );
          break;
        case MediaDownloadResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('다운로드 중 오류가 발생했어요.')),
          );
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingId = null;
        });
      }
    }
  }

  // ───────────────── 삭제 처리 ─────────────────
  Future<void> _handleDelete(MediaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('사진/영상 삭제'),
          content: const Text('정말 이 사진/영상을 삭제하시겠어요?'),
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

  Future<void> _openEditTagsSheet(BuildContext context, MediaItem item) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    List<String> editTags = [...item.tags];

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            const bg = Color(0xFFFFF9F4);
            const lavender = Color(0xFFC6B6FF);

            // ✅ 저장 가능 조건:
            // - 입력 중인 텍스트가 없어야 함(확정 안 된 태그)
            // - 9글자 이상이면 입력 중 텍스트가 있으므로 저장 불가
            final pending = controller.text.trim();
            final canSave = pending.isEmpty;

            void showMsg(String msg) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 핸들
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),

                      // 타이틀 + 닫기
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '해시태그 수정',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF444444),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ✅ 여기서 공용 입력 위젯 하나만 사용
                      CommonHashtagInput(
                        enabled: true,
                        controller: controller,
                        focusNode: focusNode,
                        tags: editTags,
                        onChanged: (next) {
                          setModalState(() => editTags = next);
                        },
                        title: '해시태그 (이 사진)',
                        helperText: '최대 3개 · 태그당 8글자',
                        compact: true,
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text(
                                '취소',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lavender,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                // ✅ “왜 저장 안되는지” 안내
                                if (!canSave) {
                                  showMsg('입력 중인 해시태그를 엔터(완료)로 확정한 뒤 저장해 주세요.');
                                  focusNode.requestFocus();
                                  return;
                                }
                                Navigator.pop(sheetContext, editTags);
                              },
                              child: const Text(
                                '저장',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
    focusNode.dispose();

    if (result == null) return;

    try {
      await context.read<FeedProvider>().updateTags(mediaId: item.id, tags: result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해시태그를 저장했어요.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했어요. 권한/RLS를 확인해 주세요.')),
      );
    }
  }

}

class _FeedCardWithTodak extends StatelessWidget {
  final MediaItem item;
  final bool isDownloading;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _FeedCardWithTodak({
    super.key,
    required this.item,
    required this.isDownloading,
    this.onDownload,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 이 카드가 "자기 mediaId의 didTodak 값만" 구독
    final didTodak =
    context.select<TodakProvider, bool>((p) => p.didTodak(item.id));

    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId;
    final todakLimit = userProvider.todakLimit;

    return FeedCard(
      item: item,
      didTodak: didTodak,
      isDownloading: isDownloading,
      onTodak: () async {
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 후 이용해 주세요.')),
          );
          return;
        }

        await context.read<TodakProvider>().toggleTodak(
          albumId: item.albumId,
          mediaId: item.id,
          userId: userId,
          maxTodaks: todakLimit,
        );
      },
      onDownload: onDownload,
      onDelete: onDelete,
      onEdit: onEdit,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MediaFullScreen(item: item),
          ),
        );
      },
    );
  }
}