import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/voz.dart';
import 'pages/explorar_page.dart';
import 'pages/menu_alumno_page.dart';
import 'pages/reto_page.dart';
import 'providers/explorar_provider.dart';
import 'providers/menu_alumno_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/progreso_provider.dart';
import 'providers/reto_provider.dart';
import 'providers/tema_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Voz.inicializar();

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => TemaProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ProgresoProvider()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();

    return MaterialApp(
      title: 'Pulssó',
      debugShowCheckedModeBanner: false,
      theme: tema.temaClaro,
      darkTheme: tema.temaOscuro,
      themeMode: tema.themeMode,
      initialRoute: '/',
      routes: {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pulssó')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
