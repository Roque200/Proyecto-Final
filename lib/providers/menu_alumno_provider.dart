import 'dart:async';

import 'package:flutter/material.dart';

import '../components/detector_agitar.dart';
import '../components/vibracion.dart';
import '../components/voz.dart';

class OpcionAlumno {
  final String titulo;
  final IconData icono;
  final String? ruta;

  const OpcionAlumno(this.titulo, this.icono, this.ruta);
}

class MenuAlumnoProvider extends ChangeNotifier {
  static const List<OpcionAlumno> opciones = [
    OpcionAlumno('Explorar figuras', Icons.pan_tool_alt, '/explorar'),
    OpcionAlumno('Retos', Icons.emoji_events, '/reto'),
    OpcionAlumno('Salir del modo alumno', Icons.logout, null),
  ];

  final DetectorAgitar _agitar = DetectorAgitar();
  Timer? _timerSalida;
  int _indice = 0;
  bool _confirmandoSalida = false;
  bool _cerrado = false;

  int get indice => _indice;
  OpcionAlumno get opcion => opciones[_indice];
  bool get confirmandoSalida => _confirmandoSalida;

  void iniciar() {
    _agitar.iniciar(repetir);
    Voz.decir(
      'Modo alumno. Desliza a la izquierda o a la derecha para cambiar de opción. '
      'Toca dos veces para entrar. Agita el celular para repetir. '
      '${_textoOpcion()}',
    );
  }

  String _textoOpcion() =>
      'Opción ${_indice + 1} de ${opciones.length}: ${opcion.titulo}.';

  void repetir() {
    if (_confirmandoSalida) {
      _pedirConfirmacion();
    } else {
      Voz.decir(_textoOpcion());
    }
  }

  void mover(int direccion) {
    if (_confirmandoSalida) {
      cancelarSalida();
      return;
    }
    _indice = (_indice + direccion) % opciones.length;
    if (_indice < 0) _indice += opciones.length;
    Vibracion.toque();
    notifyListeners();
    Voz.decir(_textoOpcion());
  }

  void activar(BuildContext context) {
    if (_confirmandoSalida) {
      _salir(context);
      return;
    }
    final ruta = opcion.ruta;
    if (ruta == null) {
      _pedirConfirmacion();
      return;
    }
    Vibracion.vertice();
    Voz.callar();
    _agitar.detener();
    Navigator.pushNamed(context, ruta).then((_) async {
      // Se espera a que termine la animación de regreso: al cerrarse,
      // la otra pantalla calla la voz y cortaría este mensaje.
      await Future.delayed(const Duration(milliseconds: 700));
      if (_cerrado) return;
      _agitar.iniciar(repetir);
      Voz.decir('Regresaste al menú. ${_textoOpcion()}');
    });
  }

  // ----------------------------------------------- Salida con 3 segundos

  void empezarPresion() {
    _timerSalida?.cancel();
    _timerSalida = Timer(const Duration(seconds: 3), _pedirConfirmacion);
  }

  void terminarPresion() {
    _timerSalida?.cancel();
  }

  void _pedirConfirmacion() {
    _confirmandoSalida = true;
    Vibracion.error();
    notifyListeners();
    Voz.decir(
      '¿Quieres salir del modo alumno? Toca dos veces para confirmar, '
      'o desliza para cancelar.',
    );
  }

  /// Lo llama el botón atrás de Android.
  void pedirSalida() => _pedirConfirmacion();

  void cancelarSalida() {
    _confirmandoSalida = false;
    notifyListeners();
    Voz.decir('Cancelado. ${_textoOpcion()}');
  }

  void _salir(BuildContext context) {
    _confirmandoSalida = false;
    _agitar.detener();
    Voz.decir('Saliendo del modo alumno');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cerrado = true;
    _timerSalida?.cancel();
    _agitar.detener();
    super.dispose();
  }
}
