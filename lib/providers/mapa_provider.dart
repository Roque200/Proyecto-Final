import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/centro_apoyo.dart';

/// Estado de la pantalla del mapa: ubicación del tutor (GPS con geolocator)
/// y distancia a cada centro de apoyo.
class MapaProvider extends ChangeNotifier {
  /// Punto inicial del mapa (Celaya) mientras se obtiene la ubicación.
  static const LatLng inicio = LatLng(20.5235, -100.8157);

  GoogleMapController? _controlador;
  Position? _ubicacion;
  bool _buscando = false;
  bool _permisoConcedido = false;
  String? _aviso;
  bool _cerrado = false;

  Position? get ubicacion => _ubicacion;
  bool get buscando => _buscando;
  bool get permisoConcedido => _permisoConcedido;

  /// Mensaje para el tutor cuando no se puede usar el GPS.
  String? get aviso => _aviso;

  /// Centros ordenados del más cercano al más lejano (si hay ubicación).
  List<CentroApoyo> get centros {
    final lista = [...CentroApoyo.lista];
    if (_ubicacion != null) {
      lista.sort((a, b) => distanciaMetros(a)!.compareTo(distanciaMetros(b)!));
    }
    return lista;
  }

  /// Distancia en línea recta desde el tutor, o null si no hay ubicación.
  double? distanciaMetros(CentroApoyo c) {
    final u = _ubicacion;
    if (u == null) return null;
    return Geolocator.distanceBetween(u.latitude, u.longitude, c.latitud, c.longitud);
  }

  String? distanciaTexto(CentroApoyo c) {
    final m = distanciaMetros(c);
    if (m == null) return null;
    return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
  }

  void alCrearMapa(GoogleMapController controlador) {
    _controlador = controlador;
  }

  /// Pide permiso de ubicación y obtiene la posición actual del celular.
  Future<void> ubicarme() async {
    if (_buscando) return;
    _buscando = true;
    _aviso = null;
    _notificar();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _aviso = 'Activa la ubicación (GPS) del celular para ver los centros más cercanos.';
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        _aviso = 'Sin permiso de ubicación: se muestran los centros sin distancia.';
        return;
      }
      if (permiso == LocationPermission.deniedForever) {
        _aviso = 'La ubicación está bloqueada para Pulssó. Actívala en Ajustes del celular.';
        return;
      }

      _permisoConcedido = true;
      _ubicacion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));

      final u = _ubicacion!;
      await _controlador?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(u.latitude, u.longitude), 12),
      );
    } catch (e) {
      _aviso = 'No se pudo obtener tu ubicación. Intenta de nuevo.';
      debugPrint('Mapa: error de ubicación ($e)');
    } finally {
      _buscando = false;
      _notificar();
    }
  }

  /// Mueve el mapa al centro elegido y abre su globo de información.
  Future<void> irA(CentroApoyo c) async {
    final controlador = _controlador;
    if (controlador == null) return;
    await controlador.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(c.latitud, c.longitud), 15),
    );
    await controlador.showMarkerInfoWindow(MarkerId(c.id));
  }

  /// Evita llamar notifyListeners si el tutor ya salió de la pantalla
  /// mientras se esperaba al GPS.
  void _notificar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _controlador?.dispose();
    super.dispose();
  }
}
