import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Texto a voz en español para toda la app.
class Voz {
  static final FlutterTts _tts = FlutterTts();
  static bool _listo = false;

  static bool get _esIos => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> inicializar() async {
    if (_listo) return;
    await _tts.setLanguage('es-MX');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    if (_esIos) {
      // En iPhone la voz se escucha aunque el switch de silencio esté activado.
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ]);
    }
    _listo = true;
  }

  /// Corta lo que se esté diciendo y dice el texto nuevo.
  static Future<void> decir(String texto) async {
    await inicializar();
    // En Android el modo de cola por defecto (QUEUE_FLUSH) ya interrumpe
    // la frase anterior; llamar stop() antes solo agrega retraso.
    // En iOS sí hay que detenerla, porque ahí las frases se encolan.
    if (_esIos) await _tts.stop();
    await _tts.speak(texto);
  }

  static Future<void> callar() async {
    await _tts.stop();
  }
}
