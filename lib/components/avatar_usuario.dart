import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Avatar del tutor. Se usa en dashboard, drawer y perfil,
/// así cualquier cambio de foto se ve en todos lados a la vez.
class AvatarUsuario extends StatelessWidget {
  final double radio;

  const AvatarUsuario({super.key, this.radio = 22});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final colores = Theme.of(context).colorScheme;
    final foto = usuario?.fotoUrl;

    // CachedNetworkImageProvider guarda la foto en el celular: la próxima vez
    // se muestra al instante y también funciona sin internet.
    return CircleAvatar(
      radius: radio,
      backgroundColor: colores.primaryContainer,
      foregroundColor: colores.onPrimaryContainer,
      backgroundImage: foto != null ? CachedNetworkImageProvider(foto) : null,
      child: foto == null
          ? Text(
              usuario?.iniciales ?? '?',
              style: TextStyle(fontSize: radio * 0.8, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}
