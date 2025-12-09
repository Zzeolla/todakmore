import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/model/media_item.dart';
import 'package:todakmore/provider/todak_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/screen/media_full_screen.dart';
import 'package:todakmore/widget/common_app_bar.dart';
import 'package:http/http.dart' as http;

class TodakScreen extends StatefulWidget {
  const TodakScreen({super.key});

  @override
  State<TodakScreen> createState() => _TodakScreenState();
}

class _TodakScreenState extends State<TodakScreen> {
  bool _loading = true;
  List<MediaItem> _items = [];
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userId = context.read<UserProvider>().userId;
      if (userId == null) {
        setState(() {
          _loading = false;
          _items = [];
        });
        return;
      }

      final mediaItems = await context
          .read<TodakProvider>()
          .fetchTodakMediaItems(userId: userId);

      if (!mounted) return;

      setState(() {
        _items = mediaItems;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('fetchTodakMediaItems error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('토닥한 사진을 불러오지 못했어요. 😢')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todakProvider = context.watch<TodakProvider>();

    return Scaffold(
      appBar: CommonAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '모아보기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '내가 토닥한 사진들을 한눈에 볼 수 있어요\n최대 30장만 저장 가능합니다',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9A9A9A),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('아직 토닥한 사진이 없어요 😊'))
                : RefreshIndicator(
              onRefresh: _load,
              child: GridView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 12),
                physics:
                const AlwaysScrollableScrollPhysics(), // 아이템 적어도 스크롤 제스처 가능
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  // media_todaks.media_id == album_medias.id 라면 이걸로 체크
                  final didTodak = todakProvider.didTodak(item.id);

                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context).push<String?>(
                        MaterialPageRoute(
                          builder: (_) => MediaFullScreen(item: item),
                        ),
                      );

                      if (result == 'download') {
                        await _handleDownload(item);
                      }

                      await _load(); // 돌아온 뒤 목록 새로고침
                    },
                    // TODO : 더블탭 시 토닥 토글은 리스크가 있을 수 있으니 추후 결정
                    // onDoubleTap: () async {
                    //   final userId =
                    //       context.read<UserProvider>().userId;
                    //   if (userId == null) return;
                    //
                    //   await todakProvider.toggleTodak(
                    //     albumId: item.albumId,
                    //     mediaId: item.id,
                    //     userId: userId,
                    //   );
                    //
                    //   // 토글 후 상태 반영 위해 다시 로드
                    //   _load();
                    // },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item.displayUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(
                                  color: Colors.grey.shade200,
                                ),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                          ),
                        ),
                        if (item.isVideo)
                          const Positioned(
                            left: 6,
                            bottom: 6,
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(MediaItem item) async {
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
  }
}
