import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeApp {
  static const Color _semilla = Color(0xFF3949AB);

  static TextTheme _texto(TextTheme base) => GoogleFonts.nunitoTextTheme(base);

  static ThemeData claro() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _semilla),
    );
    return base.copyWith(textTheme: _texto(base.textTheme));
  }

  static ThemeData oscuro() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _semilla,
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(textTheme: _texto(base.textTheme));
  }

  /// Negro con amarillo: la combinación más legible para baja visión.
  static ThemeData altoContraste() {
    const esquema = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFEB3B),
      onPrimary: Colors.black,
      secondary: Colors.white,
      onSecondary: Colors.black,
      error: Color(0xFFFF8A80),
      onError: Colors.black,
      surface: Colors.black,
      onSurface: Color(0xFFFFEB3B),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Colors.black,
    );
    return base.copyWith(
      textTheme: _texto(base.textTheme).apply(
        bodyColor: const Color(0xFFFFEB3B),
        displayColor: const Color(0xFFFFEB3B),
      ),
      cardTheme: const CardThemeData(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFFFEB3B), width: 2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
