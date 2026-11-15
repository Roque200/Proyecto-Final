import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alumno_provider.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alumno = context.watch<AlumnoProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(title: Text('Notificaciones')),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Elige de qué temas quieres recibir avisos. Los mensajes se mandan '
                'desde la consola de Firebase a cada tema (topic).',
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final t = AlumnoProvider.temas[i];
                return SwitchListTile(
                  secondary: const Icon(Icons.campaign),
                  title: Text(t.titulo),
                  subtitle: Text(t.descripcion),
                  value: alumno.suscrito(t.topic),
                  // Desactivado mientras se confirma con Firebase.
                  onChanged: alumno.cambiando(t.topic)
                      ? null
                      : (v) => alumno.cambiarSuscripcion(t.topic, v),
                );
              },
              childCount: AlumnoProvider.temas.length,
            ),
          ),
        ],
      ),
    );
  }
}
