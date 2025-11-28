import 'package:flutter/material.dart';

class FeedCard extends StatelessWidget {
  final String albumName;
  final String date; // '2025.11.28'
  final String imageUrl;
  final String coverUrl;
  final bool didTodak;        // 사용자가 토닥했는지 여부
  final VoidCallback onTodak; // 토닥 클릭
  final VoidCallback onDownload;

  const FeedCard({
    super.key,
    required this.albumName,
    required this.date,
    required this.imageUrl,
    required this.coverUrl,
    required this.didTodak,
    required this.onTodak,
    required this.onDownload,
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
                    color: Colors.grey[300],
                  )
                      : Image.network(
                    coverUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
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
              ],
            ),
          ),

          // -------------------- Main Photo --------------------
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
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

                // 다운로드 버튼
                GestureDetector(
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
