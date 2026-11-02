import 'package:flutter/material.dart';

class ProgresoFigura {
  bool explorada;
  int aciertos;
  int errores;
  DateTime? ultimaPractica;

  ProgresoFigura({
    this.explorada = false,
    this.aciertos = 0,
    this.errores = 0,
    this.ultimaPractica,
  });
}

/// Progreso del alumno. En la semana 2 se guarda en Firestore.
class ProgresoProvider extends ChangeNotifier {
  final Map<String, ProgresoFigura> _datos = {};

  ProgresoFigura de(String figuraId) =>
      _datos.putIfAbsent(figuraId, () => ProgresoFigura());

  int get figurasExploradas => _datos.values.where((p) => p.explorada).length;
  int get totalAciertos => _datos.values.fold(0, (s, p) => s + p.aciertos);
  int get totalErrores => _datos.values.fold(0, (s, p) => s + p.errores);
  int get retosResueltos => totalAciertos + totalErrores;

  void marcarExplorada(String figuraId) {
    final p = de(figuraId);
    p.ultimaPractica = DateTime.now();
    if (p.explorada) return;
    p.explorada = true;
    notifyListeners();
  }

  void registrarReto(String figuraId, bool correcto) {
    final p = de(figuraId);
    if (correcto) {
      p.aciertos++;
    } else {
      p.errores++;
    }
    p.ultimaPractica = DateTime.now();
    notifyListeners();
  }
}
