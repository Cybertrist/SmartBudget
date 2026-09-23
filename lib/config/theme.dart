import 'package:flutter/material.dart';

/// Les couleurs de SmartBudget, prises dans le logo : un vert néon sur un
/// fond presque noir, teinté de vert.
///
/// Une seule couleur d'accent, le vert. Le rouge est réservé à ce qui
/// doit alerter, une dépense au dessus du budget ou un retrait sur
/// l'épargne : s'il servait aussi à décorer, il ne voudrait plus rien dire.
class AppColors {
  const AppColors._();

  static const fond = Color(0xFF040C08);
  static const surface = Color(0xFF0A1711);
  static const surfaceHaute = Color(0xFF0F2018);
  static const bord = Color(0xFF17301F);

  static const neon = Color(0xFF50F48D);
  static const vert = Color(0xFF1BCC6D);
  static const vertSombre = Color(0xFF0B3B22);

  static const alerte = Color(0xFFFF5C6C);
  static const attention = Color(0xFFFFC857);

  static const texte = Color(0xFFEAF5EE);
  static const texteSecondaire = Color(0xFF8FA89A);
  static const texteDiscret = Color(0xFF5B7266);

  static const degrade = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neon, vert],
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get sombre {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.fond,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neon,
        onPrimary: Color(0xFF02120A),
        secondary: AppColors.vert,
        surface: AppColors.surface,
        onSurface: AppColors.texte,
        error: AppColors.alerte,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.texte,
        displayColor: AppColors.texte,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fond,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.neon,
          foregroundColor: const Color(0xFF02120A),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHaute,
        contentTextStyle: TextStyle(color: AppColors.texte),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surfaceHaute),
    );
  }
}
