import 'dart:async';

import 'package:flutter/material.dart';

import '../components/detector_agitar.dart';
import '../components/explorador_tactil.dart';
import '../components/vibracion.dart';
import '../components/voz.dart';
import '../models/figura.dart';

class Pregunta {
  final Figura figura;
  final String texto;
  final int respuesta;
  final String unidad; // "vértices" o "lados"

  const Pregunta(this.figura, this.texto, this.respuesta, this.unidad);
}

enum EstadoReto { respondiendo, resultado, terminado }

class RetoProvider extends ChangeNotifier {
  final void Function(String figuraId, bool correcto) alResponder;
  final List<Pregunta> preguntas;

  final ExploradorTactil _explorador = ExploradorTactil();
  final DetectorAgitar _agitar = DetectorAgitar();
  Timer? _timerRespuesta;
  Timer? _timerSiguiente;

  int _indice = 0;
  int _toques = 0;
  int _aciertos = 0;
  bool? _ultimaCorrecta;
  EstadoReto _estado = EstadoReto.respondiendo;
  Offset? _dedo;

  RetoProvider({required List<Figura> figuras, required this.alResponder})
      : preguntas = _crearPreguntas(figuras);

  static List<Pregunta> _crearPreguntas(List<Figura> figuras) {
    final lista = <Pregunta>[];
    var porVertices = true;
    for (final f in figuras.where((f) => !f.esCirculo)) {
      lista.add(porVertices
          ? Pregunta(f, '¿Cuántos vértices tiene ${f.articulo} ${f.nombre}?', f.numVertices, 'vértices')
          : Pregunta(f, '¿Cuántos lados tiene ${f.articulo} ${f.nombre}?', f.numLados, 'lados'));
      porVertices = !porVertices;
    }
    return lista;
  }

  Pregunta get pregunta => preguntas[_indice];
  int get indice => _indice;
  int get toques => _toques;
  int get aciertos => _aciertos;
  bool? get ultimaCorrecta => _ultimaCorrecta;
  EstadoReto get estado => _estado;
  Offset? get dedo => _dedo;
  ElementoFigura? get resaltado => _explorador.elemento;

  void iniciar() {
    _agitar.iniciar(repetir);
    Voz.decir(
      'Retos. La figura está en la parte de arriba: explórala con el dedo. '
      'Para responder, toca la parte de abajo tantas veces como la respuesta. '
      'Agita el celular para repetir la pregunta. '
      'Pregunta 1 de ${preguntas.length}. ${pregunta.texto}',
    );
  }

  void repetir() {
    if (_estado == EstadoReto.terminado) {
      _decirFinal();
      return;
    }
    Voz.decir('Pregunta ${_indice + 1} de ${preguntas.length}. ${pregunta.texto}');
  }

  // ------------------------------------------------------ Explorar la figura

  void tocarFigura(Offset local, Size area) {
    if (_estado != EstadoReto.respondiendo) return;
    _dedo = local;
    _explorador.tocar(
      pregunta.figura,
      Offset(local.dx / area.width, local.dy / area.height),
    );
    notifyListeners();
  }

  void soltarFigura() {
    _dedo = null;
    _explorador.soltar();
    notifyListeners();
  }

  // ------------------------------------------------------ Responder

  void tocarRespuesta() {
    if (_estado == EstadoReto.terminado) {
      _reiniciar();
      return;
    }
    if (_estado != EstadoReto.respondiendo) return;
    _toques++;
    Vibracion.toque();
    Voz.decir('$_toques');
    notifyListeners();
    // Si deja de tocar 2 segundos, se toma como su respuesta.
    _timerRespuesta?.cancel();
    _timerRespuesta = Timer(const Duration(seconds: 2), _evaluar);
  }

  void _evaluar() {
    final p = pregunta;
    final correcta = _toques == p.respuesta;
    _ultimaCorrecta = correcta;
    _estado = EstadoReto.resultado;
    if (correcta) _aciertos++;
    alResponder(p.figura.id, correcta);
    notifyListeners();

    if (correcta) {
      Vibracion.acierto();
      Voz.decir('¡Correcto! ${p.figura.articulo} ${p.figura.nombre} tiene ${p.respuesta} ${p.unidad}.');
    } else {
      Vibracion.error();
      final veces = _toques == 1 ? 'una vez' : '$_toques veces';
      Voz.decir('Casi. Tocaste $veces, pero ${p.figura.articulo} ${p.figura.nombre} '
          'tiene ${p.respuesta} ${p.unidad}.');
    }
    _timerSiguiente?.cancel();
    _timerSiguiente = Timer(const Duration(seconds: 5), _siguiente);
  }

  void _siguiente() {
    _toques = 0;
    _ultimaCorrecta = null;
    soltarFigura();
    if (_indice + 1 >= preguntas.length) {
      _estado = EstadoReto.terminado;
      notifyListeners();
      _decirFinal();
      return;
    }
    _indice++;
    _estado = EstadoReto.respondiendo;
    notifyListeners();
    repetir();
  }

  void _decirFinal() {
    Voz.decir('Terminaste los retos. Acertaste $_aciertos de ${preguntas.length}. '
        'Toca la parte de abajo para empezar otra vez, o usa el botón atrás para regresar.');
  }

  void _reiniciar() {
    _indice = 0;
    _aciertos = 0;
    _toques = 0;
    _estado = EstadoReto.respondiendo;
    notifyListeners();
    repetir();
  }

  @override
  void dispose() {
    _explorador.cancelar();
    _timerRespuesta?.cancel();
    _timerSiguiente?.cancel();
    _agitar.detener();
    Voz.callar();
    super.dispose();
  }
}
