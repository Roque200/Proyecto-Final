import 'package:vibration/vibration.dart';

/// Patrones de vibración del modo alumno.
class Vibracion {
  static bool? _tiene;
  static bool? _amplitud;

  static Future<bool> _puede() async {
    _tiene ??= await Vibration.hasVibrator();
    _amplitud ??= await Vibration.hasAmplitudeControl();
    return _tiene!;
  }

  static Future<void> _vibrar(int ms, int fuerza) async {
    if (!await _puede()) return;
    if (_amplitud!) {
      await Vibration.vibrate(duration: ms, amplitude: fuerza);
    } else {
      await Vibration.vibrate(duration: ms);
    }
  }

  /// Suave: el dedo va sobre un lado.
  static Future<void> lado() => _vibrar(40, 90);

  /// Fuerte: el dedo llegó a un vértice.
  static Future<void> vertice() => _vibrar(120, 255);

  /// Muy corta: cada toque al responder un reto.
  static Future<void> toque() => _vibrar(25, 150);

  static Future<void> acierto() async {
    if (!await _puede()) return;
    await Vibration.vibrate(pattern: [0, 80, 80, 80]);
  }

  static Future<void> error() async {
    if (!await _puede()) return;
    await Vibration.vibrate(pattern: [0, 400]);
  }

  static Future<void> cancelar() => Vibration.cancel();
}
