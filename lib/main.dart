import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/menu_tema.dart';
import 'components/responsivo.dart';
import 'components/voz.dart';
import 'firebase_options.dart';
import 'pages/explorar_page.dart';
import 'pages/menu_alumno_page.dart';
import 'pages/reto_page.dart';
import 'providers/auth_provider.dart';
import 'providers/explorar_provider.dart';
import 'providers/menu_alumno_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/progreso_provider.dart';
import 'providers/reto_provider.dart';
import 'providers/tema_provider.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/verificar_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Conecta la app con el proyecto pulsso-4dd5f (configuración generada
  // por flutterfire configure en firebase_options.dart).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  await Voz.inicializar();
  final onboardingVisto = prefs.getBool(OnboardingProvider.claveVisto) ?? false;

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => TemaProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
        '/': (context) => const InicioProvisional(),
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
      // Rutas que todavía no existen (pantallas del tutor...)
      onUnknownRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (context) => EnConstruccion(ruta: settings.name ?? ''),
      ),
    );
  }
}

/// Pantalla temporal mientras se construye el dashboard del tutor (semana 2).
class InicioProvisional extends StatelessWidget {
  const InicioProvisional({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${auth.usuario?.nombre ?? 'tutor'}'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.cerrarSesion(context),
          ),
        ],
      ),
      // Menú circular para cambiar entre tema claro, oscuro y alto contraste.
      body: MenuTema(
        // En tablet o escritorio el contenido no se estira de lado a lado.
        contenido: ContenidoCentrado(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 72,
                child: FilledButton.icon(
                  icon: const Icon(Icons.accessibility_new, size: 32),
                  label: const Text('Iniciar modo alumno'),
                  onPressed: () => Navigator.pushNamed(context, '/alumno'),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.pan_tool_alt),
                label: const Text('Ir directo a explorar'),
                onPressed: () => Navigator.pushNamed(context, '/explorar'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Ver la bienvenida otra vez'),
                // Reemplaza el inicio para que no se acumulen pantallas.
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/onboarding'),
              ),
            ],
          ),
        ),
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
