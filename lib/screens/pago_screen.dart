import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' show CardField;
import 'package:provider/provider.dart';

import '../components/responsivo.dart';
import '../providers/auth_provider.dart';
import '../providers/plan_provider.dart';

class PagoScreen extends StatelessWidget {
  const PagoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PlanProvider>();
    final plan = prov.seleccionado;

    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: SafeArea(
        child: plan == null
            ? const Center(child: Text('No hay un plan seleccionado'))
            : ContenidoCentrado(
                child: switch (prov.resultado) {
                  ResultadoPago.aprobado => _Resultado(
                    icono: Icons.check_circle,
                    titulo: 'Pago aprobado',
                    texto:
                        'Ya tienes el plan ${plan.nombre}. Las nuevas figuras ya están disponibles.',
                    boton: 'Volver al inicio',
                    alPresionar: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                  ),
                  ResultadoPago.rechazado => _Resultado(
                    icono: Icons.cancel,
                    titulo: 'Pago rechazado',
                    texto: prov.mensajePago ?? 'No se pudo completar el pago.',
                    boton: 'Intentar de nuevo',
                    error: true,
                    alPresionar: prov.reintentar,
                  ),
                  null => const _Formulario(),
                },
              ),
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PlanProvider>();
    final usuario = context.watch<AuthProvider>().usuario;
    final plan = prov.seleccionado!;
    final colores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: colores.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text('Plan ${plan.nombre}'),
            subtitle: const Text('Cobro mensual, cancela cuando quieras'),
            trailing: Text(
              plan.precioTexto,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Datos de la tarjeta',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        // CardField es un campo NATIVO de Stripe (Android/iOS): captura y
        // valida número, vencimiento y CVC. Los datos de la tarjeta se quedan
        // en el SDK de Stripe; nuestra app solo recibe si está completa.
        CardField(
          enablePostalCode: false,
          countryCode: 'MX',
          disabled: prov.procesando,
          onCardChanged: prov.cambiarTarjeta,
          // Sin "decoration": las versiones nuevas de flutter_stripe usan el
          // InputDecoration del paquete material_ui, no el de Flutter, y no
          // son compatibles. El CardField ya trae su propio estilo.
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.verified_user, size: 18, color: colores.primary),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('Pago seguro procesado por Stripe (modo de prueba)'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tarjeta de prueba: 4242 4242 4242 4242, cualquier fecha futura y cualquier CVC.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: !prov.tarjetaCompleta || prov.procesando
                ? null
                : () => prov.pagar(
                    nombre: usuario?.nombre ?? '',
                    correo: usuario?.correo ?? '',
                  ),
            child: prov.procesando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text('Pagar ${plan.precioTexto}'),
          ),
        ),
      ],
    );
  }
}

class _Resultado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  final String boton;
  final bool error;
  final VoidCallback alPresionar;

  const _Resultado({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.boton,
    required this.alPresionar,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icono, size: 110, color: error ? colores.error : colores.primary),
        const SizedBox(height: 16),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(texto, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: FilledButton(onPressed: alPresionar, child: Text(boton)),
        ),
      ],
    );
  }
}
