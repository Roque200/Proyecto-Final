import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/figura.dart';
import '../models/plan.dart';

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

  List<Figura> get figurasDisponibles =>
      Figura.catalogo.where((f) => f.planRequerido <= _planActual).toList();

  bool disponible(Figura f) => f.planRequerido <= _planActual;

  /// El plan gratuito se aplica directo; los de pago van a la pantalla de pago.
  Future<void> elegir(BuildContext context, Plan nuevo) async {
    if (nuevo.nivel == _planActual || _guardando) return;

    if (nuevo.precioMensual > 0) {
      _seleccionado = nuevo;
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

  @override
  void dispose() {
    _subAuth?.cancel();
    _subDoc?.cancel();
    super.dispose();
  }
}
