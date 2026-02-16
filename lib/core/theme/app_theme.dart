import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Muon App 主題設定（Spotify 風格暗色系）
class AppTheme {
  AppTheme._();

  // 顏色常數
  static const Color _primaryGreen = Color(0xFF1DB954);
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF282828);
  static const Color _darkElevated = Color(0xFF333333);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFB3B3B3);
  static const Color _textTertiary = Color(0xFF727272);

  /// 深色主題
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryGreen,
        onPrimary: Colors.black,
        secondary: _primaryGreen,
        surface: _darkSurface,
        onSurface: _textPrimary,
        error: Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: textTheme.copyWith(
        // 大標題
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.bold,
        ),
        // 副標題
        titleMedium: textTheme.titleMedium?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
        // 內文
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: _textSecondary,
        ),
        // 小字
        bodySmall: textTheme.bodySmall?.copyWith(
          color: _textTertiary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _textSecondary,
        textColor: _textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: _textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        selectedItemColor: _textPrimary,
        unselectedItemColor: _textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _primaryGreen,
        inactiveTrackColor: _darkElevated,
        thumbColor: _textPrimary,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 4,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: _textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: _textTertiary,
        ),
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
