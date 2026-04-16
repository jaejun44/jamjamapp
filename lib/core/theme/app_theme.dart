import 'package:flutter/material.dart';

/// PPG(The Powerpuff Girls) 스타일 라이트 테마
/// ⚠️ 하위호환성: 색상 이름은 기존 유지, 실제값은 라이트 팔레트로 교체
class AppTheme {
  // ── PPG 코어 팔레트 ──────────────────────────────────────────────────────────
  static const Color hotPink   = Color(0xFFFF5CA8); // 메인 핫핑크 (버블검)
  static const Color skyBlue   = Color(0xFF5CE1E6); // 스카이블루 (버블)
  static const Color outlineBlack = Color(0xFF000000); // 두꺼운 아웃라인

  // ── 하위호환성 앨리어스 (기존 코드 참조 유지) ─────────────────────────────────
  /// 크림색 배경 (구 primaryBlack = 다크배경)
  static const Color primaryBlack   = Color(0xFFFFFEF5);
  /// 카드 흰색 (구 secondaryBlack = 다크카드)
  static const Color secondaryBlack = Color(0xFFFFFFFF);
  /// 핫핑크 (구 accentPink)
  static const Color accentPink     = hotPink;
  static const Color lightPink      = Color(0xFFFFB3D4);
  static const Color darkPink       = Color(0xFFE0478B);
  /// 다크 텍스트 (구 white = 흰텍스트 → 이제 검정텍스트)
  static const Color white          = Color(0xFF1A1A1A);
  static const Color grey           = Color(0xFF888888);
  static const Color lightGrey      = Color(0xFFE8E8E8);

  // ── 테마 정의 ─────────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: hotPink,
    scaffoldBackgroundColor: primaryBlack,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: outlineBlack,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: outlineBlack,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    // BottomNavigationBar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: hotPink,
      unselectedItemColor: grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800),
    ),

    // ElevatedButton — 둥근 + 아웃라인
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: hotPink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: outlineBlack, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: hotPink),
    ),

    // InputDecoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: outlineBlack, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: hotPink, width: 2.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightGrey, width: 1.5),
      ),
      hintStyle: const TextStyle(color: grey),
    ),

    // Card — 흰 배경 + 두꺼운 아웃라인
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: outlineBlack, width: 2),
      ),
      elevation: 0,
    ),

    // TextTheme — 모두 다크 텍스트
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: outlineBlack, fontSize: 32, fontWeight: FontWeight.w900),
      displayMedium: TextStyle(color: outlineBlack, fontSize: 28, fontWeight: FontWeight.w900),
      displaySmall:  TextStyle(color: outlineBlack, fontSize: 24, fontWeight: FontWeight.w900),
      headlineLarge: TextStyle(color: outlineBlack, fontSize: 22, fontWeight: FontWeight.w800),
      headlineMedium:TextStyle(color: outlineBlack, fontSize: 20, fontWeight: FontWeight.w800),
      headlineSmall: TextStyle(color: outlineBlack, fontSize: 18, fontWeight: FontWeight.w700),
      titleLarge:    TextStyle(color: outlineBlack, fontSize: 16, fontWeight: FontWeight.w700),
      titleMedium:   TextStyle(color: outlineBlack, fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall:    TextStyle(color: outlineBlack, fontSize: 12, fontWeight: FontWeight.w600),
      bodyLarge:     TextStyle(color: outlineBlack, fontSize: 16),
      bodyMedium:    TextStyle(color: outlineBlack, fontSize: 14),
      bodySmall:     TextStyle(color: grey,         fontSize: 12),
    ),
  );
}
