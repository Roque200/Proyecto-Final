import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/campo_texto.dart';
import '../components/responsivo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ContenidoCentrado(
          key: ValueKey(auth.versionFormulario),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.change_history, size: 90, color: colores.primary),
              const SizedBox(height: 8),
              Text(
                'Pulssó',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Acceso para tutores',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
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
                oculto: auth.ocultarPassword,
                error: auth.error('password'),
                alCambiar: (v) => auth.password = v,
                sufijo: IconButton(
                  tooltip: auth.ocultarPassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(auth.ocultarPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: auth.alternarPassword,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.cargando
                      ? null
                      : () {
                          auth.limpiarFormulario();
                          Navigator.pushNamed(context, '/recuperar')
                              .then((_) => auth.limpiarFormulario());
                        },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: auth.cargando ? null : () => auth.entrarConCorreo(context),
                  child: auth.cargando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Text('Entrar'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta?'),
                  TextButton(
                    onPressed: auth.cargando
                        ? null
                        : () {
                            auth.limpiarFormulario();
                            Navigator.pushNamed(context, '/registro')
                                .then((_) => auth.limpiarFormulario());
                          },
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
