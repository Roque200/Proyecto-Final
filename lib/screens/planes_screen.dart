import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/responsivo.dart';
import '../models/plan.dart';
import '../providers/plan_provider.dart';

class PlanesScreen extends StatelessWidget {
  const PlanesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ancho = Responsivo.esAncho(context);
    final tarjetas = Plan.planes.map((p) => _TarjetaPlan(plan: p)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(title: Text('Planes')),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: ancho
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final t in tarjetas) Expanded(child: t)],
                    )
                  : Column(children: tarjetas),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  final Plan plan;

  const _TarjetaPlan({required this.plan});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PlanProvider>();
    final actual = prov.planActual == plan.nivel;
    final colores = Theme.of(context).colorScheme;
    final destacado = plan.nivel == 1;

    return Card(
      elevation: destacado ? 6 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: actual ? colores.primary : colores.outlineVariant,
          width: actual ? 3 : 1,
        ),
      ),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(plan.nombre, style: Theme.of(context).textTheme.headlineSmall),
                if (destacado) const Chip(label: Text('Recomendado')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.precioTexto,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colores.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            for (final linea in plan.incluye)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 20, color: colores.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(linea)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: actual
                  ? const OutlinedButton(onPressed: null, child: Text('Plan actual'))
                  : FilledButton(
                      onPressed: prov.guardando ? null : () => prov.elegir(context, plan),
                      child: const Text('Elegir'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
