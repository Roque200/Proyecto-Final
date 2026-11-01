class Plan {
  final int nivel;
  final String nombre;
  final double precioMensual;
  final List<String> incluye;

  const Plan({
    required this.nivel,
    required this.nombre,
    required this.precioMensual,
    required this.incluye,
  });

  String get precioTexto =>
      precioMensual == 0 ? 'Gratis' : '\$${precioMensual.toStringAsFixed(0)} MXN / mes';

  static const List<Plan> planes = [
    Plan(
      nivel: 0,
      nombre: 'Básico',
      precioMensual: 0,
      incluye: ['Cuadrado, triángulo, rectángulo y círculo', 'Retos de vértices', '1 alumno'],
    ),
    Plan(
      nivel: 1,
      nombre: 'Escolar',
      precioMensual: 79,
      incluye: ['Todo lo del plan Básico', 'Rombo y pentágono', 'Historial de progreso', '1 alumno'],
    ),
    Plan(
      nivel: 2,
      nombre: 'Institución',
      precioMensual: 249,
      incluye: ['Todas las figuras', 'Hasta 30 alumnos por maestro', 'Reportes por grupo'],
    ),
  ];
}
