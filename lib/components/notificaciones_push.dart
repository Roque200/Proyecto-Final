import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'voz.dart';

/// Se ejecuta aparte de la app (en otro isolate) cuando llega un mensaje
/// con la app en segundo plano o cerrada. La notificación la dibuja el
/// sistema solo; aquí únicamente se registra que llegó.
///
/// Tiene que ser una función de primer nivel (fuera de cualquier clase) y
/// llevar @pragma para que el compilador no la elimine al optimizar.
@pragma('vm:entry-point')
Future<void> manejarPushEnSegundoPlano(RemoteMessage mensaje) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Push en segundo plano: ${mensaje.notification?.title}');
}

/// Notificaciones push con Firebase Cloud Messaging.
///
/// Los mensajes se mandan desde la consola de Firebase (sin backend propio).
/// Si traen en "Datos personalizados" la clave `ruta` (por ejemplo
/// `/progreso`), al tocarlos la app abre esa pantalla.
///
/// Los tres estados de la app:
/// - Primer plano: onMessage → aviso dentro de la app (y se lee en voz alta).
/// - Segundo plano: el sistema muestra la notificación; al tocarla llega
///   por onMessageOpenedApp.
/// - Cerrada: el sistema muestra la notificación; al tocarla la app arranca
///   y el mensaje se recupera con getInitialMessage.
class NotificacionesPush {
  /// Llaves globales: permiten navegar y mostrar avisos desde fuera de un
  /// widget. Así el listener funciona en cualquier pantalla de la app.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Se registra antes de runApp (lo pide firebase_messaging).
  static void registrarSegundoPlano() {
    FirebaseMessaging.onBackgroundMessage(manejarPushEnSegundoPlano);
  }

  /// Se llama después de runApp, cuando ya existe el Navigator.
  static Future<void> inicializar() async {
    try {
      // Android 13+ e iOS piden permiso para mostrar notificaciones.
      await _fcm.requestPermission();
      // En iOS, que también se muestren con la app abierta.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 1) Primer plano: listener global, activo en todas las pantallas.
      FirebaseMessaging.onMessage.listen(_enPrimerPlano);

      // 2) Segundo plano: el tutor tocó la notificación.
      FirebaseMessaging.onMessageOpenedApp.listen(_abrir);

      // 3) App cerrada: se abrió desde una notificación.
      final inicial = await _fcm.getInitialMessage();
      if (inicial != null) {
        await WidgetsBinding.instance.endOfFrame;
        _abrir(inicial);
      }

      // Token del dispositivo: sirve para mandarle un mensaje de prueba
      // solo a este celular desde la consola de Firebase.
      debugPrint('Token FCM: ${await _fcm.getToken()}');
    } catch (e) {
      // En iPhone con cuenta de Apple gratuita no hay APNs y getToken falla:
      // la app sigue funcionando, solo que sin push.
      debugPrint('Push: no se pudo inicializar ($e)');
    }
  }

  static void _enPrimerPlano(RemoteMessage mensaje) {
    final titulo = mensaje.notification?.title ?? 'Pulssó';
    final cuerpo = mensaje.notification?.body ?? '';
    final ruta = mensaje.data['ruta'] as String?;

    // Pensado para el modo alumno: el aviso también se dice en voz alta.
    Voz.decir('$titulo. $cuerpo');

    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(cuerpo.isEmpty ? titulo : '$titulo\n$cuerpo'),
          action: ruta == null
              ? null
              : SnackBarAction(label: 'Ver', onPressed: () => _navegar(ruta)),
        ),
      );
  }

  static void _abrir(RemoteMessage mensaje) {
    final ruta = mensaje.data['ruta'] as String?;
    if (ruta != null) _navegar(ruta);
  }

  /// Solo navega si hay sesión: las pantallas del tutor la necesitan.
  static void _navegar(String ruta) {
    if (FirebaseAuth.instance.currentUser == null) return;
    navigatorKey.currentState?.pushNamed(ruta);
  }

  static Future<void> suscribir(String topic) => _fcm.subscribeToTopic(topic);
  static Future<void> desuscribir(String topic) => _fcm.unsubscribeFromTopic(topic);
}
