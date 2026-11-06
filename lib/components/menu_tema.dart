import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tema_provider.dart';

/// Menú circular para cambiar el tema. [contenido] es la pantalla
/// que va detrás del menú (backgroundWidget del paquete).
class MenuTema extends StatelessWidget {
  final Widget contenido;

  const MenuTema({super.key, required this.contenido});

  @override
  Widget build(BuildContext context) {
    final tema = context.read<TemaProvider>();
    final colores = Theme.of(context).colorScheme;

    return CircularMenu(
      alignment: Alignment.bottomRight,
      radius: 90,
      toggleButtonColor: colores.primary,
      toggleButtonIconColor: colores.onPrimary,
      toggleButtonSize: 32,
      backgroundWidget: contenido,
      items: [
        CircularMenuItem(
          icon: Icons.light_mode,
          color: Colors.amber.shade600,
          iconColor: Colors.black,
          onTap: () => tema.cambiar(ModoTema.claro),
        ),
        CircularMenuItem(
          icon: Icons.dark_mode,
          color: Colors.indigo.shade700,
          iconColor: Colors.white,
          onTap: () => tema.cambiar(ModoTema.oscuro),
        ),
        CircularMenuItem(
          icon: Icons.contrast,
          color: Colors.black,
          iconColor: const Color(0xFFFFEB3B),
          onTap: () => tema.cambiar(ModoTema.contraste),
        ),
      ],
    );
  }
}
