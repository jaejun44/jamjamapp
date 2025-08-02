import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class ForgotPasswordModal extends StatefulWidget {
  const ForgotPasswordModal({super.key});

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: 실제 아이디/비밀번호 찾기 로직 구현
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tabController.index == 0 
                ? '아이디가 이메일로 전송되었습니다!' 
                : '비밀번호 재설정 링크가 이메일로 전송되었습니다!'
          ),
          backgroundColor: AppTheme.accentPink,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '계정 찾기',
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

            // 탭 바
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.accentPink,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: AppTheme.white,
                unselectedLabelColor: AppTheme.grey,
                tabs: const [
                  Tab(text: '아이디 찾기'),
                  Tab(text: '비밀번호 찾기'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 탭 뷰
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 아이디 찾기 탭
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          '가입 시 등록한 이메일을 입력하세요',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        TextFormField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: '닉네임',
                            prefixIcon: Icon(Icons.person, color: AppTheme.grey),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '닉네임을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // 비밀번호 찾기 탭
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          '가입 시 등록한 이메일을 입력하세요',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        TextFormField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: '아이디',
                            prefixIcon: Icon(Icons.account_circle, color: AppTheme.grey),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '아이디를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 제출 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                        ),
                      )
                    : Text(
                        _tabController.index == 0 ? '아이디 찾기' : '비밀번호 찾기',
                        style: const TextStyle(
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
                  '계정을 기억하셨나요? ',
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
    );
  }
} 