import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto sin controller: el valor y el error viven en el provider.
class CampoTexto extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final ValueChanged<String> alCambiar;
  final String? error;
  final String? pista;
  final bool oculto;
  final Widget? sufijo;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatos;
  final int? maxLength;
  final String? valorInicial;

  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.alCambiar,
    this.error,
    this.pista,
    this.oculto = false,
    this.sufijo,
    this.teclado,
    this.formatos,
    this.maxLength,
    this.valorInicial,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: valorInicial,
        onChanged: alCambiar,
        obscureText: oculto,
        keyboardType: teclado,
        inputFormatters: formatos,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: etiqueta,
          hintText: pista,
          prefixIcon: Icon(icono),
          suffixIcon: sufijo,
          errorText: error,
          counterText: '',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
