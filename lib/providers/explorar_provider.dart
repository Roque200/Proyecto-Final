import 'package:flutter/material.dart';

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

  int _indice = 0;
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
  Offset? get dedo => _dedo;
  ElementoFigura? get resaltado => _explorador.elemento;

  void iniciar() {
    _agitar.iniciar(instrucciones);
    instrucciones();
  }

  void instrucciones() {
    Voz.decir(
      'Figura ${_indice + 1} de ${figuras.length}: ${figura.nombre}. '
      'Desliza un dedo para sentirla. Mantén presionado para escuchar su información. '
      'Desliza con dos dedos para cambiar de figura. '
      'Toca dos veces o agita el celular para repetir estas instrucciones. '
      'Para regresar, usa el botón atrás.',
    );
  }

  // ------------------------------------------------------------ Toques

  void tocar(Offset local, Size area) {
    _dedo = local;
    final p = Offset(local.dx / area.width, local.dy / area.height);

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
    soltar();
    Vibracion.vertice();
    instrucciones();
  }

  @override
  void dispose() {
    _explorador.cancelar();
    _agitar.detener();
    Voz.callar();
    super.dispose();
  }
}
