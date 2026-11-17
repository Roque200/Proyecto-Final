# Pulssó

**Geometría que se siente.** Aplicación móvil en Flutter para que niñas y niños **invidentes o con baja visión** de primaria y secundaria aprendan geometría con **voz, vibración y gestos**, al estilo de un lector de pantalla como VoiceOver o TalkBack.

Proyecto final de la materia de **Programación de Dispositivos Móviles** — Instituto Tecnológico de Celaya (TecNM).
Autor: **Jesús Roberto Pérez Roque** (21031190).

---

## Problemática

La geometría es una de las materias más visuales de la educación básica: figuras, lados, vértices y ángulos se enseñan casi siempre con dibujos en el pizarrón o en el libro. Los estudiantes con discapacidad visual dependen de material táctil especializado, que es caro, escaso y no siempre está disponible en casa.

**Pulssó** convierte el celular en un material didáctico accesible: el alumno recorre la figura con el dedo y el teléfono **vibra en los lados, vibra más fuerte en los vértices y le dice en voz alta lo que está tocando**. El tutor (padre, madre o maestro) administra la cuenta, consulta el progreso y elige el plan de suscripción.

## Funcionalidades

### Modo alumno (accesible)
- **Explorar figuras:** figura dibujada con `CustomPainter`; vibración suave en lados y fuerte en vértices, narración de cada elemento, información (lados, vértices, perímetro y área) con presión larga, cambio de figura con dos dedos y repetir instrucciones con doble toque o agitando el celular.
- **Retos por voz:** preguntas de lados y vértices que se responden tocando la pantalla esa cantidad de veces.
- **Menú por gestos:** una opción a la vez; deslizar para cambiar, doble toque para entrar, **agitar el celular para repetir** (acelerómetro) y salida protegida (3 s + confirmación).
- Tema de **alto contraste** (negro y amarillo) en todas las pantallas del alumno.

### Parte del tutor
- **Onboarding** narrado por voz, solo la primera vez.
- **Autenticación:** correo y contraseña (con verificación de correo, reenvío y recuperación de contraseña), **Google** y **GitHub**.
- **Dashboard** con avatar, progreso del alumno, lecciones bloqueadas según el plan y menú circular de temas (claro, oscuro y alto contraste).
- **Perfil** con datos del proveedor; cambio de foto solo para cuentas de correo, sincronizado en toda la app.
- **Progreso** del alumno guardado en la nube, en tiempo real.
- **Notificaciones push** y suscripción a temas (topics).
- **Planes de suscripción** (Básico, Escolar e Institución) con **pago con tarjeta en Stripe**.
- **Mapa nativo** de centros de apoyo con la distancia desde la ubicación del tutor.

## Tecnologías

| Área | Herramienta |
|---|---|
| Framework | Flutter 3.47 · Dart 3.13 |
| Manejo de estado | `provider` (sin `setState` ni `ValueNotifier`) |
| Autenticación | Firebase Auth · `google_sign_in` · GitHub (`signInWithProvider`) |
| Base de datos | Cloud Firestore (con caché local sin conexión) |
| Archivos (fotos de perfil) | Supabase Storage |
| Notificaciones | Firebase Cloud Messaging (topics, primer plano, segundo plano y app cerrada) |
| Pagos | Stripe (`flutter_stripe`, `CardField` nativo, modo de prueba) |
| Mapa y ubicación | `google_maps_flutter` (Maps SDK nativo) · `geolocator` |
| Accesibilidad | `flutter_tts` (voz) · `vibration` · `sensors_plus` (acelerómetro) · `Semantics` |
| Imágenes | `image_picker` · `cached_network_image` |
| Interfaz | Tipografía Nunito local · `circular_menu` · Material 3 |

## Arquitectura

Cada pantalla sigue el patrón **Página + Provider + Componentes**: la página solo dibuja y avisa de los gestos; el provider (`ChangeNotifier`) guarda el estado y la lógica y llama a `notifyListeners()`; los componentes reutilizables encapsulan voz, vibración, sensores y dibujo.

```
lib/
├── main.dart              Firebase, Supabase, Stripe, providers globales y rutas
├── firebase_options.dart  Configuración generada por flutterfire
├── config/                Claves públicas de Stripe y Supabase
├── models/                Figura (geometría), Plan, CentroApoyo
├── providers/             Estado: auth, tema, progreso, plan, alumno, mapa,
│                          onboarding, menú del alumno, explorar y retos
├── components/            Voz, vibración, sensores, FiguraPainter, avatar,
│                          notificaciones push, menú lateral y de temas
├── screens/               Pantallas del tutor (login, dashboard, perfil, pago, mapa…)
└── pages/                 Pantallas del modo alumno (menú, explorar, retos)
```

Datos en Firestore:

```
usuarios/{uid}
├── plan: 0 | 1 | 2
├── progreso/{figuraId}   explorada, aciertos, errores, ultimaPractica
└── pagos/{id}            plan, monto, marca, ultimos4, paymentMethodId, fecha
```

Las reglas de seguridad están en [`firestore.rules`](firestore.rules) y la política del bucket de Supabase en [`supabase/politicas_storage.sql`](supabase/politicas_storage.sql).

## Cómo correr el proyecto

1. Instalar Flutter 3.47 o superior y correr `flutter pub get`.
2. **Firebase:** el proyecto ya incluye `firebase_options.dart`, `google-services.json` y `GoogleService-Info.plist`. Para usar otro proyecto: `flutterfire configure --platforms=android,ios`.
3. **Supabase:** poner la URL y la clave publicable en `lib/config/supabase_config.dart` y crear el bucket público `avatares`.
4. **Stripe:** poner la clave publicable (`pk_test_…`) en `lib/config/stripe_config.dart`.
5. **Google Maps:** poner la API key en `android/app/src/main/AndroidManifest.xml` e `ios/Runner/AppDelegate.swift`.
6. `flutter run`

### Datos de prueba
- Tarjeta aprobada: `4242 4242 4242 4242`, cualquier fecha futura y cualquier CVC.
- Tarjeta rechazada (simulada): `4000 0000 0000 0002`.
- Notificaciones: el token del dispositivo aparece en la consola como `Token FCM: …`; los mensajes se envían desde Firebase → Messaging.

## Limitaciones conocidas

- **Firebase Storage → Supabase Storage:** desde 2024 Firebase Storage requiere el plan de pago Blaze; las fotos de perfil se guardan en Supabase Storage y la identidad sigue siendo Firebase Auth.
- **Pagos:** Stripe valida y tokeniza la tarjeta con su API real (modo de prueba). El cobro se simula, porque cobrar requiere un servidor con la clave secreta y el proyecto es sin backend propio.
- **Push en iPhone:** requiere una cuenta de pago de Apple Developer (APNs); en iOS la app funciona, pero no recibe notificaciones.
- **Google Sign-In en Android** está registrado con la huella SHA-1 de la llave de depuración del equipo de desarrollo.

## Historial

El desarrollo se hizo por etapas, con un commit por funcionalidad:

| Etapa | Commits |
|---|---|
| Semana 1 · núcleo accesible (`v0.1`) | Proyecto base, iOS, figuras, voz y vibración, exploración táctil, tipografía local, menú del alumno, retos, onboarding, temas y diseño responsivo |
| Semana 2 · Firebase | Configuración, login con correo, verificación, recuperación, Google, GitHub, dashboard, progreso en Firestore, perfil con foto |
| Semana 3 · servicios | Notificaciones push y topics, planes, pago con Stripe, mapa nativo |