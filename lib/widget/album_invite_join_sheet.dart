import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todakmore/provider/user_provider.dart';
import 'package:todakmore/service/invite_code_service.dart';

class AlbumInviteJoinSheet extends StatefulWidget {
  const AlbumInviteJoinSheet({super.key});

  @override
  State<AlbumInviteJoinSheet> createState() => _AlbumInviteJoinSheetState();
}

class _AlbumInviteJoinSheetState extends State<AlbumInviteJoinSheet> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  bool _isChecking = false; // 코드 체크 중
  bool _isValid = false;    // 코드 유효 여부
  String? _errorText;       // 코드 관련 에러 메시지

  @override
  void dispose() {
    _codeController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    final code = value.trim();

    if (code.isEmpty) {
      setState(() {
        _isValid = false;
        _errorText = null;
      });
      return;
    }

    // 입력 바뀔 때 마다 초기화
    setState(() {
      _isValid = false;
      _errorText = null;
    });

    // 6자리 다 입력됐을 때만 체크
    if (code.length == 6) {
      _checkCode(code);
    }
  }

  void _onLabelChanged(String value) {
    // 라벨은 단순히 UI 업데이트만 필요 (버튼 활성 조건에 영향)
    setState(() {});
  }

  Future<void> _checkCode(String code) async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    try {
      final result = await InviteCodeService.verifyInviteCode(code);

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _isValid = true;
          _errorText = null;
        });
      } else {
        setState(() {
          _isValid = false;
          _errorText = '유효하지 않은 코드입니다. 앨범 관리자에게 문의하세요.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValid = false;
        _errorText = '코드를 확인하는 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _joinAlbum() async {
    final code = _codeController.text.trim();
    final label = _labelController.text.trim();

    if (!_isValid || code.isEmpty || label.isEmpty) {
      // 이론상 버튼이 안보여서 못 누르긴 하는데, 방어 코드
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코드와 라벨을 모두 입력해 주세요.')),
      );
      return;
    }

    try {
      final joinedAlbumId = await InviteCodeService.joinAlbumByInviteCode(code, label);

      if (!mounted) return;

      final userProvider = context.read<UserProvider>();
      await userProvider.updateLastAlbumId(joinedAlbumId);

      // SplashScreen(초기 라우트)로 이동해서 상태 초기화
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앨범을 추가하는 중 오류가 발생했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  bool get _canJoin {
    return _isValid && _labelController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 바
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Text(
                '초대 코드로 앨범 추가하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                '가족이나 지인이 보내준 초대 코드를 입력하면\n해당 앨범이 내 목록에 추가돼요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // 코드 + 라벨 입력 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FDF6), // 토닥 라이트 라벤더
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 초대 코드 입력 ---
                    const Text(
                      '초대 코드',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      maxLength: 6,
                      onChanged: _onCodeChanged,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '6자리 숫자를 입력해 주세요',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: Color(0xFF4CAF81), // 민트 계열 진한 색
                            width: 1.2,
                          ),
                        ),
                        suffixIcon: _isChecking
                            ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : (_isValid
                            ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF81),
                        )
                            : null),
                      ),
                      onSubmitted: (_) {
                        // 6자리 + 유효이면 바로 라벨로 포커스 옮기거나, join은 라벨 이후에만
                        FocusScope.of(context).nextFocus();
                      },
                    ),
                    const SizedBox(height: 4),
                    if (_errorText != null)
                      Text(
                        _errorText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      )
                    else
                      Text(
                        '코드는 발급 후 20분 동안만 사용할 수 있어요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // --- 라벨 입력 ---
                    const Text(
                      '라벨',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _labelController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      maxLength: 20,
                      onChanged: _onLabelChanged,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '할아버지/할버지, 이모/삼촌, 가족, 지인 등',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: Color(0xFF4CAF81),
                            width: 1.2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (_canJoin) {
                          _joinAlbum();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 버튼 영역
              Row(
                children: [
                  // 항상 보이는 취소 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 유효한 코드 + 비어있지 않은 라벨 조건에서만 보이는 추가하기 버튼
                  if (_canJoin)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _joinAlbum,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF4CAF81),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('추가하기'),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
