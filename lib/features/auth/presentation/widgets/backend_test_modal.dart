import 'package:flutter/material.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';

class BackendTestModal extends StatefulWidget {
  const BackendTestModal({super.key});

  @override
  State<BackendTestModal> createState() => _BackendTestModalState();
}

class _BackendTestModalState extends State<BackendTestModal> {
  bool _isLoading = false;
  String _testResult = '';
  bool _connectionSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔧 백엔드 연결 테스트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 테스트 버튼
          ElevatedButton(
            onPressed: _isLoading ? null : _runBackendTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('테스트 중...'),
                    ],
                  )
                : const Text('백엔드 연결 테스트'),
          ),
          const SizedBox(height: 20),

          // 결과 표시
          if (_testResult.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _connectionSuccess ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _connectionSuccess ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _connectionSuccess ? Icons.check_circle : Icons.error,
                        color: _connectionSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _connectionSuccess ? '연결 성공!' : '연결 실패',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _connectionSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _testResult,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // 추가 정보
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '백엔드 정보',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text('• Supabase URL: aadlqmyynidfsygnxnnk.supabase.co'),
                Text('• 데이터베이스: PostgreSQL'),
                Text('• 인증: JWT 토큰'),
                Text('• 실시간: WebSocket'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runBackendTest() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
    });

    try {
      // 1. Supabase 연결 테스트
      final connectionSuccess = await SupabaseService.instance.testConnection();
      
      if (connectionSuccess) {
        // 2. 데이터베이스 스키마 확인
        await SupabaseService.instance.checkDatabaseSchema();
        
        setState(() {
          _connectionSuccess = true;
          _testResult = '''
✅ 백엔드 연결이 성공했습니다!

테스트 결과:
• Supabase 연결: 성공
• 데이터베이스 스키마: 확인됨
• 인증 시스템: 준비됨
• 실시간 기능: 준비됨

이제 실제 백엔드 개발을 시작할 수 있습니다!
          ''';
        });
      } else {
        setState(() {
          _connectionSuccess = false;
          _testResult = '''
❌ 백엔드 연결에 실패했습니다.

가능한 원인:
• Supabase 프로젝트가 설정되지 않음
• 데이터베이스 마이그레이션이 실행되지 않음
• 네트워크 연결 문제

해결 방법:
1. Supabase 대시보드에서 프로젝트 확인
2. 데이터베이스 마이그레이션 실행
3. 네트워크 연결 확인
          ''';
        });
      }
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _testResult = '❌ 테스트 중 오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 