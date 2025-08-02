import 'package:flutter/material.dart';
import 'package:jamjamapp/core/theme/app_theme.dart';
import 'features/home/presentation/screens/main_screen.dart';

void main() {
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
      home: const MainScreen(),
    );
  }
}
