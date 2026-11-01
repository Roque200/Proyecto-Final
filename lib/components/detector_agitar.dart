import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Escucha el acelerómetro y avisa cuando el celular se agita.
class DetectorAgitar {
  static const double _umbral = 22; // m/s², la gravedad sola da ~9.8
  static const Duration _espera = Duration(milliseconds: 1200);

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _ultimo = DateTime.fromMillisecondsSinceEpoch(0);

  void iniciar(void Function() alAgitar) {
    _sub?.cancel();
    _sub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((e) {
      final fuerza = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      final ahora = DateTime.now();
      if (fuerza > _umbral && ahora.difference(_ultimo) > _espera) {
        _ultimo = ahora;
        alAgitar();
      }
    }, onError: (_) {});
  }

  void detener() {
    _sub?.cancel();
    _sub = null;
  }
}
