import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaNotificacion {
  final String topic;
  final String titulo;
  final String descripcion;

  const TemaNotificacion(this.topic, this.titulo, this.descripcion);
}

/// Datos del alumno y sus suscripciones a topics.
/// En la semana 3 cada cambio llama a FirebaseMessaging.subscribeToTopic / unsubscribeFromTopic.
class AlumnoProvider extends ChangeNotifier {
  static const _claveNivel = 'nivel_alumno';
  static const _prefijoTopic = 'topic_';

  static const List<TemaNotificacion> temas = [
    TemaNotificacion('primaria', 'Primaria', 'Lecciones y avisos para nivel primaria'),
    TemaNotificacion('secundaria', 'Secundaria', 'Lecciones y avisos para nivel secundaria'),
    TemaNotificacion('nuevas_lecciones', 'Nuevas lecciones', 'Cuando se agreguen figuras o retos'),
    TemaNotificacion('recordatorios', 'Recordatorios', 'Un aviso para practicar cada día'),
  ];

  final SharedPreferences _prefs;
  late String _nivel;
  final Map<String, bool> _suscripciones = {};

  AlumnoProvider(this._prefs) {
    _nivel = _prefs.getString(_claveNivel) ?? 'primaria';
    for (final t in temas) {
      _suscripciones[t.topic] = _prefs.getBool('$_prefijoTopic${t.topic}') ?? false;
    }
  }

  String get nivel => _nivel;
  bool suscrito(String topic) => _suscripciones[topic] ?? false;

  Future<void> cambiarNivel(String nuevo) async {
    if (nuevo == _nivel) return;
    final anterior = _nivel;
    _nivel = nuevo;
    // Al cambiar de nivel también se cambia el topic del nivel.
    if (suscrito(anterior)) {
      _suscripciones[anterior] = false;
      _suscripciones[nuevo] = true;
      await _prefs.setBool('$_prefijoTopic$anterior', false);
      await _prefs.setBool('$_prefijoTopic$nuevo', true);
    }
    notifyListeners();
    await _prefs.setString(_claveNivel, nuevo);
  }

  Future<void> cambiarSuscripcion(String topic, bool activo) async {
    _suscripciones[topic] = activo;
    notifyListeners();
    await _prefs.setBool('$_prefijoTopic$topic', activo);
  }
}
