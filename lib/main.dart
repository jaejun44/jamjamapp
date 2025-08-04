import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/app_state_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/home/presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드 (실패해도 계속 진행)
  try {
    await dotenv.load(fileName: ".env");
    print('✅ 환경 변수 로드 성공');
  } catch (e) {
    print('⚠️ 환경 변수 로드 실패, 하드코딩된 값 사용: $e');
    // 하드코딩된 기본값 설정
    dotenv.env['SUPABASE_URL'] = 'https://your-project.supabase.co';
    dotenv.env['SUPABASE_ANON_KEY'] = 'your-anon-key';
  }
  
  // Initialize Supabase
  await SupabaseService.instance.initialize();
  
  // Initialize Auth State Manager
  await AuthStateManager.instance.initializeAuthState();
  
  // Initialize App State Manager
  await AppStateManager.instance.initializeAppState();
  
  runApp(const JamJamApp());
}

class JamJamApp extends StatelessWidget {
  const JamJamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JamJam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
