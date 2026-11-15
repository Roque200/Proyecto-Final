import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/notificaciones_push.dart';

class TemaNotificacion {
  final String topic;
  final String titulo;
  final String descripcion;

  const TemaNotificacion(this.topic, this.titulo, this.descripcion);
}

/// Nivel del alumno y suscripciones del dispositivo a los topics de FCM.
///
/// Un topic es un "canal": desde la consola de Firebase se manda un mensaje
/// al topic `primaria` y le llega a todos los celulares suscritos a él.
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
  final Set<String> _cambiando = {};

  AlumnoProvider(this._prefs) {
    _nivel = _prefs.getString(_claveNivel) ?? 'primaria';
    for (final t in temas) {
      _suscripciones[t.topic] = _prefs.getBool('$_prefijoTopic${t.topic}') ?? false;
    }
  }

  String get nivel => _nivel;
  bool suscrito(String topic) => _suscripciones[topic] ?? false;

  /// Mientras se habla con Firebase, el switch de ese topic se desactiva.
  bool cambiando(String topic) => _cambiando.contains(topic);

  /// Al cambiar de nivel, si estaba suscrito al topic del nivel anterior,
  /// se pasa la suscripción al nuevo (primaria ↔ secundaria).
  Future<void> cambiarNivel(String nuevo) async {
    if (nuevo == _nivel) return;
    final anterior = _nivel;
    _nivel = nuevo;
    notifyListeners();
    await _prefs.setString(_claveNivel, nuevo);

    if (suscrito(anterior)) {
      await cambiarSuscripcion(anterior, false);
      await cambiarSuscripcion(nuevo, true);
    }
  }

  Future<void> cambiarSuscripcion(String topic, bool activo) async {
    if (_cambiando.contains(topic)) return;
    final antes = suscrito(topic);
    _suscripciones[topic] = activo;
    _cambiando.add(topic);
    notifyListeners();

    try {
      if (activo) {
        await NotificacionesPush.suscribir(topic);
      } else {
        await NotificacionesPush.desuscribir(topic);
      }
      await _prefs.setBool('$_prefijoTopic$topic', activo);
    } catch (_) {
      // Sin internet (o sin push en iPhone gratuito): se regresa el switch
      // a como estaba para no mentirle al tutor.
      _suscripciones[topic] = antes;
      NotificacionesPush.messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('No se pudo cambiar la suscripción. Revisa tu conexión.')),
      );
    } finally {
      _cambiando.remove(topic);
      notifyListeners();
    }
  }
}
