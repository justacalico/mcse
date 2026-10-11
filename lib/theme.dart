import 'package:flutter/material.dart';

const seed = Color(0xFF5BA829); // grass-block green

ThemeData mcseTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    fontFamilyFallback: const ['sans-serif'],
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

ThemeData get lightTheme => mcseTheme(Brightness.light);
ThemeData get darkTheme => mcseTheme(Brightness.dark);
