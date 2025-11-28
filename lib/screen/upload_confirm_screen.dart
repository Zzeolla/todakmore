// lib/screen/upload_confirm_screen.dart (예시 경로)
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/provider/album_provider.dart';
import 'package:todakmore/service/album_upload_service.dart';

class UploadConfirmScreen extends StatefulWidget {
  final List<AssetEntity> assets;

  const UploadConfirmScreen({
    super.key,
    required this.assets,
  });

  @override
  State<UploadConfirmScreen> createState() => _UploadConfirmScreenState();
}

class _UploadConfirmScreenState extends State<UploadConfirmScreen> {
  int _currentIndex = 0;
  bool _isUploading = false;
  double _progress = 0.0;
  int _uploadedCount = 0;

  @override
  Widget build(BuildContext context) {
    // 토닥모아 색상
    const todakBackground = Color(0xFFFFF9F4); // Cream White
    const todakLavender = Color(0xFFC6B6FF);
    const todakPeach = Color(0xFFFFDDD2);
    const todakText = Color(0xFF444444);

    final total = widget.assets.length;

    return Scaffold(
      backgroundColor: todakBackground,
      appBar: AppBar(
        backgroundColor: todakBackground,
        elevation: 0,
        title: const Text('업로드 확인'),
        foregroundColor: todakText,
      ),
      body: Column(
        children: [
          // 상단 큰 미리보기
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildPreview(
                  asset: widget.assets[_currentIndex],
                  emptyBackground: todakPeach.withOpacity(0.5),
                  textColor: todakText,
                ),
              ),
            ),
          ),

          // 인디케이터
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${_currentIndex + 1} / $total',
                  style: const TextStyle(fontSize: 13, color: todakText),
                ),
                const Spacer(),
                Text(
                  '총 $total장 업로드 예정',
                  style: const TextStyle(fontSize: 13, color: todakText),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 썸네일 리스트
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: total,
              itemBuilder: (context, index) {
                final asset = widget.assets[index];
                final isCurrent = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = index);
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? todakLavender : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildThumb(asset),
                    ),
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          // 업로드 진행 상태
          if (_isUploading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(
                    '업로드 중... $_uploadedCount / $total',
                    style: const TextStyle(fontSize: 13, color: todakText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 하단 버튼
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isUploading ? null : () => _startUpload(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor:
                    _isUploading ? Colors.grey.shade300 : const Color(0xFF4CAF81),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isUploading ? '업로드 중...' : '업로드 하기',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── 미리보기 ─────────
  Widget _buildPreview({
    required AssetEntity asset,
    required Color emptyBackground,
    required Color textColor,
  }) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(800, 800)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: emptyBackground,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }

  // ───────── 썸네일 ─────────
  Widget _buildThumb(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Colors.grey[200]);
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }

  // ───────── 업로드 시작 ─────────
  Future<void> _startUpload(BuildContext context) async {
    if (widget.assets.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final albumProvider = context.read<AlbumProvider>();

    final userId = userProvider.userId;          // 너가 쓰는 필드명에 맞게 수정
    final albumId = albumProvider.selectedAlbumId; // 예시: 현재 선택된 앨범 id

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인해 주세요.')),
      );
      return;
    }

    if (albumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업로드할 앨범을 먼저 선택해 주세요.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0.0;
      _uploadedCount = 0;
    });

    final total = widget.assets.length;

    try {
      for (int i = 0; i < total; i++) {
        final asset = widget.assets[i];

        await AlbumUploadService.uploadSingleAsset(
          asset: asset,
          albumId: albumId,
          uploadedBy: userId,
        );

        _uploadedCount = i + 1;
        _progress = _uploadedCount / total;

        if (mounted) {
          setState(() {});
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업로드가 완료되었어요.')),
      );

      Navigator.pop(context); // TODO: 필요하면 더 상위까지 pop
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 중 오류가 발생했어요: $e')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }
}
