import 'package:flutter/material.dart';

/// Les couleurs de SmartBudget : des noirs neutres, des gris de lecteur de
/// musique, et un seul vert, gardé pour ce qui compte vraiment.
///
/// Le rouge dit « attention » : une dépense au dessus du budget, un
/// retrait sur l'épargne. S'il servait aussi à décorer, il ne voudrait
/// plus rien dire.
class AppColors {
  const AppColors._();

  static const fond = Color(0xFF121212);
  static const surface = Color(0xFF181818);
  static const surfaceHaute = Color(0xFF242424);
  static const surfaceBasse = Color(0xFF1E1E1E);
  static const trait = Color(0x12FFFFFF);

  static const vert = Color(0xFF1ED760);
  static const alerte = Color(0xFFFF6B7A);
  static const attention = Color(0xFFFFC857);
  static const interne = Color(0xFF8FA3B8);
  static const epargne = Color(0xFF3CE0FF);

  static const texte = Color(0xFFFFFFFF);
  static const texteSecondaire = Color(0xFFB3B3B3);
  static const texteDiscret = Color(0xFF8A8A8A);

  /// Le vert néon du logo, réservé au contour du logo lui-même.
  static const neon = Color(0xFF50F48D);
}

class AppTheme {
  const AppTheme._();

  static const police = 'Figtree';

  static ThemeData get sombre {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: police,
      scaffoldBackgroundColor: AppColors.fond,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.vert,
        onPrimary: Colors.black,
        secondary: AppColors.vert,
        surface: AppColors.surface,
        onSurface: AppColors.texte,
        error: AppColors.alerte,
      ),
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: police,
        bodyColor: AppColors.texte,
        displayColor: AppColors.texte,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.vert,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: police, fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHaute,
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: AppColors.texteDiscret),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.black : AppColors.texteSecondaire),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.vert : AppColors.surfaceHaute),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHaute,
        contentTextStyle: TextStyle(fontFamily: police, color: AppColors.texte),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surfaceHaute),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.surface),
      dividerColor: AppColors.trait,
    );
  }
}

/// Les chiffres : même police, chiffres de largeur égale pour que les
/// colonnes de montants s'alignent.
const chiffres = [FontFeature.tabularFigures()];
