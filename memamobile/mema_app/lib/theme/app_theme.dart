import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Styles de texte centralisés : pour changer la police ou les tailles
/// de toute l'application, on modifie uniquement ce fichier.
class AppText {
  static const h1 = TextStyle(
      fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.2);
  static const h2 = TextStyle(
      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, height: 1.3);
  static const title = TextStyle(
      fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.text);
  static const body = TextStyle(
      fontSize: 14, color: AppColors.textSoft, height: 1.5);
  static const caption = TextStyle(
      fontSize: 12.5, color: AppColors.textSoft, height: 1.4);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSoft, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}