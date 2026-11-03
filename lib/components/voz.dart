import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Texto a voz en español para toda la app.
class Voz {
  static final FlutterTts _tts = FlutterTts();
  static bool _listo = false;
  static String? _idioma;

  /// En orden de preferencia. No todos los celulares traen español de México.
  static const List<String> _idiomas = [
    'es-MX',
    'es-US',
    'es-419',
    'es-ES',
    'es',
  ];

  static bool get _esIos => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _esAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Idioma que se terminó usando (sirve para revisar en la consola).
  static String? get idioma => _idioma;

  static Future<void> inicializar() async {
    if (_listo) return;
    try {
      _idioma = await _elegirIdioma();
      if (_idioma != null) await _tts.setLanguage(_idioma!);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      if (_esIos) {
        // En iPhone la voz se escucha aunque el switch de silencio esté activado.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ]);
      }
      if (_esAndroid) {
        debugPrint(
          'Voz: motor ${await _tts.getDefaultEngine}, idioma $_idioma',
        );
      }
    } catch (e) {
      // Si el celular no tiene motor de voz, la app sigue funcionando
      // con la vibración en lugar de tronar.
      debugPrint('Voz: no se pudo inicializar ($e)');
    }
    _listo = true;
  }

  /// En Android primero busca una voz instalada en el celular (funciona sin
  /// internet); si no hay, usa la primera disponible aunque requiera red.
  static Future<String?> _elegirIdioma() async {
    if (_esAndroid) {
      for (final codigo in _idiomas) {
        if (await _tts.isLanguageInstalled(codigo) == true) return codigo;
      }
    }
    for (final codigo in _idiomas) {
      if (await _tts.isLanguageAvailable(codigo) == true) return codigo;
    }
    return null;
  }

  /// Corta lo que se esté diciendo y dice el texto nuevo.
  static Future<void> decir(String texto) async {
    await inicializar();
    try {
      // En Android el modo de cola por defecto (QUEUE_FLUSH) ya interrumpe
      // la frase anterior; llamar stop() antes solo agrega retraso.
      // En iOS sí hay que detenerla, porque ahí las frases se encolan.
      if (_esIos) await _tts.stop();
      await _tts.speak(texto);
    } catch (e) {
      debugPrint('Voz: no se pudo hablar ($e)');
    }
  }

  static Future<void> callar() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
