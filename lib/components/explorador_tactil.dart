import 'dart:ui';

import '../models/figura.dart';
import 'vibracion.dart';
import 'voz.dart';

/// Convierte el toque del dedo en vibración y voz.
/// Lo usan la pantalla de explorar y la de retos.
class ExploradorTactil {
  String? _claveActual;
  DateTime _ultimaVibracion = DateTime.fromMillisecondsSinceEpoch(0);
  ElementoFigura? _elemento;

  ElementoFigura? get elemento => _elemento;

  /// [p] es el punto normalizado (0 a 1) y ya sin rotación.
  /// Regresa true la primera vez que el dedo entra a la figura.
  bool tocar(Figura figura, Offset p) {
    final e = figura.elementoEn(p);
    _elemento = e;
    final cambio = e.clave != _claveActual;
    final ahora = DateTime.now();

    if (cambio) {
      _claveActual = e.clave;
      if (e.tipo == TipoElemento.vertice) {
        Vibracion.vertice();
      } else if (e.tipo == TipoElemento.lado) {
        Vibracion.lado();
      }
      _ultimaVibracion = ahora;
      Voz.decir(e.descripcion);
    } else if (e.tipo == TipoElemento.lado &&
        ahora.difference(_ultimaVibracion).inMilliseconds > 120) {
      // Mientras sigue sobre el lado, vibra seguido para que lo pueda seguir.
      Vibracion.lado();
      _ultimaVibracion = ahora;
    }
    return cambio && e.tipo != TipoElemento.fuera;
  }

  void soltar() {
    _claveActual = null;
    _elemento = null;
  }
}
