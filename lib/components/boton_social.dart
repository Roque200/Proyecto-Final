import 'package:flutter/material.dart';

class BotonSocial extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback? alPresionar;

  const BotonSocial({
    super.key,
    required this.texto,
    required this.icono,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          icon: Icon(icono, size: 26),
          label: Text(texto),
          onPressed: alPresionar,
        ),
      ),
    );
  }
}
