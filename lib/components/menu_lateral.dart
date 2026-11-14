import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'avatar_usuario.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  void _ir(BuildContext context, String ruta) {
    Navigator.pop(context);
    Navigator.pushNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(usuario?.nombre ?? 'Tutor'),
            accountEmail: Text(usuario?.correo ?? ''),
            currentAccountPicture: const AvatarUsuario(radio: 36),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: const Text('Iniciar modo alumno'),
            onTap: () => _ir(context, '/alumno'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () => _ir(context, '/perfil'),
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Progreso del alumno'),
            onTap: () => _ir(context, '/progreso'),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Planes'),
            onTap: () => _ir(context, '/planes'),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Centros de apoyo'),
            onTap: () => _ir(context, '/mapa'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            onTap: () => _ir(context, '/notificaciones'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => context.read<AuthProvider>().cerrarSesion(context),
          ),
        ],
      ),
    );
  }
}
