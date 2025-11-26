import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/widget/common_app_bar.dart';

class AlbumStartScreen extends StatefulWidget {
  const AlbumStartScreen({super.key});

  @override
  State<AlbumStartScreen> createState() => _AlbumStartScreenState();
}

class _AlbumStartScreenState extends State<AlbumStartScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSavingName = false;
  String? _errorText;
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(UserProvider userProvider) async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = '이름을 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isSavingName = true;
      _errorText = null;
    });

    try {
      await userProvider.updateDisplayName(name);

      setState(() {
        _isEditingName = false;
      });
      _nameController.clear();
    } catch (e) {
      setState(() {
        _errorText = '저장 중 오류가 발생했습니다. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  void _showNeedNameSnack() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이름 입력 후 확인을 눌러주세요.')));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final displayName = userProvider.displayName;
    final hasName = displayName != null && displayName.trim().isNotEmpty;

    return Scaffold(
      appBar: CommonAppBar(),
      backgroundColor: const Color(0xFFFFF9F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 1) 이름 입력/표시 섹션
              if (!hasName || _isEditingName) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9FCEF), // Mint Breeze
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 제목 + 아이콘
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('👋', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Text(
                            '이름을 입력해 주세요',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '(가족 관계는 별도 입력 예정)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveName(userProvider),
                        decoration: InputDecoration(
                          hintText: '예: 홍길동',
                          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      // 에러 메시지 (있을 때만)
                      if (_errorText != null) ...[
                        const SizedBox(height: 6),
                        Text(_errorText!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (hasName)
                            SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed:
                                    _isSavingName
                                        ? null
                                        : () {
                                          // 수정 취소 → 다시 표시 모드
                                          setState(() {
                                            _isEditingName = false;
                                            _errorText = null;
                                            _nameController.clear();
                                          });
                                        },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF2F2F2),
                                  foregroundColor: const Color(0xFF4A4A4A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide.none,
                                ),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          const Spacer(),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isSavingName ? null : () => _saveName(userProvider),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFF4CAF81),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isSavingName
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                      : const Text(
                                        '확인',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // 이름이 이미 있는 경우, 간단히 표시
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF9A9A9A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$displayName 님',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditingName = true;
                          _errorText = null;
                          _nameController.text = displayName;
                        });
                      },
                      icon: const Icon(Icons.edit, size: 20),
                      color: const Color(0xFF9A9A9A),
                      tooltip: '이름 수정',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // 🔹 2) 초대 링크 / 새 앨범 버튼들
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '어떻게 시작할까요?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 초대 코드 입력 버튼
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            hasName
                                ? () {
                                  // TODO: 초대 코드 입력 화면/다이얼로그로 이동
                                }
                                : _showNeedNameSnack,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFF1F1FD), // 연보라 톤
                          foregroundColor: const Color(0xFF4A4A4A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔑', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text(
                              '초대 코드로 앨범 추가하기',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 새 앨범 만들기 버튼
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed:
                            hasName
                                ? () {
                                  // TODO: 새 앨범 생성 로직으로 이동
                                }
                                : _showNeedNameSnack,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A4A4A),
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFE0D9FF), // 아주 연한 라벤더 보더
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📸', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text(
                              '+ 새 앨범 만들기',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),
                    const Text(
                      '이름은 나중에 설정에서 다시 변경할 수 있어요.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9A9A9A)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
