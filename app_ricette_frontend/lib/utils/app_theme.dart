// lib/utils/app_theme.dart - VERSIONE SOFT
import 'package:flutter/material.dart';

class AppColors {
  // Viola SOFT - più tenue e moderno
  static const Color primary = Color(0xFF7E69AB); // Viola pastello Material 3

  // Testo SU viola (sempre bianco per contrasto)
  static const Color onPrimary = Colors.white;

  // Viola chiarissimo per sfondi secondari
  static const Color secondary = Color(0xFFEFE9F7);

  // Testo SU viola chiaro
  static const Color onSecondary = Color(0xFF362E4E);

  // Sfondi bianchi
  static const Color surface = Colors.white;
  static const Color background =
      Color(0xFFF8F6FC); // Bianco con leggerissima sfumatura viola

  // Testo principale
  static const Color onSurface = Color(0xFF1D192B);
  static const Color onBackground = Color(0xFF1D192B);

  // Errori
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        // SOSTITUISCI background e onBackground con surface e onSurface
        surface: AppColors.background, // Usa background come surface
        onSurface: AppColors.onBackground, // Usa onBackground come onSurface
        error: AppColors.error,
        onError: AppColors.onError,
        brightness: Brightness.light,
      ),

      // AppBar più elegante
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary, // ← OBBLIGATORIO: bianco!
        ),
      ),

      // Bottoni elevati con viola soft
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0, // Più flat e moderno
        ),
      ),

      // Bottoni di testo viola soft
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: CircleBorder(),
        elevation: 1,
      ),

      // Mantieni Material 3
      useMaterial3: true,
    );
  }
}
