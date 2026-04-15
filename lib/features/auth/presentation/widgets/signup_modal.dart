import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';

class SignupModal extends StatefulWidget {
  final Function(bool) onSignupSuccess;

  const SignupModal({
    super.key,
    required this.onSignupSuccess,
  });

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


    try {

      // Supabase 회원가입 + profiles 행 생성 (단일 호출)
      final response = await SupabaseService.instance.signUpWithProfile(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
      );

      if (response.user != null) {
        // 이메일 인증 필요 여부 확인 (세션 유무로 판단)
        final hasSession = response.session != null;

        if (hasSession) {
          await AuthStateManager.instance.updateLoginState(
            userId: response.user!.id,
            email: response.user!.email ?? '',
            nickname: _nicknameController.text.trim(),
          );

          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('회원가입이 완료되었습니다! 자동으로 로그인되었습니다.'),
                backgroundColor: AppTheme.accentPink,
              ),
            );
          }
        } else {
          // 이메일 인증 필요한 경우
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이메일로 인증 링크가 발송되었습니다. 확인 후 로그인해주세요.'),
                backgroundColor: AppTheme.accentPink,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }

      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Text(
                      '회원가입',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 60), // 균형을 위한 빈 공간
                  ],
                ),
                const SizedBox(height: 30),

                // 닉네임 입력
                TextFormField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentPink),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    if (value.length < 2) {
                      return '닉네임은 2자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 이메일 입력
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '이메일',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentPink),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 비밀번호 입력
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentPink),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
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
                const SizedBox(height: 20),

                // 비밀번호 확인 입력
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentPink),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호 확인을 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '회원가입',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 