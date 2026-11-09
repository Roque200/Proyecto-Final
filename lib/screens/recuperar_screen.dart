import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/campo_texto.dart';
import '../components/responsivo.dart';
import '../providers/auth_provider.dart';

class RecuperarScreen extends StatelessWidget {
  const RecuperarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: ContenidoCentrado(
          key: ValueKey(auth.versionFormulario),
          child: auth.correoRecuperacionEnviado
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_read, size: 96, color: colores.primary),
                    const SizedBox(height: 24),
                    Text(
                      'Listo, revisa tu correo',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mandamos un enlace a ${auth.correo} para que crees una contraseña nueva.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          auth.limpiarFormulario();
                          Navigator.pop(context);
                        },
                        child: const Text('Volver al inicio de sesión'),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_reset, size: 96, color: colores.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Escribe el correo de tu cuenta y te mandaremos un enlace para cambiar tu contraseña.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CampoTexto(
                      etiqueta: 'Correo',
                      icono: Icons.email,
                      teclado: TextInputType.emailAddress,
                      error: auth.error('correo'),
                      alCambiar: (v) => auth.correo = v,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: auth.cargando ? null : () => auth.enviarRecuperacion(context),
                        child: auth.cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            : const Text('Enviar enlace'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
