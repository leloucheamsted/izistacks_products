import 'package:flutter/material.dart';

// Couleurs et polices reprises du site izistacks.com

class IziColors {
  static const ink = Color(0xFF0B1220);
  static const secondary = Color(0xFF51607A);
  static const muted = Color(0xFF93A1B7);
  static const border = Color(0xFFE3E9F2);
  static const surface = Color(0xFFFBFDFF);
  static const surfaceAlt = Color(0xFFF5F8FC);
  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF1E3A8A);
  static const cyan = Color(0xFF22D3EE);
  static const blueTint = Color(0xFFEFF4FF);
  static const danger = Color(0xFFDC2626);

  // le dégradé du logo
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blue, cyan],
  );
}

class IziFonts {
  static const display = 'Sora';
  static const body = 'Figtree';
}

ThemeData iziTheme() {
  const scheme = ColorScheme.light(
    primary: IziColors.blue,
    onPrimary: Colors.white,
    secondary: IziColors.cyan,
    onSecondary: IziColors.ink,
    surface: IziColors.surface,
    onSurface: IziColors.ink,
    onSurfaceVariant: IziColors.secondary,
    outline: IziColors.border,
    outlineVariant: IziColors.border,
    error: IziColors.danger,
    onError: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: IziFonts.body,
  );

  const sora = TextStyle(
    fontFamily: IziFonts.display,
    fontWeight: FontWeight.w700,
    color: IziColors.ink,
  );

  return base.copyWith(
    scaffoldBackgroundColor: IziColors.surface,
    textTheme: base.textTheme
        .apply(bodyColor: IziColors.ink, displayColor: IziColors.ink)
        .copyWith(
          headlineSmall: sora.copyWith(fontSize: 24, letterSpacing: -0.5),
          titleLarge: sora.copyWith(fontSize: 20, letterSpacing: -0.3),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: IziColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: IziColors.secondary,
          ),
          bodySmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: IziColors.muted,
          ),
          labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          labelSmall: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: IziColors.blue,
          ),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: IziColors.surface,
      foregroundColor: IziColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: sora.copyWith(fontSize: 20, letterSpacing: -0.3),
      shape: const Border(bottom: BorderSide(color: IziColors.border)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: IziColors.blue,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: IziColors.ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: const TextStyle(
        fontFamily: IziFonts.body,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
