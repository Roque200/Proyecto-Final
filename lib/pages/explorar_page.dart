import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/figura_painter.dart';
import '../components/theme_app.dart';
import '../providers/explorar_provider.dart';

/// Exploración táctil de la figura (CustomPainter + Semantics).
class ExplorarPage extends StatelessWidget {
  const ExplorarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExplorarProvider>();
    final figura = prov.figura;
    final nombre = figura.nombre[0].toUpperCase() + figura.nombre.substring(1);

    return Theme(
      data: ThemeApp.altoContraste(),
      child: Builder(
        builder: (context) {
          final colores = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        Text(
                          '${prov.indice + 1} / ${prov.figuras.length}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: LayoutBuilder(
                          builder: (context, area) {
                            final tamano = Size(area.maxWidth, area.maxHeight);
                            return Semantics(
                              label: 'Área de exploración. $nombre. '
                                  'Desliza un dedo para sentir la figura.',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onScaleStart: (d) {
                                  if (d.pointerCount == 1) prov.tocar(d.localFocalPoint, tamano);
                                },
                                onScaleUpdate: (d) {
                                  if (d.pointerCount == 1) {
                                    prov.tocar(d.localFocalPoint, tamano);
                                  } else {
                                    prov.arrastreDosDedos(d.focalPointDelta.dx);
                                  }
                                },
                                onScaleEnd: (_) {
                                  prov.terminarArrastre();
                                  prov.soltar();
                                },
                                onLongPress: prov.informacion,
                                onDoubleTap: prov.reiniciarRotacion,
                                child: CustomPaint(
                                  size: tamano,
                                  painter: FiguraPainter(
                                    figura: figura,
                                    rotacion: prov.rotacion,
                                    dedo: prov.dedo,
                                    resaltado: prov.resaltado,
                                    colorLinea: colores.primary,
                                    colorRelleno: colores.primary.withValues(alpha: 0.12),
                                    colorResaltado: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      prov.resaltado?.descripcion ??
                          'Mantén presionado: información · Dos dedos: cambiar figura · '
                              'Doble toque: enderezar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
