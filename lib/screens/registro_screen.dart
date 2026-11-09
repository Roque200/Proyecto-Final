import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/campo_texto.dart';
import '../components/responsivo.dart';
import '../providers/auth_provider.dart';

class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: ContenidoCentrado(
          key: ValueKey(auth.versionFormulario),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registra la cuenta del tutor. Después podrás iniciar el modo alumno desde el menú.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Nombre completo',
                icono: Icons.person,
                error: auth.error('nombre'),
                alCambiar: (v) => auth.nombre = v,
              ),
              CampoTexto(
                etiqueta: 'Correo',
                icono: Icons.email,
                teclado: TextInputType.emailAddress,
                error: auth.error('correo'),
                alCambiar: (v) => auth.correo = v,
              ),
              CampoTexto(
                etiqueta: 'Contraseña',
                icono: Icons.lock,
                pista: 'Mínimo 6 caracteres',
                oculto: auth.ocultarPassword,
                error: auth.error('password'),
                alCambiar: (v) => auth.password = v,
                sufijo: IconButton(
                  tooltip: auth.ocultarPassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(auth.ocultarPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: auth.alternarPassword,
                ),
              ),
              CampoTexto(
                etiqueta: 'Confirmar contraseña',
                icono: Icons.lock_outline,
                oculto: auth.ocultarPassword,
                error: auth.error('confirmar'),
                alCambiar: (v) => auth.confirmar = v,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: auth.cargando ? null : () => auth.registrar(context),
                  child: auth.cargando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Text('Crear cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
