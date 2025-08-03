import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'package:jamjamapp/core/services/supabase_service.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/home/presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.instance.initialize();
  
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
