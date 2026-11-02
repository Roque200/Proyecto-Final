import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../components/detector_agitar.dart';
import '../components/explorador_tactil.dart';
import '../components/vibracion.dart';
import '../components/voz.dart';
import '../models/figura.dart';

class ExplorarProvider extends ChangeNotifier {
  final List<Figura> figuras;
  final void Function(String figuraId) alExplorar;

  final ExploradorTactil _explorador = ExploradorTactil();
  final DetectorAgitar _agitar = DetectorAgitar();
  StreamSubscription<GyroscopeEvent>? _giro;

  int _indice = 0;
  double _rotacion = 0;
  int _cuartoAnterior = 0;
  Offset? _dedo;
  double _arrastreDosDedos = 0;

  ExplorarProvider({
    required this.figuras,
    required this.alExplorar,
    String? figuraInicial,
  }) {
    final i = figuras.indexWhere((f) => f.id == figuraInicial);
    _indice = i < 0 ? 0 : i;
  }

  Figura get figura => figuras[_indice];
  int get indice => _indice;
  double get rotacion => _rotacion;
  Offset? get dedo => _dedo;
  ElementoFigura? get resaltado => _explorador.elemento;

  void iniciar() {
    _agitar.iniciar(instrucciones);
    _giro = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen(_alGirar, onError: (_) {});
    instrucciones();
  }

  void instrucciones() {
    Voz.decir(
      'Figura ${_indice + 1} de ${figuras.length}: ${figura.nombre}. '
      'Desliza un dedo para sentirla. Mantén presionado para escuchar su información. '
      'Desliza con dos dedos para cambiar de figura. Gira el celular para rotarla. '
      'Para regresar, usa el botón atrás.',
    );
  }

  // ------------------------------------------------------------ Giroscopio

  void _alGirar(GyroscopeEvent e) {
    // z = giro del celular sobre la mesa; se ignora el ruido pequeño.
    if (e.z.abs() < 0.3) return;
    const dt = 1 / 15; // uiInterval ≈ 66 ms
    _rotacion -= e.z * dt;

    // Avisa con una vibración cada vez que pasa un cuarto de vuelta.
    final cuarto = (_rotacion / (math.pi / 2)).floor();
    if (cuarto != _cuartoAnterior) {
      _cuartoAnterior = cuarto;
      Vibracion.toque();
    }
    notifyListeners();
  }

  void reiniciarRotacion() {
    _rotacion = 0;
    _cuartoAnterior = 0;
    notifyListeners();
    Voz.decir('La figura regresó a su posición original');
  }

  // ------------------------------------------------------------ Toques

  void tocar(Offset local, Size area) {
    _dedo = local;
    final centro = Offset(area.width / 2, area.height / 2);
    // Se deshace la rotación para comparar contra la figura original.
    final rel = local - centro;
    final cos = math.cos(-_rotacion);
    final sin = math.sin(-_rotacion);
    final sinRotar = Offset(rel.dx * cos - rel.dy * sin, rel.dx * sin + rel.dy * cos) + centro;
    final p = Offset(sinRotar.dx / area.width, sinRotar.dy / area.height);

    if (_explorador.tocar(figura, p)) {
      alExplorar(figura.id);
    }
    notifyListeners();
  }

  void soltar() {
    _dedo = null;
    _explorador.soltar();
    notifyListeners();
  }

  void informacion() {
    Vibracion.toque();
    Voz.decir(figura.informacion);
  }

  void arrastreDosDedos(double dx) {
    _arrastreDosDedos += dx;
  }

  void terminarArrastre() {
    if (_arrastreDosDedos.abs() > 80) {
      cambiar(_arrastreDosDedos < 0 ? 1 : -1);
    }
    _arrastreDosDedos = 0;
  }

  void cambiar(int direccion) {
    _indice = (_indice + direccion) % figuras.length;
    if (_indice < 0) _indice += figuras.length;
    _rotacion = 0;
    _cuartoAnterior = 0;
    soltar();
    Vibracion.vertice();
    instrucciones();
  }

  @override
  void dispose() {
    _giro?.cancel();
    _agitar.detener();
    Voz.callar();
    super.dispose();
  }
}
