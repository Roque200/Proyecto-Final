/// Un lugar de apoyo para niñas y niños con discapacidad visual
/// (escuelas de educación especial, centros de rehabilitación, etc.).
class CentroApoyo {
  final String id;
  final String nombre;
  final String direccion;
  final String telefono;
  final double latitud;
  final double longitud;

  const CentroApoyo({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.latitud,
    required this.longitud,
  });

  /// Lista de centros que muestra el mapa.
  ///
  /// IMPORTANTE: son datos de EJEMPLO. Antes de la entrega reemplázalos por
  /// centros reales: en Google Maps mantén presionado el lugar y copia las
  /// coordenadas (latitud, longitud) que aparecen arriba.
  static const List<CentroApoyo> lista = [
    CentroApoyo(
      id: 'celaya_centro',
      nombre: 'Centro de apoyo visual Celaya (ejemplo)',
      direccion: 'Zona Centro, Celaya, Gto.',
      telefono: '461 000 0000',
      latitud: 20.5235,
      longitud: -100.8157,
    ),
    CentroApoyo(
      id: 'celaya_norte',
      nombre: 'Escuela de educación especial (ejemplo)',
      direccion: 'Celaya, Gto.',
      telefono: '461 000 0001',
      latitud: 20.5480,
      longitud: -100.8090,
    ),
    CentroApoyo(
      id: 'apaseo',
      nombre: 'Unidad de rehabilitación Apaseo el Grande (ejemplo)',
      direccion: 'Apaseo el Grande, Gto.',
      telefono: '413 000 0000',
      latitud: 20.5464,
      longitud: -100.6847,
    ),
  ];
}
