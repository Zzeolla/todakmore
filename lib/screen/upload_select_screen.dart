import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class UploadSelectScreen extends StatefulWidget {
  const UploadSelectScreen({super.key});

  @override
  State<UploadSelectScreen> createState() => _UploadSelectScreenState();
}

class _UploadSelectScreenState extends State<UploadSelectScreen> {
  final ImagePicker _picker = ImagePicker();

  List<AssetEntity> _assets = [];
  // 여러 장 선택용
  final Set<AssetEntity> _selectedAssets = {};
  AssetEntity? _previewAsset;
  bool _isLoading = true;

  AssetPathEntity? _recentPath;
  int _currentPage = 0;
  final int _pageSize = 100;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  static const int _maxSelection = 5;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAssets();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────── 갤러리 로딩 ─────────────────
  Future<void> _loadAssets() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      debugPrint('Photo permission state: $ps  isAuth=${ps.isAuth}');

      if (ps == PermissionState.denied || ps == PermissionState.restricted) {
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('사진 접근 권한이 필요해요'),
            content: const Text(
              '아기 사진을 불러오기 위해 사진 및 동영상 접근 권한을 허용해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  PhotoManager.openSetting();
                },
                child: const Text('설정 열기'),
              ),
            ],
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 여기부터는 권한 OK (authorized / limited)
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image, // 🔒 이미지 전용 (동영상 제외)
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            )
          ]
        )
      );

      debugPrint('paths length = ${paths.length}');

      if (paths.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      _recentPath = paths.first;
      _currentPage = 0;
      _hasMore = true;
      _assets.clear();
      _selectedAssets.clear();
      _previewAsset = null;

      // 첫 페이지 로드
      await _loadMoreAssets(initial: true);

      final recent = paths.first;
      final assets = await recent.getAssetListPaged(page: 0, size: 100);
      debugPrint('assets length = ${assets.length}');

      if (!mounted) return;
      setState(() {
        _assets = assets;
        _previewAsset = assets.isNotEmpty ? assets.first : null;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('loadAssets error: $e\n$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ───────────────── 카메라 촬영 ─────────────────
  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    final file = File(picked.path);
    debugPrint('Camera captured file: ${file.path}');

    // TODO: MVP에서는 카메라 촬영 → 바로 다음 단계(확인 화면)로 넘기는 방식 고민
  }

  // ───────────────── 선택된 파일 리스트 얻기 ────────────────
  Future<List<File>> _getSelectedFiles() async {
    final List<File> files = [];
    for (final asset in _selectedAssets) {
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }
    return files;
  }

  // ───────────────── "다음" 버튼 ─────────────────
  Future<void> _onNext() async {
    if (_selectedAssets.isEmpty) return;

    Navigator.pushNamed(
      context,
      '/upload-confirm',
      arguments: _selectedAssets.toList(),
    );
  }

  // ───────────────── 선택 토글 ─────────────────
  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        if (_selectedAssets.length >= _maxSelection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사진은 최대 $_maxSelection장까지 선택할 수 있어요.'),
            ),
          );
          return;
        }
        _selectedAssets.add(asset);
      }
      _previewAsset = asset;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;

    final position = _scrollController.position;
    // 맨 아래에서 300px 남았을 때 다음 페이지 로드
    if (position.pixels > position.maxScrollExtent - 300) {
      _loadMoreAssets();
    }
  }

  Future<void> _loadMoreAssets({bool initial = false}) async {
    if (_recentPath == null) return;
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      if (!initial) {
        _isLoadingMore = true;
      }
    });

    try {
      final more = await _recentPath!.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );

      debugPrint('load page $_currentPage, got ${more.length} assets');

      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _assets.addAll(more);
        _currentPage++;

        // 미리보기 기본값
        if (_previewAsset == null && _assets.isNotEmpty) {
          _previewAsset = _assets.first;
        }
      }
    } catch (e, st) {
      debugPrint('loadMoreAssets error: $e\n$st');
      _hasMore = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final canNext = _selectedAssets.isNotEmpty && !_isLoading;
    final selectedCount = _selectedAssets.length;

    // 토닥모아 색상
    const todakBackground = Color(0xFFFFF9F4); // Cream White
    const todakLavender = Color(0xFFC6B6FF);
    const todakPeach = Color(0xFFFFDDD2);
    const todakMint = Color(0xFFCFF8DD);
    const todakText = Color(0xFF444444);

    return Scaffold(
      backgroundColor: todakBackground,
      appBar: AppBar(
        backgroundColor: todakBackground,
        foregroundColor: todakText,
        elevation: 0,
        title: const Text('사진 고르기'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: canNext ? _onNext : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                backgroundColor: canNext ? Color(0xFF4CAF81) : Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // 앨범 선택 (TODO)
                GestureDetector(
                  onTap: () {
                    // TODO: 업로드 시 앨범 선택하는 기능으로 요건 추후 upload_confirm 스크린으로 이동 필요
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.photo_album_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '현재 앨범 (TODO)',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.expand_more, size: 18),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 선택 개수 표시
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: todakLavender.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '선택함 $selectedCount / $_maxSelection',
                    style: const TextStyle(
                      fontSize: 12,
                      color: todakText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 상단 큰 미리보기 (정사각형)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildPreview(
                  emptyBackground: todakPeach.withOpacity(0.5),
                  textColor: todakText,
                ),
              ),
            ),
          ),
          // 하단 그리드 영역
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: _buildGrid(
                lavender: todakLavender,
                mint: todakMint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── 상단 미리보기 영역 ─────────────────
  Widget _buildPreview({
    required Color emptyBackground,
    required Color textColor,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final targetAsset = _previewAsset ??
        (_selectedAssets.isNotEmpty ? _selectedAssets.first : null);

    if (targetAsset == null) {
      return Container(
        color: emptyBackground,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📷',
                style: TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 8),
              Text(
                '사진을 선택해 주세요',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildAssetPreview(targetAsset);
  }

  // ───────────────── 하단 그리드 영역 ─────────────────
  Widget _buildGrid({
    required Color lavender,
    required Color mint,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 인스타처럼 4열
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _assets.length + 1 + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          // 맨 첫 칸: 카메라 아이콘
          return GestureDetector(
            onTap: _pickFromCamera,
            child: Container(
              color: lavender.withOpacity(0.08),
              child: const Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.black54,
                  size: 26,
                ),
              ),
            ),
          );
        }

        // 마지막 인덱스이면서 hasMore=true → 로딩 인디케이터
        if (index == _assets.length + 1 && _hasMore) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final asset = _assets[index - 1];
        final isSelected = _selectedAssets.contains(asset);

        return GestureDetector(
          onTap: () => _toggleSelection(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildAssetThumb(asset),
              // 선택 오버레이
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: isSelected ? 0.25 : 0.0,
                child: Container(
                  color: Colors.black,
                ),
              ),
              // 우상단 체크 뱃지
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? mint : Colors.white70,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.black26,
                      width: 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black87)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── 상단 큰 미리보기용 ─────────────────
  Widget _buildAssetPreview(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize(800, 800),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
        );
      },
    );
  }

  // ───────────────── 그리드용 썸네일 ─────────────────
  Widget _buildAssetThumb(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize(300, 300),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: Colors.grey[200],
          );
        }

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
