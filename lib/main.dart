import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/voz.dart';
import 'pages/explorar_page.dart';
import 'providers/explorar_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/progreso_provider.dart';
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
      initialRoute: '/explorar',
      routes: {
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
      },
    );
  }
}
