import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/responsivo.dart';
import '../providers/auth_provider.dart';

class VerificarScreen extends StatelessWidget {
  const VerificarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colores = Theme.of(context).colorScheme;
    final correo = auth.usuario?.correo ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica tu correo'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.cerrarSesion(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ContenidoCentrado(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_unread, size: 96, color: colores.primary),
              const SizedBox(height: 24),
              Text(
                'Te mandamos un correo a',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                correo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Abre el enlace del correo para activar tu cuenta. '
                'Si no lo ves, revisa la carpeta de spam.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  icon: const Icon(Icons.verified),
                  label: const Text('Ya lo verifiqué'),
                  onPressed: auth.cargando ? null : () => auth.confirmarVerificacion(context),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    auth.puedeReenviar
                        ? 'Reenviar correo'
                        : 'Reenviar en ${auth.segundosReenvio} s',
                  ),
                  onPressed: auth.cargando || !auth.puedeReenviar
                      ? null
                      : () => auth.reenviarCorreo(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
