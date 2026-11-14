import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/avatar_usuario.dart';
import '../components/menu_lateral.dart';
import '../components/menu_tema.dart';
import '../components/responsivo.dart';
import '../models/figura.dart';
import '../providers/auth_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/progreso_provider.dart';

class DashScreen extends StatelessWidget {
  const DashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final ancho = Responsivo.esAncho(context);

    return Scaffold(
      drawer: const MenuLateral(),
      body: MenuTema(
        contenido: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 150,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/perfil'),
                    child: const AvatarUsuario(radio: 20),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Hola, ${usuario?.nombre.split(' ').first ?? 'tutor'}'),
                background: const Align(
                  alignment: Alignment(0.85, 0.2),
                  child: Icon(Icons.change_history, size: 80, color: Colors.white24),
                ),
              ),
            ),
            if (ancho)
              // Tablet o escritorio: resumen a la izquierda, lecciones a la derecha.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 2, child: _Resumen()),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: _ListaLecciones.columna()),
                    ],
                  ),
                ),
              )
            else ...[
              const SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(child: _Resumen()),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(child: _TituloLecciones()),
              ),
              _ListaLecciones.sliver(),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    final progreso = context.watch<ProgresoProvider>();
    final plan = context.watch<PlanProvider>().plan;
    final colores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Progreso del alumno',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Chip(label: Text(plan.nombre)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Dato(
                      valor: '${progreso.figurasExploradas}/${Figura.catalogo.length}',
                      etiqueta: 'Figuras exploradas',
                    ),
                    _Dato(valor: '${progreso.retosResueltos}', etiqueta: 'Retos resueltos'),
                    _Dato(valor: '${progreso.totalAciertos}', etiqueta: 'Aciertos'),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/progreso'),
                    child: const Text('Ver detalle'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colores.primary,
              textStyle: Theme.of(context).textTheme.titleLarge,
            ),
            icon: const Icon(Icons.accessibility_new, size: 32),
            label: const Text('Iniciar modo alumno'),
            onPressed: () => Navigator.pushNamed(context, '/alumno'),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _Dato({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(etiqueta, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TituloLecciones extends StatelessWidget {
  const _TituloLecciones();

  @override
  Widget build(BuildContext context) {
    return Text('Lecciones', style: Theme.of(context).textTheme.titleLarge);
  }
}

/// Lista de figuras: como sliver en el celular y como columna en pantallas anchas.
class _ListaLecciones extends StatelessWidget {
  final bool comoSliver;

  const _ListaLecciones._(this.comoSliver);
  factory _ListaLecciones.sliver() => const _ListaLecciones._(true);
  factory _ListaLecciones.columna() => const _ListaLecciones._(false);

  @override
  Widget build(BuildContext context) {
    final planes = context.watch<PlanProvider>();
    final progreso = context.watch<ProgresoProvider>();
    final figuras = Figura.catalogo;

    Widget tarjeta(Figura f) {
      final disponible = planes.disponible(f);
      final p = progreso.de(f.id);
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(child: Icon(_icono(f))),
          title: Text(f.nombre[0].toUpperCase() + f.nombre.substring(1)),
          subtitle: Text(
            disponible
                ? (p.explorada ? 'Explorada · ${p.aciertos} aciertos' : 'Sin explorar')
                : 'Disponible en un plan superior',
          ),
          trailing: Icon(disponible ? Icons.chevron_right : Icons.lock),
          onTap: () => disponible
              ? Navigator.pushNamed(context, '/explorar', arguments: f.id)
              : Navigator.pushNamed(context, '/planes'),
        ),
      );
    }

    if (comoSliver) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => tarjeta(figuras[i]),
            childCount: figuras.length,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TituloLecciones(),
        const SizedBox(height: 8),
        ...figuras.map(tarjeta),
      ],
    );
  }

  static IconData _icono(Figura f) {
    if (f.esCirculo) return Icons.circle_outlined;
    return switch (f.numLados) {
      3 => Icons.change_history,
      4 => f.id == 'rombo' ? Icons.diamond_outlined : Icons.crop_square,
      5 => Icons.pentagon_outlined,
      _ => Icons.hexagon_outlined,
    };
  }
}
