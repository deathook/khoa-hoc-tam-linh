import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBg,
      scrollbarTheme: _buildScrollbarTheme(
        isDark: false,
        thumbColor: AppColors.primaryDark,
        thumbActiveColor: const Color(0xFF8B641B),
      ),
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
      ),
    );
  }

  static ThemeData get sepiaTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.sepiaBg,
      scrollbarTheme: _buildScrollbarTheme(
        isDark: false,
        thumbColor: AppColors.textSepia,
        thumbActiveColor: const Color(0xFF3E2D1E),
      ),
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondary,
        surface: AppColors.cardSepia,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.sepiaBg,
        foregroundColor: AppColors.textSepia,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textSepia,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSepia,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textSepia, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: AppColors.textSepia, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.textSepia, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: AppColors.textSepia, fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(color: Color(0xFF6B5E4F), fontSize: 14, height: 1.5),
      ),
    );
  }

  static ThemeData get darkTheme {
    const goldAccent = Color(0xFFE5B968);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: goldAccent,
      scaffoldBackgroundColor: AppColors.darkBg,
      scrollbarTheme: _buildScrollbarTheme(
        isDark: true,
        thumbColor: goldAccent,
        thumbActiveColor: const Color(0xFFF3C978),
      ),
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: Color(0xFF5CA37B),
        surface: AppColors.cardDark,
        onSurface: AppColors.textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardDarkBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: AppColors.textLight, fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(color: AppColors.textLightMuted, fontSize: 14, height: 1.5),
      ),
    );
  }

  static ScrollbarThemeData _buildScrollbarTheme({
    required bool isDark,
    required Color thumbColor,
    required Color thumbActiveColor,
  }) {
    return ScrollbarThemeData(
      interactive: true,
      thumbVisibility: const WidgetStatePropertyAll<bool>(true),
      trackVisibility: const WidgetStatePropertyAll<bool>(true),
      thickness: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged)) {
          return 14.0;
        }
        return 10.0;
      }),
      minThumbLength: 48.0,
      radius: const Radius.circular(8),
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.dragged)) {
          return thumbActiveColor;
        }
        if (states.contains(WidgetState.hovered)) {
          return thumbColor;
        }
        return thumbColor.withOpacity(0.65);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.hovered)) {
          return isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
        }
        return isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02);
      }),
      trackBorderColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    );
  }
}
