import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/theme_app.dart';
import '../providers/menu_alumno_provider.dart';

/// Menú del modo alumno: una opción a la vez, toda la pantalla es el botón.
class MenuAlumnoPage extends StatelessWidget {
  const MenuAlumnoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MenuAlumnoProvider>();
    final opcion = prov.opcion;
    final total = MenuAlumnoProvider.opciones.length;

    return Theme(
      data: ThemeApp.altoContraste(),
      child: Builder(
        builder: (context) {
          final colores = Theme.of(context).colorScheme;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) prov.pedirSalida();
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: prov.repetir,
                onDoubleTap: () => prov.activar(context),
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  prov.mover(v < 0 ? 1 : -1);
                },
                onLongPressStart: (_) => prov.empezarPresion(),
                onLongPressEnd: (_) => prov.terminarPresion(),
                child: Semantics(
                  label: prov.confirmandoSalida
                      ? '¿Salir del modo alumno? Toca dos veces para confirmar'
                      : 'Opción ${prov.indice + 1} de $total: ${opcion.titulo}',
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              prov.confirmandoSalida ? Icons.help_outline : opcion.icono,
                              size: 160,
                              color: colores.primary,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              prov.confirmandoSalida ? '¿Salir?' : opcion.titulo,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              prov.confirmandoSalida
                                  ? 'Toca dos veces para confirmar\nDesliza para cancelar'
                                  : '${prov.indice + 1} de $total',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
