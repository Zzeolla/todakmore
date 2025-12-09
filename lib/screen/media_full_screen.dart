import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/model/media_item.dart';
import 'package:todakmore/provider/todak_provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/service/media_download_service.dart';

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
  Player? _player;
  VideoController? _videoController;
  bool _isInitializingVideo = false;
  bool _isDownloading = false;

  bool get _isVideo => widget.item.isVideo;

  @override
  void initState() {
    super.initState();

    if (_isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    setState(() => _isInitializingVideo = true);

    final player = Player();
    final controller = VideoController(player);

    // 반복 재생 + 자동 재생
    await player.open(
      Media(widget.item.url),
      play: true,
    );
    await player.setPlaylistMode(PlaylistMode.loop);

    if (!mounted) {
      await player.dispose();
      return;
    }

    setState(() {
      _player = player;
      _videoController = controller;
      _isInitializingVideo = false;
    });
  }

  @override
  void dispose() {
    _player?.dispose();
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
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.file_download_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          onPressed: _isDownloading
                              ? null
                              : () async {
                            setState(() => _isDownloading = true);

                            final result =
                            await MediaDownloadService.downloadMedia(widget.item);

                            if (!mounted) return;
                            setState(() => _isDownloading = false);

                            switch (result) {
                              case MediaDownloadResult.permissionDenied:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('갤러리 접근 권한을 허용해 주세요.'),
                                  ),
                                );
                                break;
                              case MediaDownloadResult.savedImage:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('갤러리에 저장됐어요. 😊'),
                                  ),
                                );
                                break;
                              case MediaDownloadResult.savedVideo:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('영상이 갤러리에 저장됐어요. 🎬'),
                                  ),
                                );
                                break;
                              case MediaDownloadResult.failed:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('다운로드 중 오류가 발생했어요.'),
                                  ),
                                );
                                break;
                            }
                          },
                        ),
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


  // ───────────────── 동영상일 때 뷰 (media_kit_video) ─────────────────
  Widget _buildVideo() {
    if (_isInitializingVideo || _player == null || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // 재생 여부를 실시간으로 받아서 아이콘 토글
    return StreamBuilder<bool>(
      stream: _player!.stream.playing,
      initialData: _player!.state.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return GestureDetector(
          onTap: () {
            if (isPlaying) {
              _player!.pause();
            } else {
              _player!.play();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video 위젯: 색감은 media_kit_video가 알아서
              Video(
                controller: _videoController!,
                fit: BoxFit.contain,
              ),
              if (!isPlaying)
                const Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white70,
                ),
            ],
          ),
        );
      },
    );
  }
}
