import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/theme_app.dart';

enum ModoTema { claro, oscuro, contraste }

class TemaProvider extends ChangeNotifier {
  static const _clave = 'modo_tema';
  final SharedPreferences _prefs;
  late ModoTema _modo;

  TemaProvider(this._prefs) {
    final guardado = _prefs.getInt(_clave) ?? 0;
    _modo = ModoTema.values[guardado.clamp(0, ModoTema.values.length - 1)];
  }

  ModoTema get modo => _modo;

  /// El alto contraste se maneja como un tema propio en lugar del tema claro.
  ThemeData get temaClaro =>
      _modo == ModoTema.contraste ? ThemeApp.altoContraste() : ThemeApp.claro();

  ThemeData get temaOscuro =>
      _modo == ModoTema.contraste ? ThemeApp.altoContraste() : ThemeApp.oscuro();

  ThemeMode get themeMode =>
      _modo == ModoTema.claro ? ThemeMode.light : ThemeMode.dark;

  Future<void> cambiar(ModoTema nuevo) async {
    if (nuevo == _modo) return;
    _modo = nuevo;
    notifyListeners();
    await _prefs.setInt(_clave, nuevo.index);
  }
}
