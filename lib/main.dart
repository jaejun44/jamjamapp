import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';
import 'package:jamjamapp/core/services/profile_image_manager.dart';
import 'package:jamjamapp/core/services/auth_state_manager.dart';
import 'package:jamjamapp/core/services/app_state_manager.dart';
import 'package:jamjamapp/core/services/counter_service.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/home/presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔄 서비스 초기화 순서 (기둥 → 가지)
  // dotenv는 SupabaseService.initialize() 내부에서 로드
  await SupabaseService.instance.initialize();
  
  await ProfileImageManager.instance.initialize();
  
  await AuthStateManager.instance.initializeAuthState();
  
  await CounterService.instance.initialize();
  
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
