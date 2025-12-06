import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/model/media_item.dart';
import 'package:todakmore/provider/todak_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:video_player/video_player.dart';

class MediaFullScreen extends StatefulWidget {
  final MediaItem item;

  const MediaFullScreen({
    super.key,
    required this.item,
  });

  @override
  State<MediaFullScreen> createState() => _MediaFullScreenState();
}

class _MediaFullScreenState extends State<MediaFullScreen> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoFuture;

  bool get _isVideo => widget.item.isVideo;

  @override
  void initState() {
    super.initState();

    if (_isVideo) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.item.url));

      _initializeVideoFuture = _videoController!.initialize().then((_) {
        _videoController!
          ..setLooping(true)
          ..play();

        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const todakText = Color(0xFFEEEEEE);

    final todakProvider = context.watch<TodakProvider>();
    final didTodak = todakProvider.didTodak(widget.item.id);
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId;
    final todakLimit = userProvider.todakLimit;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ───────── 중앙 미디어(이미지/영상) ─────────
            Positioned.fill(
              child: Center(
                child: _isVideo ? _buildVideo() : _buildImage(),
              ),
            ),

            // ───────── 상단 닫기 버튼 ─────────
            Positioned(
              top: 4,
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // ───────── 하단 바: 커버 + 앨범명/시간 + 토닥 + 다운로드 ─────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 앨범 커버
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.item.albumCoverUrl.isEmpty
                              ? Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '👶',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                              : SizedBox(
                            width: 40,
                            height: 40,
                            child: CachedNetworkImage(
                              imageUrl: widget.item.albumCoverUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 120,
                              placeholder: (_, __) => Container(
                                color: Colors.white12,
                              ),
                              errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined,
                                  size: 20, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 앨범명 + 날짜
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.albumName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: todakText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.item.formattedDateTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 토닥 버튼
                        GestureDetector(
                          onTap: () async {
                            if (userId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('로그인 후 이용해 주세요.')),
                              );
                              return;
                            }

                            await todakProvider.toggleTodak(
                              albumId: widget.item.albumId,
                              mediaId: widget.item.id,
                              userId: userId,
                              maxTodaks: todakLimit,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: didTodak
                                  ? const Color(0xFFCFF8DD)
                                  : Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              didTodak
                                  ? 'assets/img/todak_on.png'
                                  : 'assets/img/todak_off.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ),

                        // 다운로드 버튼
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.file_download_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            // TodakScreen / FeedScreen에서 pop 결과 보고 처리
                            Navigator.of(context).pop('download');
                          },
                        ),

                        // TODO: 삭제 메뉴도 여기서 추가 가능 (Navigator.pop('delete') 후 상위에서 처리)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── 이미지일 때 뷰 ─────────────────
  Widget _buildImage() {
    return Hero(
      tag: 'media_${widget.item.id}', // FeedCard와 동일
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: SizedBox.expand(
          child: CachedNetworkImage(
            imageUrl: widget.item.displayUrl,
            fit: BoxFit.contain, // 가로 기준 거의 꽉 차게
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── 동영상일 때 뷰 ─────────────────
  Widget _buildVideo() {
    if (_videoController == null || _initializeVideoFuture == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return FutureBuilder(
      future: _initializeVideoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final value = _videoController!.value;
          final aspect =
          value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio;

          return AspectRatio(
            aspectRatio: aspect,
            child: GestureDetector(
              onTap: () {
                if (value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
                setState(() {});
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  if (!_videoController!.value.isPlaying)
                    const Icon(
                      Icons.play_circle_fill,
                      size: 64,
                      color: Colors.white70,
                    ),
                ],
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
      },
    );
  }
}
