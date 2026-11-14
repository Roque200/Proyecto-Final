import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/figura.dart';
import '../providers/plan_provider.dart';
import '../providers/progreso_provider.dart';

class ProgresoScreen extends StatelessWidget {
  const ProgresoScreen({super.key});

  static String _fecha(DateTime? d) {
    if (d == null) return 'Sin práctica';
    String dos(int n) => n.toString().padLeft(2, '0');
    return 'Última práctica: ${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final progreso = context.watch<ProgresoProvider>();
    final planes = context.watch<PlanProvider>();
    final figuras = Figura.catalogo;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(title: Text('Progreso del alumno')),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final f = figuras[i];
                  final p = progreso.de(f.id);
                  final disponible = planes.disponible(f);
                  final total = p.aciertos + p.errores;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          !disponible
                              ? Icons.lock
                              : p.explorada
                                  ? Icons.check
                                  : Icons.hourglass_empty,
                        ),
                      ),
                      title: Text(f.nombre[0].toUpperCase() + f.nombre.substring(1)),
                      subtitle: Text(
                        disponible
                            ? '${p.explorada ? 'Explorada' : 'Sin explorar'} · ${_fecha(p.ultimaPractica)}'
                            : 'No incluida en el plan actual',
                      ),
                      trailing: total == 0
                          ? null
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${p.aciertos}/$total',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const Text('aciertos'),
                              ],
                            ),
                    ),
                  );
                },
                childCount: figuras.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
