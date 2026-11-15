import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' show Stripe;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:shared_preferences/shared_preferences.dart';

import 'components/notificaciones_push.dart';
import 'components/voz.dart';
import 'config/stripe_config.dart';
import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'pages/explorar_page.dart';
import 'pages/menu_alumno_page.dart';
import 'pages/reto_page.dart';
import 'providers/alumno_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/explorar_provider.dart';
import 'providers/menu_alumno_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/progreso_provider.dart';
import 'providers/reto_provider.dart';
import 'providers/tema_provider.dart';
import 'screens/dash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notificaciones_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pago_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/planes_screen.dart';
import 'screens/progreso_screen.dart';
import 'screens/recuperar_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/verificar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Conecta la app con el proyecto pulsso-4dd5f (configuración generada
  // por flutterfire configure en firebase_options.dart).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Supabase solo se usa para guardar las fotos de perfil (Storage).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  // Notificaciones con la app en segundo plano o cerrada.
  NotificacionesPush.registrarSegundoPlano();
  // Stripe en modo de prueba, con la clave publicable.
  Stripe.publishableKey = StripeConfig.publishableKey;
  await Stripe.instance.applySettings();
  final prefs = await SharedPreferences.getInstance();
  await Voz.inicializar();
  final onboardingVisto = prefs.getBool(OnboardingProvider.claveVisto) ?? false;

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => TemaProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AlumnoProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ProgresoProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      // Si ya vio la bienvenida, arranca según la sesión guardada:
      // login, verificar correo o inicio.
      child: MyApp(
        rutaInicial: onboardingVisto
            ? AuthProvider.rutaInicial()
            : '/onboarding',
      ),
    ),
  );

  // Ya con la app en pantalla: permisos y listener global de push.
  NotificacionesPush.inicializar();
}

class MyApp extends StatelessWidget {
  final String rutaInicial;

  const MyApp({super.key, required this.rutaInicial});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();

    return MaterialApp(
      title: 'Pulssó',
      debugShowCheckedModeBanner: false,
      // Llaves globales para que las notificaciones puedan mostrar avisos y
      // abrir pantallas sin importar en cuál esté el tutor.
      navigatorKey: NotificacionesPush.navigatorKey,
      scaffoldMessengerKey: NotificacionesPush.messengerKey,
      theme: tema.temaClaro,
      darkTheme: tema.temaOscuro,
      themeMode: tema.themeMode,
      initialRoute: rutaInicial,
      routes: {
        '/onboarding': (context) => ChangeNotifierProvider(
          // Al terminar va al login, o al inicio si ya hay sesión.
          create: (ctx) => OnboardingProvider(
            ctx.read<SharedPreferences>(),
            destino: AuthProvider.rutaInicial(),
          )..narrarActual(),
          child: const OnboardingScreen(),
        ),
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/verificar': (context) => const VerificarScreen(),
        '/recuperar': (context) => const RecuperarScreen(),
        // Dashboard del tutor: pantalla principal después de iniciar sesión.
        '/': (context) => const DashScreen(),
        '/progreso': (context) => const ProgresoScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/notificaciones': (context) => const NotificacionesScreen(),
        '/planes': (context) => const PlanesScreen(),
        '/pago': (context) => const PagoScreen(),
        '/alumno': (context) => ChangeNotifierProvider(
          create: (_) => MenuAlumnoProvider()..iniciar(),
          child: const MenuAlumnoPage(),
        ),
        '/explorar': (context) {
          final figuraId =
              ModalRoute.of(context)?.settings.arguments as String?;
          return ChangeNotifierProvider(
            create: (ctx) => ExplorarProvider(
              figuras: ctx.read<PlanProvider>().figurasDisponibles,
              alExplorar: ctx.read<ProgresoProvider>().marcarExplorada,
              figuraInicial: figuraId,
            )..iniciar(),
            child: const ExplorarPage(),
          );
        },
        '/reto': (context) => ChangeNotifierProvider(
          create: (ctx) => RetoProvider(
            figuras: ctx.read<PlanProvider>().figurasDisponibles,
            alResponder: ctx.read<ProgresoProvider>().registrarReto,
          )..iniciar(),
          child: const RetoPage(),
        ),
      },
      // Rutas que todavía no existen (perfil, planes, mapa...)
      onUnknownRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (context) => EnConstruccion(ruta: settings.name ?? ''),
      ),
    );
  }
}

/// Se muestra al abrir una ruta que todavía no existe, en lugar de que truene.
class EnConstruccion extends StatelessWidget {
  final String ruta;

  const EnConstruccion({super.key, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('En construcción')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 80),
              const SizedBox(height: 16),
              Text(
                'La pantalla $ruta todavía no está lista.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Regresar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
