import 'package:flutter/material.dart';

import '../models/figura.dart';

/// Dibuja la figura para quien tenga baja visión y para el tutor.
/// El alumno invidente la "siente" con la vibración, no con el dibujo.
class FiguraPainter extends CustomPainter {
  final Figura figura;
  final double rotacion;
  final Offset? dedo; // posición local del dedo, para marcarla
  final ElementoFigura? resaltado;
  final Color colorLinea;
  final Color colorRelleno;
  final Color colorResaltado;

  FiguraPainter({
    required this.figura,
    required this.colorLinea,
    required this.colorRelleno,
    required this.colorResaltado,
    this.rotacion = 0,
    this.dedo,
    this.resaltado,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grosor = size.shortestSide * 0.03;
    final linea = Paint()
      ..color = colorLinea
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeJoin = StrokeJoin.round;
    final relleno = Paint()
      ..color = colorRelleno
      ..style = PaintingStyle.fill;
    final marca = Paint()
      ..color = colorResaltado
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor * 1.6
      ..strokeCap = StrokeCap.round;

    canvas.save();
    final centro = Offset(size.width / 2, size.height / 2);
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(rotacion);
    canvas.translate(-centro.dx, -centro.dy);

    Offset escalar(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    if (figura.esCirculo) {
      final r = figura.radio * size.shortestSide;
      canvas.drawCircle(centro, r, relleno);
      canvas.drawCircle(
        centro,
        r,
        resaltado?.tipo == TipoElemento.lado ? marca : linea,
      );
    } else {
      final puntos = figura.vertices.map(escalar).toList();
      final ruta = Path()..addPolygon(puntos, true);
      canvas.drawPath(ruta, relleno);
      canvas.drawPath(ruta, linea);

      final r = resaltado;
      if (r != null && r.tipo == TipoElemento.lado) {
        final a = puntos[r.indice];
        final b = puntos[(r.indice + 1) % puntos.length];
        canvas.drawLine(a, b, marca);
      }

      for (var i = 0; i < puntos.length; i++) {
        final activo = r?.tipo == TipoElemento.vertice && r?.indice == i;
        canvas.drawCircle(
          puntos[i],
          grosor * (activo ? 2.4 : 1.4),
          Paint()..color = activo ? colorResaltado : colorLinea,
        );
      }
    }
    canvas.restore();

    final d = dedo;
    if (d != null) {
      canvas.drawCircle(
        d,
        grosor * 2.2,
        Paint()..color = colorResaltado.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(FiguraPainter old) =>
      old.figura != figura ||
      old.rotacion != rotacion ||
      old.dedo != dedo ||
      old.resaltado?.clave != resaltado?.clave ||
      old.colorLinea != colorLinea;
}
