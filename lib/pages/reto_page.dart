import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/figura_painter.dart';
import '../components/theme_app.dart';
import '../providers/reto_provider.dart';

/// Reto: la figura para explorar y la zona para responder con toques.
/// En vertical van una arriba de otra; en horizontal (tablet o cel acostado)
/// van lado a lado para aprovechar el ancho.
class RetoPage extends StatelessWidget {
  const RetoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RetoProvider>();
    final terminado = prov.estado == EstadoReto.terminado;
    final horizontal = MediaQuery.sizeOf(context).aspectRatio > 1;

    return Theme(
      data: ThemeApp.altoContraste(),
      child: Builder(
        builder: (context) {
          final colores = Theme.of(context).colorScheme;
          final textos = Theme.of(context).textTheme;

          // ------------------------------------------ Figura
          final figura = Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, area) {
                  final tamano = Size(area.maxWidth, area.maxHeight);
                  return Semantics(
                    label: 'Figura para explorar',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) => prov.tocarFigura(d.localPosition, tamano),
                      onPanUpdate: (d) => prov.tocarFigura(d.localPosition, tamano),
                      onPanEnd: (_) => prov.soltarFigura(),
                      child: CustomPaint(
                        size: tamano,
                        painter: FiguraPainter(
                          figura: prov.pregunta.figura,
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
          );

          // ------------------------------------------ Zona de respuesta
          final zona = Semantics(
            button: true,
            label: 'Zona de respuesta. Toca tantas veces como la respuesta.',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: prov.tocarRespuesta,
              onLongPress: prov.repetir,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fondo(prov),
                  border: Border.all(color: colores.primary, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  _textoZona(prov),
                  textAlign: TextAlign.center,
                  style: textos.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          );

          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      terminado
                          ? 'Acertaste ${prov.aciertos} de ${prov.preguntas.length}'
                          : 'Pregunta ${prov.indice + 1} de ${prov.preguntas.length}\n'
                              '${prov.pregunta.texto}',
                      textAlign: TextAlign.center,
                      style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: horizontal
                        ? Row(
                            children: [
                              Expanded(flex: 3, child: figura),
                              Expanded(flex: 2, child: zona),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(flex: 3, child: figura),
                              Expanded(flex: 2, child: zona),
                            ],
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

  static Color _fondo(RetoProvider prov) {
    if (prov.estado != EstadoReto.resultado) return Colors.black;
    return prov.ultimaCorrecta == true ? const Color(0xFF1B5E20) : const Color(0xFF7F0000);
  }

  static String _textoZona(RetoProvider prov) {
    return switch (prov.estado) {
      EstadoReto.respondiendo => prov.toques == 0 ? 'Toca aquí' : '${prov.toques}',
      EstadoReto.resultado => prov.ultimaCorrecta == true ? '¡Correcto!' : 'Casi',
      EstadoReto.terminado => 'Toca para\nempezar otra vez',
    };
  }
}
