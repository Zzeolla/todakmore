import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:todakmore/model/media_item.dart';
import 'package:todakmore/widget/hashtag_pill.dart';

// TODO: 나중에 더블클릭으로 토닥 시 애니메이션 추가 기능은
// '토닥 DB 설계 안내' 참고

class FeedCard extends StatelessWidget {
  final MediaItem item;
  final bool didTodak;        // 사용자가 토닥했는지 여부
  final bool isDownloading;
  final VoidCallback onTodak; // 토닥 클릭
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const FeedCard({
    super.key,
    required this.item,
    required this.didTodak,
    required this.onTodak,
    this.onDownload,
    this.onDelete,
    this.onEdit,
    this.onTap,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    const todakBackground = Color(0xFFFFF9F4); // Cream White
    const todakText = Color(0xFF444444);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───────── 상단 이미지/영상 영역 ─────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: GestureDetector(
                onDoubleTap: onTodak,
                child: AspectRatio(
                  aspectRatio: 1, // 피드는 정사각형
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 썸네일/이미지
                      Hero(
                        tag: 'media_${item.id}', // ⭐ MediaFullScreen과 맞추기
                        child: CachedNetworkImage(
                          imageUrl: item.displayUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: todakBackground,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),

                      // 동영상일 때 재생 아이콘 + duration 뱃지
                      if (item.isVideo) ...[
                        // 가운데 재생 아이콘
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 56,
                            color: Colors.white70,
                          ),
                        ),
                        // 오른쪽 아래 duration
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(item.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // 다운로드 인디케이터 (있으면)
                      if (isDownloading)
                        Container(
                          color: Colors.black.withOpacity(0.25),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ───────── 아래 앨범명 / 날짜 / 액션 영역 ─────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 해시태그: Row 아래 + 1줄 고정 + 가로 스크롤
                  if (item.tags.isNotEmpty) ...[
                    SizedBox(
                      height: 34, // 칩 높이 맞춰서 1줄 고정
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.tags.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => HashtagPill(tag: item.tags[i]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 앨범 커버
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.albumCoverUrl.isEmpty
                            ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1FD), // 연보라 톤
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              '👶',
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        )
                            : SizedBox(
                          width: 40,
                          height: 40,
                          child: CachedNetworkImage(
                            imageUrl: item.albumCoverUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 120,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFFF1F1FD),
                            ),
                            errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined, size: 20),
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
                              item.albumName,
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
                              item.formattedDateTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 토닥 버튼
                      GestureDetector(
                        onTap: onTodak,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: didTodak
                                ? const Color(0xFFCFF8DD)
                                : Colors.grey.shade100,
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

                      // 다운로드 버튼 (옵션)
                      if (onDownload != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 22,
                          ),
                          onPressed: onDownload,
                        ),
                      ],

                      // 삭제 메뉴 (옵션, ... 팝업)
                      if (onDelete != null || onEdit != null) ...[
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            if (value == 'edit') onEdit?.call();
                            if (value == 'delete') onDelete?.call();
                          },
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('수정하기'),
                              ),
                            if (onDelete != null)
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('삭제하기', style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// duration(double? 초) → "0:15" 형태로 표기
  static String _formatDuration(double? seconds) {
    if (seconds == null) return '0:00';
    final total = seconds.round();
    final m = total ~/ 60;
    final s = total % 60;
    final sStr = s.toString().padLeft(2, '0');
    return '$m:$sStr';
  }
}