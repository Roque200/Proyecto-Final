import 'package:flutter/material.dart';

import '../models/figura.dart';
import '../models/plan.dart';

enum ResultadoPago { aprobado, rechazado }

/// Planes y pago del prototipo (solo interfaz).
/// En la semana 3 el pago se manda a Stripe en modo prueba.
class PlanProvider extends ChangeNotifier {
  int _planActual = 0;
  Plan? _seleccionado;
  bool _procesando = false;
  ResultadoPago? _resultado;

  // Campos de la tarjeta
  String titular = '';
  String numero = '';
  String vencimiento = '';
  String cvc = '';
  final Map<String, String> _errores = {};

  int get planActual => _planActual;
  Plan get plan => Plan.planes[_planActual];
  Plan? get seleccionado => _seleccionado;
  bool get procesando => _procesando;
  ResultadoPago? get resultado => _resultado;
  String? error(String campo) => _errores[campo];

  List<Figura> get figurasDisponibles =>
      Figura.catalogo.where((f) => f.planRequerido <= _planActual).toList();

  bool disponible(Figura f) => f.planRequerido <= _planActual;

  void elegir(BuildContext context, Plan nuevo) {
    if (nuevo.nivel == _planActual) return;
    if (nuevo.precioMensual == 0) {
      _planActual = nuevo.nivel;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cambiaste al plan ${nuevo.nombre}')),
      );
      return;
    }
    _seleccionado = nuevo;
    _limpiarTarjeta();
    Navigator.pushNamed(context, '/pago');
  }

  void _limpiarTarjeta() {
    titular = '';
    numero = '';
    vencimiento = '';
    cvc = '';
    _errores.clear();
    _resultado = null;
    notifyListeners();
  }

  void reintentar() {
    _resultado = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- Validación

  bool _validar() {
    _errores.clear();
    final digitos = numero.replaceAll(' ', '');

    if (titular.trim().length < 3) {
      _errores['titular'] = 'Escribe el nombre como aparece en la tarjeta';
    }
    if (digitos.length != 16 || !_luhn(digitos)) {
      _errores['numero'] = 'Número de tarjeta no válido';
    }
    if (!_vencimientoValido(vencimiento)) {
      _errores['vencimiento'] = 'Fecha no válida';
    }
    if (!RegExp(r'^\d{3}$').hasMatch(cvc)) {
      _errores['cvc'] = '3 dígitos';
    }
    notifyListeners();
    return _errores.isEmpty;
  }

  static bool _luhn(String digitos) {
    var suma = 0;
    var doble = false;
    for (var i = digitos.length - 1; i >= 0; i--) {
      var d = int.parse(digitos[i]);
      if (doble) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      suma += d;
      doble = !doble;
    }
    return suma % 10 == 0;
  }

  static bool _vencimientoValido(String texto) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(texto);
    if (m == null) return false;
    final mes = int.parse(m.group(1)!);
    final anio = 2000 + int.parse(m.group(2)!);
    if (mes < 1 || mes > 12) return false;
    final ultimoDia = DateTime(anio, mes + 1, 0, 23, 59);
    return ultimoDia.isAfter(DateTime.now());
  }

  // ---------------------------------------------------------------- Pago

  /// Tarjetas de prueba de Stripe:
  /// 4242 4242 4242 4242 = aprobada, 4000 0000 0000 0002 = rechazada.
  Future<void> pagar() async {
    final plan = _seleccionado;
    if (plan == null || !_validar()) return;
    _procesando = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _procesando = false;
    final rechazada = numero.replaceAll(' ', '') == '4000000000000002';
    if (rechazada) {
      _resultado = ResultadoPago.rechazado;
    } else {
      _resultado = ResultadoPago.aprobado;
      _planActual = plan.nivel;
    }
    notifyListeners();
  }
}
