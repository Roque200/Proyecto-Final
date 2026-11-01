import 'dart:math' as math;
import 'dart:ui';

enum TipoElemento { vertice, lado, interior, fuera }

/// Lo que hay bajo el dedo del alumno.
class ElementoFigura {
  final TipoElemento tipo;
  final int indice;
  final String descripcion;

  const ElementoFigura(this.tipo, this.indice, this.descripcion);

  /// Sirve para no repetir la narración mientras el dedo sigue en el mismo lugar.
  String get clave => '${tipo.name}-$indice';
}

/// Figura geométrica en coordenadas normalizadas (0 a 1).
/// Los vértices se dibujan escalados al tamaño del área de exploración.
class Figura {
  final String id;
  final String nombre;
  final String articulo; // "el" o "la", para narrar bien
  final List<Offset> vertices;
  final bool esCirculo;
  final double radio; // solo para el círculo
  final double medidaCm; // medida de referencia que se narra
  final String descripcionMedida;
  final int planRequerido; // 0 Básico, 1 Escolar, 2 Institución

  const Figura({
    required this.id,
    required this.nombre,
    required this.articulo,
    this.vertices = const [],
    this.esCirculo = false,
    this.radio = 0,
    required this.medidaCm,
    required this.descripcionMedida,
    this.planRequerido = 0,
  });

  int get numLados => esCirculo ? 0 : vertices.length;
  int get numVertices => esCirculo ? 0 : vertices.length;

  static const double _tolVertice = 0.07;
  static const double _tolLado = 0.04;
  static const Offset _centro = Offset(0.5, 0.5);

  /// Recibe el punto ya normalizado y sin rotación.
  ElementoFigura elementoEn(Offset p) {
    if (esCirculo) {
      final d = (p - _centro).distance;
      if ((d - radio).abs() <= _tolLado) {
        return const ElementoFigura(
            TipoElemento.lado, 0, 'Estás sobre la orilla del círculo');
      }
      if (d < radio) {
        return const ElementoFigura(
            TipoElemento.interior, 0, 'Dentro del círculo');
      }
      return const ElementoFigura(TipoElemento.fuera, 0, 'Fuera de la figura');
    }

    for (var i = 0; i < vertices.length; i++) {
      if ((p - vertices[i]).distance <= _tolVertice) {
        return ElementoFigura(
            TipoElemento.vertice, i, 'Vértice ${_posicion(vertices[i])}');
      }
    }

    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      if (_distanciaASegmento(p, a, b) <= _tolLado) {
        return ElementoFigura(
            TipoElemento.lado, i, 'Lado ${i + 1} de ${vertices.length}');
      }
    }

    if (_dentro(p)) {
      return ElementoFigura(
          TipoElemento.interior, 0, 'Dentro $articuloDel $nombre');
    }
    return const ElementoFigura(TipoElemento.fuera, 0, 'Fuera de la figura');
  }

  String get articuloDel => articulo == 'el' ? 'del' : 'de la';

  /// Texto que se narra al mantener presionado.
  String get informacion {
    if (esCirculo) {
      final r = medidaCm;
      final perimetro = 2 * math.pi * r;
      final area = math.pi * r * r;
      return 'Es un círculo. No tiene lados ni vértices. '
          'Su radio mide ${_n(r)} centímetros. '
          'Su perímetro es de ${_n(perimetro)} centímetros '
          'y su área es de ${_n(area)} centímetros cuadrados.';
    }
    return 'Es $articulo $nombre. Tiene $numLados lados y $numVertices vértices. '
        '$descripcionMedida '
        'Su perímetro es de ${_n(perimetroCm)} centímetros '
        'y su área es de ${_n(areaCm)} centímetros cuadrados.';
  }

  double get perimetroCm {
    if (esCirculo) return 2 * math.pi * medidaCm;
    final escala = _escalaCm;
    var total = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      total += (vertices[(i + 1) % vertices.length] - vertices[i]).distance;
    }
    return total * escala;
  }

  double get areaCm {
    if (esCirculo) return math.pi * medidaCm * medidaCm;
    final escala = _escalaCm;
    var suma = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      suma += a.dx * b.dy - b.dx * a.dy;
    }
    return (suma.abs() / 2) * escala * escala;
  }

  /// La medida en cm corresponde al primer lado de la figura.
  double get _escalaCm {
    if (vertices.length < 2) return 1;
    final primerLado = (vertices[1] - vertices[0]).distance;
    return medidaCm / primerLado;
  }

  bool _dentro(Offset p) {
    var dentro = false;
    for (var i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final a = vertices[i];
      final b = vertices[j];
      final cruza = (a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx;
      if (cruza) dentro = !dentro;
    }
    return dentro;
  }

  static double _distanciaASegmento(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final largo2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (largo2 == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / largo2;
    t = t.clamp(0.0, 1.0);
    final proyeccion = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proyeccion).distance;
  }

  static String _posicion(Offset v) {
    final vertical = v.dy < 0.4
        ? 'superior'
        : v.dy > 0.6
            ? 'inferior'
            : '';
    final horizontal = v.dx < 0.4
        ? 'izquierdo'
        : v.dx > 0.6
            ? 'derecho'
            : '';
    if (vertical.isEmpty && horizontal.isEmpty) return 'central';
    return [vertical, horizontal].where((t) => t.isNotEmpty).join(' ');
  }

  static String _n(double valor) {
    final redondeado = (valor * 10).round() / 10;
    return redondeado == redondeado.roundToDouble()
        ? redondeado.toInt().toString()
        : redondeado.toStringAsFixed(1);
  }

  /// Catálogo del prototipo. Después se carga desde Firestore.
  static const List<Figura> catalogo = [
    Figura(
      id: 'cuadrado',
      nombre: 'cuadrado',
      articulo: 'el',
      vertices: [
        Offset(0.2, 0.2),
        Offset(0.8, 0.2),
        Offset(0.8, 0.8),
        Offset(0.2, 0.8),
      ],
      medidaCm: 5,
      descripcionMedida: 'Todos sus lados miden 5 centímetros.',
    ),
    Figura(
      id: 'triangulo',
      nombre: 'triángulo',
      articulo: 'el',
      vertices: [
        Offset(0.5, 0.15),
        Offset(0.85, 0.8),
        Offset(0.15, 0.8),
      ],
      medidaCm: 6,
      descripcionMedida: 'Es un triángulo isósceles: dos de sus lados son iguales.',
    ),
    Figura(
      id: 'rectangulo',
      nombre: 'rectángulo',
      articulo: 'el',
      vertices: [
        Offset(0.1, 0.3),
        Offset(0.9, 0.3),
        Offset(0.9, 0.7),
        Offset(0.1, 0.7),
      ],
      medidaCm: 8,
      descripcionMedida: 'Sus lados largos miden 8 centímetros y los cortos 4.',
    ),
    Figura(
      id: 'circulo',
      nombre: 'círculo',
      articulo: 'el',
      esCirculo: true,
      radio: 0.35,
      medidaCm: 3,
      descripcionMedida: '',
    ),
    Figura(
      id: 'rombo',
      nombre: 'rombo',
      articulo: 'el',
      vertices: [
        Offset(0.5, 0.12),
        Offset(0.85, 0.5),
        Offset(0.5, 0.88),
        Offset(0.15, 0.5),
      ],
      medidaCm: 5,
      descripcionMedida: 'Sus cuatro lados miden lo mismo, pero no tiene ángulos rectos.',
      planRequerido: 1,
    ),
    Figura(
      id: 'pentagono',
      nombre: 'pentágono',
      articulo: 'el',
      vertices: [
        Offset(0.5, 0.12),
        Offset(0.86, 0.38),
        Offset(0.72, 0.82),
        Offset(0.28, 0.82),
        Offset(0.14, 0.38),
      ],
      medidaCm: 4,
      descripcionMedida: 'Es un pentágono regular: todos sus lados miden 4 centímetros.',
      planRequerido: 1,
    ),
    Figura(
      id: 'hexagono',
      nombre: 'hexágono',
      articulo: 'el',
      vertices: [
        Offset(0.3, 0.15),
        Offset(0.7, 0.15),
        Offset(0.9, 0.5),
        Offset(0.7, 0.85),
        Offset(0.3, 0.85),
        Offset(0.1, 0.5),
      ],
      medidaCm: 4,
      descripcionMedida: 'Es un hexágono regular: todos sus lados miden 4 centímetros.',
      planRequerido: 2,
    ),
  ];

  static Figura porId(String id) =>
      catalogo.firstWhere((f) => f.id == id, orElse: () => catalogo.first);
}
