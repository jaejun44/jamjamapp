import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class SignupModal extends StatefulWidget {
  const SignupModal({super.key});

  @override
  State<SignupModal> createState() => _SignupModalState();
}

class _SignupModalState extends State<SignupModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // 닉네임 중복검사 관련 변수
  bool _isCheckingNickname = false;
  bool _isNicknameAvailable = false;
  bool _hasCheckedNickname = false;
  
  // 임시 사용 중인 닉네임 목록 (실제로는 서버에서 확인)
  final List<String> _existingNicknames = [
    'jammaster',
    'musiclover',
    'guitarhero',
    'pianist',
    'drummer',
    'vocalist',
    'producer',
    'composer',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: 실제 회원가입 로직 구현
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입이 완료되었습니다!'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
    }
  }

  // 닉네임 중복검사 함수
  void _checkNicknameAvailability() async {
    final nickname = _nicknameController.text.trim();
    
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (nickname.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임은 2자 이상이어야 합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingNickname = true;
    });

    // 서버 요청 시뮬레이션
    await Future.delayed(const Duration(seconds: 1));

    final isAvailable = !_existingNicknames.contains(nickname.toLowerCase());

    setState(() {
      _isCheckingNickname = false;
      _isNicknameAvailable = isAvailable;
      _hasCheckedNickname = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable 
                ? '사용 가능한 닉네임입니다!' 
                : '이미 사용 중인 닉네임입니다'
          ),
          backgroundColor: isAvailable ? AppTheme.accentPink : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 이메일 필드
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email, color: AppTheme.grey),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '올바른 이메일 형식을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 비밀번호 필드
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.grey),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.grey,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 비밀번호 확인 필드
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.grey),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.grey,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 다시 입력해주세요';
                  }
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 닉네임 필드
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      prefixIcon: const Icon(Icons.person, color: AppTheme.grey),
                      suffixIcon: _isCheckingNickname
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
                                ),
                              ),
                            )
                          : _hasCheckedNickname
                              ? Icon(
                                  _isNicknameAvailable 
                                      ? Icons.check_circle 
                                      : Icons.error,
                                  color: _isNicknameAvailable 
                                      ? Colors.green 
                                      : Colors.red,
                                  size: 20,
                                )
                              : IconButton(
                                  onPressed: _checkNicknameAvailability,
                                  icon: const Icon(
                                    Icons.search,
                                    color: AppTheme.accentPink,
                                    size: 20,
                                  ),
                                  tooltip: '중복확인',
                                ),
                    ),
                    onChanged: (value) {
                      // 닉네임이 변경되면 중복검사 상태 초기화
                      if (_hasCheckedNickname) {
                        setState(() {
                          _hasCheckedNickname = false;
                          _isNicknameAvailable = false;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '닉네임을 입력해주세요';
                      }
                      if (value.length < 2) {
                        return '닉네임은 2자 이상이어야 합니다';
                      }
                      if (!_hasCheckedNickname) {
                        return '닉네임 중복확인을 해주세요';
                      }
                      if (!_isNicknameAvailable) {
                        return '이미 사용 중인 닉네임입니다';
                      }
                      return null;
                    },
                  ),
                  if (_hasCheckedNickname)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        _isNicknameAvailable 
                            ? '사용 가능한 닉네임입니다' 
                            : '이미 사용 중인 닉네임입니다',
                        style: TextStyle(
                          color: _isNicknameAvailable ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                          ),
                        )
                      : const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 로그인 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '이미 계정이 있으신가요? ',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: 로그인 모달 열기
                    },
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        color: AppTheme.accentPink,
                        fontWeight: FontWeight.bold,
                      ),
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
} 