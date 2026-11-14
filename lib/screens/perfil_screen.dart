import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../components/avatar_usuario.dart';
import '../components/responsivo.dart';
import '../providers/alumno_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/plan_provider.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  void _elegirOrigen(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(hoja);
                auth.cambiarFoto(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(hoja);
                auth.cambiarFoto(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;
    final alumno = context.watch<AlumnoProvider>();
    final plan = context.watch<PlanProvider>().plan;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ContenidoCentrado(
          anchoMaximo: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const AvatarUsuario(radio: 56),
                    if (auth.cargando)
                      const SizedBox(
                        width: 112,
                        height: 112,
                        child: CircularProgressIndicator(strokeWidth: 4),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (usuario?.puedeEditarFoto ?? false)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Cambiar foto'),
                    onPressed: auth.cargando ? null : () => _elegirOrigen(context),
                  ),
                )
              else
                Text(
                  'La foto viene de tu cuenta de ${usuario?.nombreProveedor ?? ''} y no se puede cambiar aquí.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Nombre'),
                      subtitle: Text(usuario?.nombre ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Correo'),
                      subtitle: Text(usuario?.correo ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Inicio de sesión con'),
                      subtitle: Text(usuario?.nombreProveedor ?? ''),
                    ),
                    ListTile(
                      leading: const Icon(Icons.workspace_premium),
                      title: const Text('Plan'),
                      subtitle: Text(plan.nombre),
                      trailing: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/planes'),
                        child: const Text('Cambiar'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Nivel del alumno', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'primaria', label: Text('Primaria'), icon: Icon(Icons.child_care)),
                  ButtonSegment(value: 'secundaria', label: Text('Secundaria'), icon: Icon(Icons.school)),
                ],
                selected: {alumno.nivel},
                onSelectionChanged: (s) => alumno.cambiarNivel(s.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
