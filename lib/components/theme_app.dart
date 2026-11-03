import 'package:flutter/material.dart';

class ThemeApp {
  static const Color _semilla = Color(0xFF3949AB);

  /// Familia declarada en la sección fonts del pubspec.yaml.
  static const String _fuente = 'Nunito';

  static ThemeData claro() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fuente,
      colorScheme: ColorScheme.fromSeed(seedColor: _semilla),
    );
  }

  static ThemeData oscuro() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fuente,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _semilla,
        brightness: Brightness.dark,
      ),
    );
  }

  /// Negro con amarillo: la combinación más legible para baja visión.
  static ThemeData altoContraste() {
    const amarillo = Color(0xFFFFEB3B);
    const esquema = ColorScheme(
      brightness: Brightness.dark,
      primary: amarillo,
      onPrimary: Colors.black,
      secondary: Colors.white,
      onSecondary: Colors.black,
      error: Color(0xFFFF8A80),
      onError: Colors.black,
      surface: Colors.black,
      onSurface: amarillo,
    );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: _fuente,
      colorScheme: esquema,
      scaffoldBackgroundColor: Colors.black,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: amarillo,
        displayColor: amarillo,
      ),
      cardTheme: const CardThemeData(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: amarillo, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
