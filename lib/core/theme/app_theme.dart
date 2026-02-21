import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Muon App 主題設定（Spotify 風格暗色系）
class AppTheme {
  AppTheme._();

  // 顏色常數 (YouTube 風格)
  static const Color _primaryRed = Color(0xFFFF0000); // YouTube 紅

  // 淺色模式常數
  static const Color _lightBackground = Color(0xFFF9F9F9);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFF1F1F1);
  static const Color _textPrimaryLight = Color(0xFF0F0F0F);
  static const Color _textSecondaryLight = Color(0xFF606060);
  static const Color _textTertiaryLight = Color(0xFF909090);

  // 深色模式常數
  static const Color _darkBackground = Color(0xFF0F0F0F);
  static const Color _darkSurface = Color(0xFF212121);
  static const Color _darkCard = Color(0xFF212121);
  static const Color _darkElevated = Color(0xFF3D3D3D);
  static const Color _textPrimaryDark = Color(0xFFFFFFFF);
  static const Color _textSecondaryDark = Color(0xFFAAAAAA);
  static const Color _textTertiaryDark = Color(0xFF717171);

  /// 淺色主題
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primaryRed,
        onPrimary: Colors.white,
        secondary: _primaryRed,
        surface: _lightSurface,
        onSurface: _textPrimaryLight,
        error: Color(0xFFCC0000),
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: _textPrimaryLight,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: _textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: _textSecondaryLight),
        bodySmall: textTheme.bodySmall?.copyWith(color: _textTertiaryLight),
      ),
      cardTheme: const CardThemeData(
        color: _lightCard,
        elevation: 1,
        shadowColor: Color(0x1F000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _textSecondaryLight,
        textColor: _textPrimaryLight,
      ),
      iconTheme: const IconThemeData(color: _textSecondaryLight),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _primaryRed,
        unselectedItemColor: _textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _primaryRed,
        inactiveTrackColor: _lightElevated,
        thumbColor: _primaryRed,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 4,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: _textPrimaryDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: _textTertiaryLight),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }

  /// 深色主題
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryRed,
        onPrimary: Colors.white,
        secondary: _primaryRed,
        surface: _darkSurface,
        onSurface: _textPrimaryDark,
        error: Color(0xFFFF4E4E),
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: textTheme.copyWith(
        // 大標題
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: _textPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
        // 副標題
        titleMedium: textTheme.titleMedium?.copyWith(
          color: _textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        // 內文
        bodyMedium: textTheme.bodyMedium?.copyWith(color: _textSecondaryDark),
        // 小字
        bodySmall: textTheme.bodySmall?.copyWith(color: _textTertiaryDark),
      ),
      cardTheme: const CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _textSecondaryDark,
        textColor: _textPrimaryDark,
      ),
      iconTheme: const IconThemeData(color: _textSecondaryDark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        selectedItemColor: _textPrimaryDark,
        unselectedItemColor: _textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _primaryRed,
        inactiveTrackColor: _darkElevated,
        thumbColor: _textPrimaryDark,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 4,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: _textPrimaryDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        hintStyle: textTheme.bodyMedium?.copyWith(color: _textTertiaryDark),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }
}
