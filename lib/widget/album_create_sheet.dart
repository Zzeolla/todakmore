import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// 앨범 생성 시 입력받을 값
class AlbumCreateFormData {
  final String name;
  final String label;
  final File? coverImage;

  AlbumCreateFormData({
    required this.name,
    required this.label,
    this.coverImage,
  });
}

/// 실제로 showModalBottomSheet 에서 사용하는 컨텐츠 위젯
class AlbumCreateSheetContent extends StatefulWidget {
  const AlbumCreateSheetContent({super.key});

  @override
  State<AlbumCreateSheetContent> createState() => _AlbumCreateSheetContentState();
}

class _AlbumCreateSheetContentState extends State<AlbumCreateSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _labelController = TextEditingController();

  File? _coverImage;
  bool _hasTempCover = false;

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    // 취소 → 그냥 바텀시트 닫기 (null 반환)
    Navigator.of(context).pop(null);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final data = AlbumCreateFormData(
      name: _nameController.text.trim(),
      label: _labelController.text.trim(),
      coverImage: _coverImage,
    );

    // 확인 → 입력값을 상위로 넘김
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const todakBackground = Color(0xFFF1F1FD); // 너가 자주 쓰는 연보라 톤
    const confirmColor = Color(0xFF4CAF81);    // 이미 쓰고 있는 진한 초록

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: todakBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // 제목 + 이모지
              Row(
                children: [
                  const Text(
                    '📸',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+ 새 앨범 만들기',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '우리 가족만 보는 작은 공간을 만들어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ 대표 사진 (선택)
              Text(
                '대표 사진 (선택)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _showCoverBottomSheet,
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _hasTempCover && _coverImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _coverImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.photo_camera_outlined, size: 28),
                          SizedBox(height: 4),
                          Text(
                            '사진 선택',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _hasTempCover
                            ? '선택된 사진이 앨범 대표 이미지로 사용돼요.'
                            : '아기 사진이나 가족 사진을 대표 이미지로 설정해 보세요 😊',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 앨범 이름
              Text(
                '앨범 이름',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _RoundedTextField(
                controller: _nameController,
                hintText: '예) 이준이 일상, 김씨 가족 이야기',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '앨범 이름을 입력해 주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 라벨 이름
              Text(
                '라벨 이름',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _RoundedTextField(
                controller: _labelController,
                hintText: '예) 아빠/엄마, 할머니/할아버지, 삼촌, 가족, 지인 등',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '라벨 이름을 입력해 주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 하단 버튼: 취소 / 앨범 만들기
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _handleSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        backgroundColor: confirmColor,
                      ),
                      child: const Text('앨범 만들기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // 대표 사진 선택용 BottomSheet
  // ─────────────────────────────
  void _showCoverBottomSheet() {
    final hasCover = _hasTempCover && _coverImage != null;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickCover(ImageSource.camera);
                  },
                  child: const Text(
                    '사진 촬영',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickCover(ImageSource.gallery);
                  },
                  child: const Text(
                    '앨범에서 사진 선택',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
                if (hasCover)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _coverImage = null;
                        _hasTempCover = false;
                      });
                    },
                    child: const Text(
                      '대표 사진 제거',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCover(ImageSource source) async {
    final picked = await _safePick(source);
    if (picked == null) return;

    setState(() {
      _coverImage = File(picked.path);
      _hasTempCover = true;
    });
  }

  // 원모아에서 쓰던 safePick 재활용
  Future<XFile?> _safePick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source);
      return file;
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      String msg = '사진을 불러오지 못했습니다.';

      if (code.contains('camera')) {
        msg = '카메라를 사용할 수 없습니다. 권한을 확인해주세요.';
      } else if (code.contains('photo') || code.contains('gallery')) {
        msg = '사진 보관함에 접근할 수 없습니다. 설정에서 사진 권한을 허용해 주세요.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알 수 없는 오류가 발생했습니다. 다시 시도해 주세요.'),
          ),
        );
      }
      return null;
    }
  }
}

class _RoundedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;

  const _RoundedTextField({
    required this.controller,
    required this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
