import 'dart:async';
import 'dart:ui';

import '../models/figura.dart';
import 'vibracion.dart';
import 'voz.dart';

/// Convierte el toque del dedo en vibración y voz.
/// Lo usan la pantalla de explorar y la de retos.
class ExploradorTactil {
  /// Tiempo que el dedo debe quedarse en un elemento antes de narrarlo.
  /// En celulares lentos el motor de voz tarda en arrancar; si cada
  /// movimiento interrumpe la frase anterior, nunca se alcanza a oír nada.
  static const Duration _espera = Duration(milliseconds: 250);

  String? _claveActual;
  String? _claveNarrada;
  DateTime _ultimaVibracion = DateTime.fromMillisecondsSinceEpoch(0);
  ElementoFigura? _elemento;
  Timer? _timerVoz;

  ElementoFigura? get elemento => _elemento;

  /// [p] es el punto normalizado (0 a 1) y ya sin rotación.
  /// Regresa true la primera vez que el dedo entra a un elemento de la figura.
  bool tocar(Figura figura, Offset p) {
    final e = figura.elementoEn(p, actual: _elemento);
    _elemento = e;
    final cambio = e.clave != _claveActual;
    final ahora = DateTime.now();

    if (cambio) {
      _claveActual = e.clave;
      // La vibración es inmediata: es lo que el niño siente primero.
      if (e.tipo == TipoElemento.vertice) {
        Vibracion.vertice();
      } else if (e.tipo == TipoElemento.lado) {
        Vibracion.lado();
      }
      _ultimaVibracion = ahora;
      _programarVoz(e);
    } else if (e.tipo == TipoElemento.lado &&
        ahora.difference(_ultimaVibracion).inMilliseconds > 120) {
      // Mientras sigue sobre el lado, vibra seguido para que lo pueda seguir.
      Vibracion.lado();
      _ultimaVibracion = ahora;
    }
    return cambio && e.tipo != TipoElemento.fuera;
  }

  /// La voz espera a que el dedo se asiente; si cambia antes, se reprograma.
  void _programarVoz(ElementoFigura e) {
    _timerVoz?.cancel();
    _timerVoz = Timer(_espera, () => _narrar(e));
  }

  void _narrar(ElementoFigura e) {
    if (e.clave == _claveNarrada) return;
    _claveNarrada = e.clave;
    Voz.decir(e.descripcion);
  }

  /// Al levantar el dedo se dice de inmediato lo último que tocó.
  void soltar() {
    if (_timerVoz?.isActive ?? false) {
      _timerVoz!.cancel();
      final e = _elemento;
      if (e != null) _narrar(e);
    }
    _claveActual = null;
    _claveNarrada = null;
    _elemento = null;
  }

  void cancelar() {
    _timerVoz?.cancel();
  }
}
