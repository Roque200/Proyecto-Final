/// Un lugar de apoyo para niñas, niños y familias
/// (atención médica, asistencia social y actividades culturales).
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

  /// Centros de atención en Apaseo el Grande, Gto., que muestra el mapa.
  static const List<CentroApoyo> lista = [
    CentroApoyo(
      id: 'dif_apaseo',
      nombre: 'DIF Municipal Apaseo el Grande',
      direccion: 'Calle Morelos 542, Zona Centro, 38160 Apaseo el Grande, Gto.',
      telefono: '413 158 2483',
      latitud: 20.543879,
      longitud: -100.680268,
    ),
    CentroApoyo(
      id: 'caises_apaseo',
      nombre: 'CAISES Apaseo el Grande',
      direccion:
          'Calle La Adelita 105–137, Los Charros, 38164 Apaseo el Grande, Gto.',
      telefono: '413 688 2509',
      latitud: 20.545299,
      longitud: -100.679092,
    ),
    CentroApoyo(
      id: 'casa_cultura_apaseo',
      nombre: 'Casa de la Cultura Poeta Antonio Plaza',
      direccion:
          'Calle José María Morelos 308, Zona Centro, 38160 Apaseo el Grande, Gto.',
      telefono: 'Teléfono no disponible',
      latitud: 20.545948,
      longitud: -100.684698,
    ),
  ];
}
