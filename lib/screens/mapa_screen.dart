import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../components/responsivo.dart';
import '../models/centro_apoyo.dart';
import '../providers/mapa_provider.dart';

/// Centros de apoyo en un mapa NATIVO de Google (Maps SDK de Android/iOS,
/// no un WebView), con la distancia desde la ubicación del tutor.
class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  void _detalle(BuildContext context, CentroApoyo c) {
    final distancia = context.read<MapaProvider>().distanciaTexto(c);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.nombre, style: Theme.of(hoja).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place),
                title: Text(c.direccion),
                subtitle: distancia == null ? null : Text('A $distancia de ti'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone),
                title: Text(c.telefono),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MapaProvider>();
    final ancho = Responsivo.esAncho(context);

    final marcadores = {
      for (final c in CentroApoyo.lista)
        Marker(
          markerId: MarkerId(c.id),
          position: LatLng(c.latitud, c.longitud),
          infoWindow: InfoWindow(
            title: c.nombre,
            snippet: prov.distanciaTexto(c) ?? c.direccion,
            onTap: () => _detalle(context, c),
          ),
        ),
    };

    final mapa = GoogleMap(
      initialCameraPosition: const CameraPosition(target: MapaProvider.inicio, zoom: 11),
      markers: marcadores,
      // El punto azul del tutor solo se activa cuando ya dio permiso.
      myLocationEnabled: prov.permisoConcedido,
      myLocationButtonEnabled: prov.permisoConcedido,
      onMapCreated: (controlador) {
        prov.alCrearMapa(controlador);
        prov.ubicarme();
      },
    );

    final lista = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prov.aviso != null)
          MaterialBanner(
            content: Text(prov.aviso!),
            leading: const Icon(Icons.location_off),
            actions: [
              TextButton(onPressed: prov.ubicarme, child: const Text('Reintentar')),
            ],
          ),
        if (prov.buscando) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: prov.centros.length,
            itemBuilder: (context, i) {
              final c = prov.centros[i];
              final distancia = prov.distanciaTexto(c);
              return ListTile(
                leading: CircleAvatar(
                  child: Text(i == 0 && distancia != null ? '★' : '${i + 1}'),
                ),
                title: Text(c.nombre),
                subtitle: Text(
                  distancia == null ? c.direccion : '${c.direccion} · $distancia',
                ),
                trailing: IconButton(
                  tooltip: 'Ver información',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _detalle(context, c),
                ),
                onTap: () => prov.irA(c),
              );
            },
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centros de apoyo'),
        actions: [
          IconButton(
            tooltip: 'Mi ubicación',
            icon: const Icon(Icons.my_location),
            onPressed: prov.buscando ? null : prov.ubicarme,
          ),
        ],
      ),
      // En tablet: mapa a la izquierda y lista a la derecha.
      body: ancho
          ? Row(
              children: [
                Expanded(flex: 3, child: mapa),
                Expanded(flex: 2, child: lista),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 3, child: mapa),
                Expanded(flex: 2, child: lista),
              ],
            ),
    );
  }
}
