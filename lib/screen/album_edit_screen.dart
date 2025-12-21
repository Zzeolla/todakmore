import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/model/album_with_my_info_model.dart';
import 'package:todakmore/provider/album_provider.dart';

class AlbumEditScreen extends StatefulWidget {
  final AlbumWithMyInfoModel album;

  const AlbumEditScreen({super.key, required this.album});

  @override
  State<AlbumEditScreen> createState() => _AlbumEditScreenState();
}

class _AlbumEditScreenState extends State<AlbumEditScreen> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  Uint8List? _pickedCoverBytes; // 새로 고른 커버
  late String _initialName;
  late String? _initialCoverUrl;

  @override
  void initState() {
    super.initState();
    _initialName = widget.album.name;
    _initialCoverUrl = widget.album.coverUrl;
    _nameCtrl.text = _initialName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    final nameChanged = _nameCtrl.text.trim() != _initialName;
    final coverChanged = _pickedCoverBytes != null;
    return nameChanged || coverChanged;
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final XFile? x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1400,
    );

    if (x == null) return;

    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() => _pickedCoverBytes = bytes);
  }

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();
    final nameChanged = newName.isNotEmpty && newName != _initialName;
    final coverChanged = _pickedCoverBytes != null;

    if (!_canSave) return;

    setState(() => _saving = true);

    try {
      final albumProvider = context.read<AlbumProvider>();

      // 1) 이름 변경
      if (nameChanged) {
        await albumProvider.updateAlbumName(
          albumId: widget.album.id,
          newName: newName,
        );
        _initialName = newName;
      }

      // 2) 커버 변경
      if (coverChanged) {
        await albumProvider.updateAlbumCover(
          albumId: widget.album.id,
          coverBytes: _pickedCoverBytes,
        );
        _pickedCoverBytes = null;
      }

      if (!mounted) return;
      Navigator.pop(context, true); // 변경됨 표시
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앨범 수정 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFF9F4); // Todak Cream White
    const card = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('앨범 수정'),
        actions: [
          TextButton(
            onPressed: (_saving || !_canSave) ? null : _save,
            child: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              '저장',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // 커버
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3E0FF), width: 1.2),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _saving ? null : _pickCover,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildCoverPreview(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '앨범 커버',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '탭해서 사진을 선택해 주세요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _pickCover,
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('커버 변경'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFFE0D9FF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 이름
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3E0FF), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '앨범 이름',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    enabled: !_saving,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: '예: 이겸이 성장 앨범',
                      filled: true,
                      fillColor: const Color(0xFFF1F1FD),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 저장 버튼(하단)
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_saving || !_canSave) ? null : _save,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFC6B6FF), // Todak Lavender
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  '저장하기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPreview() {
    final size = 72.0;

    if (_pickedCoverBytes != null) {
      return Image.memory(
        _pickedCoverBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    // 기존 URL 없으면 기본
    final url = _initialCoverUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFFF1F1FD),
        alignment: Alignment.center,
        child: const Text('👶', style: TextStyle(fontSize: 28)),
      );
    }

    // CachedNetworkImage 쓰고 싶으면 여기서 교체하면 됨 (현재는 기본 Image.network)
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
