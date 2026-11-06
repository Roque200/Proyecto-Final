import 'package:flutter/material.dart';

class Responsivo {
  /// Tablet en horizontal o escritorio.
  static bool esAncho(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 800;
}

/// Centra el contenido y limita su ancho en pantallas grandes
/// (formularios de login, registro, pago, etc.).
class ContenidoCentrado extends StatelessWidget {
  final Widget child;
  final double anchoMaximo;

  const ContenidoCentrado({super.key, required this.child, this.anchoMaximo = 480});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: anchoMaximo),
          child: child,
        ),
      ),
    );
  }
}
