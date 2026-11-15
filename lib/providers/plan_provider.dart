import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/stripe_config.dart';
import '../models/figura.dart';
import '../models/plan.dart';

enum ResultadoPago { aprobado, rechazado }

/// Plan de suscripción del tutor (Básico, Escolar o Institución).
///
/// Se guarda en Firestore, en el campo `plan` del documento usuarios/{uid}.
/// Así el plan se conserva aunque el tutor cambie de celular.
class PlanProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _subAuth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subDoc;

  String? _uid;
  int _planActual = 0;
  Plan? _seleccionado;
  bool _guardando = false;

  // Estado de la pantalla de pago
  CardFieldInputDetails? _tarjeta;
  bool _procesando = false;
  ResultadoPago? _resultado;
  String? _mensajePago;

  /// Sin internet, Firestore guarda el cambio para mandarlo después y el
  /// Future no termina; con este límite la pantalla no se queda cargando.
  static const Duration _espera = Duration(seconds: 10);

  PlanProvider() {
    _subAuth = FirebaseAuth.instance.authStateChanges().listen(_cambioDeUsuario);
  }

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _uid;
    return uid == null ? null : _db.collection('usuarios').doc(uid);
  }

  void _cambioDeUsuario(User? usuario) {
    if (usuario?.uid == _uid) return;
    _uid = usuario?.uid;
    _subDoc?.cancel();
    _planActual = 0;
    _seleccionado = null;
    notifyListeners();

    final doc = _doc;
    if (doc == null) return;
    _subDoc = doc.snapshots().listen((snap) {
      final nivel = (snap.data()?['plan'] as num?)?.toInt() ?? 0;
      _planActual = nivel.clamp(0, Plan.planes.length - 1);
      notifyListeners();
    }, onError: (Object e) => debugPrint('Plan: no se pudo leer ($e)'));
  }

  int get planActual => _planActual;
  Plan get plan => Plan.planes[_planActual];

  /// Plan de pago que el tutor eligió y que se muestra en la pantalla de pago.
  Plan? get seleccionado => _seleccionado;
  bool get guardando => _guardando;

  bool get tarjetaCompleta => _tarjeta?.complete ?? false;
  bool get procesando => _procesando;
  ResultadoPago? get resultado => _resultado;
  String? get mensajePago => _mensajePago;

  List<Figura> get figurasDisponibles =>
      Figura.catalogo.where((f) => f.planRequerido <= _planActual).toList();

  bool disponible(Figura f) => f.planRequerido <= _planActual;

  /// El plan gratuito se aplica directo; los de pago van a la pantalla de pago.
  Future<void> elegir(BuildContext context, Plan nuevo) async {
    if (nuevo.nivel == _planActual || _guardando) return;

    if (nuevo.precioMensual > 0) {
      _seleccionado = nuevo;
      _tarjeta = null;
      _resultado = null;
      _mensajePago = null;
      notifyListeners();
      Navigator.pushNamed(context, '/pago');
      return;
    }

    final ok = await guardarPlan(nuevo.nivel);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Cambiaste al plan ${nuevo.nombre}' : 'No se pudo cambiar el plan'),
      ),
    );
  }

  /// Escribe el plan en Firestore. El listener de snapshots actualiza
  /// _planActual, así toda la app (dashboard, lecciones) se refresca sola.
  Future<bool> guardarPlan(int nivel, {Map<String, Object>? datosPago}) async {
    final doc = _doc;
    if (doc == null) return false;
    _guardando = true;
    notifyListeners();
    try {
      await doc.set({
        'plan': nivel,
        'planActualizado': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_espera);
      if (datosPago != null) {
        // Historial de pagos en usuarios/{uid}/pagos.
        await doc.collection('pagos').add({
          ...datosPago,
          'fecha': FieldValue.serverTimestamp(),
        }).timeout(_espera);
      }
      return true;
    } catch (e) {
      debugPrint('Plan: no se pudo guardar ($e)');
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Pago

  /// El CardField de Stripe avisa cada vez que cambia la tarjeta. Solo
  /// recibimos si está completa y válida, y sus últimos 4 dígitos: el
  /// número completo nunca llega a nuestro código.
  void cambiarTarjeta(CardFieldInputDetails? detalles) {
    _tarjeta = detalles;
    notifyListeners();
  }

  void reintentar() {
    // El CardField se vuelve a crear vacío, así que la tarjeta anterior
    // ya no cuenta.
    _tarjeta = null;
    _resultado = null;
    _mensajePago = null;
    notifyListeners();
  }

  /// Stripe tokeniza la tarjeta y regresa un PaymentMethod (pm_...): un
  /// identificador seguro que representa la tarjeta sin exponer sus datos.
  ///
  /// Para cobrar de verdad se necesita un servidor con la clave secreta que
  /// cree un PaymentIntent; como el proyecto es sin backend, aquí el cobro
  /// se simula y se guarda el plan con los datos del PaymentMethod.
  Future<void> pagar({required String nombre, required String correo}) async {
    final plan = _seleccionado;
    if (plan == null || !tarjetaCompleta || _procesando) return;

    _procesando = true;
    _resultado = null;
    _mensajePago = null;
    notifyListeners();

    try {
      final metodo = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: nombre, email: correo),
          ),
        ),
      );

      // Simulación del rechazo del banco con la tarjeta de prueba ...0002.
      if (metodo.card.last4 == StripeConfig.terminacionRechazada) {
        _resultado = ResultadoPago.rechazado;
        _mensajePago = 'El banco rechazó la tarjeta. Revisa los datos o usa otra.';
        return;
      }

      final ok = await guardarPlan(plan.nivel, datosPago: {
        'plan': plan.nombre,
        'monto': plan.precioMensual,
        'moneda': 'MXN',
        'paymentMethodId': metodo.id,
        'marca': metodo.card.brand ?? '',
        'ultimos4': metodo.card.last4 ?? '',
        'modo': 'prueba',
      });
      _resultado = ok ? ResultadoPago.aprobado : ResultadoPago.rechazado;
      if (!ok) _mensajePago = 'El pago pasó, pero no se pudo guardar el plan. Revisa tu conexión.';
    } on StripeException catch (e) {
      _resultado = ResultadoPago.rechazado;
      _mensajePago = e.error.localizedMessage ?? 'No se pudo procesar la tarjeta.';
    } catch (_) {
      _resultado = ResultadoPago.rechazado;
      _mensajePago = 'No se pudo conectar con Stripe. Revisa tu conexión.';
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subAuth?.cancel();
    _subDoc?.cancel();
    super.dispose();
  }
}
