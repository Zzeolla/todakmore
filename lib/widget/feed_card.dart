import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FeedCard extends StatelessWidget {
  final String albumName;
  final String date; // '2025.11.28'
  final String imageUrl;
  final String coverUrl;
  final bool didTodak;        // 사용자가 토닥했는지 여부
  final bool isDownloading;
  final VoidCallback onTodak; // 토닥 클릭
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const FeedCard({
    super.key,
    required this.albumName,
    required this.date,
    required this.imageUrl,
    required this.coverUrl,
    required this.didTodak,
    required this.onTodak,
    this.onDownload,
    this.onDelete,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------- Header --------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 앨범 커버
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: coverUrl.isEmpty
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1FD), // 연보라 톤 (토닥모아 테마)
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              '👶',                   // 원하는 이모지로 변경 가능
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: 40,
                          height: 40,
                          child: CachedNetworkImage(
                            imageUrl: coverUrl,
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
                        albumName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date, // ← yyyy.mm.dd
                        style: const TextStyle(
                          color: Color(0xFF9A9A9A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ 우측 상단 ... 메뉴 (삭제)
                if (onDelete != null)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          '삭제하기',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // -------------------- Main Photo --------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,

                  // 🔥 여기서 디코딩 사이즈 제한
                  memCacheWidth: 800, // 기기 가로폭보다 조금 큰 정도(600~1000 사이 아무거나)

                  placeholder: (context, url) => Container(
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // -------------------- Bottom actions --------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // 👋 토닥 버튼
                GestureDetector(
                  onTap: onTodak,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: didTodak ? const Color(0xFFCFF8DD) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '👋',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),

                const Spacer(),

                // 다운로드 버튼 / 로딩 인디케이터
                if (onDownload != null)
                  isDownloading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : GestureDetector(
                    onTap: onDownload,
                    child: const Icon(
                      Icons.file_download_outlined,
                      size: 26,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
