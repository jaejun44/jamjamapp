import 'package:flutter/material.dart';

class AppTheme {
  // 색상 팔레트
  static const Color primaryBlack = Color(0xFF000000);
  static const Color secondaryBlack = Color(0xFF1A1A1A);
  static const Color accentPink = Color(0xFFFF69B4);
  static const Color lightPink = Color(0xFFFFB6C1);
  static const Color darkPink = Color(0xFFFF1493);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFCCCCCC);

  // 다크 테마
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryBlack,
    scaffoldBackgroundColor: primaryBlack,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlack,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: secondaryBlack,
      selectedItemColor: accentPink,
      unselectedItemColor: grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPink,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentPink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondaryBlack,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentPink, width: 2),
      ),
      hintStyle: const TextStyle(color: grey),
    ),
    cardTheme: CardThemeData(
      color: secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: white, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: white, fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: white, fontSize: 22, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: white, fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: white, fontSize: 16),
      bodyMedium: TextStyle(color: white, fontSize: 14),
      bodySmall: TextStyle(color: grey, fontSize: 12),
    ),
  );
} 