import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgresoFigura {
  final bool explorada;
  final int aciertos;
  final int errores;
  final DateTime? ultimaPractica;

  const ProgresoFigura({
    this.explorada = false,
    this.aciertos = 0,
    this.errores = 0,
    this.ultimaPractica,
  });

  factory ProgresoFigura.deMapa(Map<String, dynamic> m) => ProgresoFigura(
        explorada: m['explorada'] as bool? ?? false,
        aciertos: (m['aciertos'] as num?)?.toInt() ?? 0,
        errores: (m['errores'] as num?)?.toInt() ?? 0,
        ultimaPractica: (m['ultimaPractica'] as Timestamp?)?.toDate(),
      );
}

/// Progreso del alumno guardado en Firestore, en
/// usuarios/{uid}/progreso/{figuraId}.
///
/// Firestore guarda una copia local: el progreso se ve y se registra aunque
/// no haya internet, y se sincroniza solo cuando vuelve la conexión.
class ProgresoProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _subAuth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subDatos;

  final Map<String, ProgresoFigura> _datos = {};
  final Map<String, DateTime> _ultimaEscritura = {};
  String? _uid;

  ProgresoProvider() {
    // Cada tutor ve solo el progreso de su cuenta.
    _subAuth = FirebaseAuth.instance.authStateChanges().listen(_cambioDeUsuario);
  }

  CollectionReference<Map<String, dynamic>>? get _coleccion {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('usuarios').doc(uid).collection('progreso');
  }

  void _cambioDeUsuario(User? usuario) {
    if (usuario?.uid == _uid) return;
    _uid = usuario?.uid;
    _subDatos?.cancel();
    _datos.clear();
    _ultimaEscritura.clear();
    notifyListeners();

    final coleccion = _coleccion;
    if (coleccion == null) return;
    // snapshots() avisa en tiempo real cada vez que cambia algún documento.
    _subDatos = coleccion.snapshots().listen((snap) {
      _datos.clear();
      for (final doc in snap.docs) {
        _datos[doc.id] = ProgresoFigura.deMapa(doc.data());
      }
      notifyListeners();
    }, onError: (Object e) => debugPrint('Progreso: no se pudo leer ($e)'));
  }

  ProgresoFigura de(String figuraId) => _datos[figuraId] ?? const ProgresoFigura();

  int get figurasExploradas => _datos.values.where((p) => p.explorada).length;
  int get totalAciertos => _datos.values.fold(0, (s, p) => s + p.aciertos);
  int get totalErrores => _datos.values.fold(0, (s, p) => s + p.errores);
  int get retosResueltos => totalAciertos + totalErrores;

  /// Se llama cada vez que el dedo entra a un lado o vértice. Para no escribir
  /// en Firestore a cada rato, si la figura ya estaba explorada solo se
  /// actualiza la fecha una vez por minuto.
  void marcarExplorada(String figuraId) {
    final ahora = DateTime.now();
    final ultima = _ultimaEscritura[figuraId];
    if (de(figuraId).explorada &&
        ultima != null &&
        ahora.difference(ultima) < const Duration(minutes: 1)) {
      return;
    }
    _ultimaEscritura[figuraId] = ahora;
    _guardar(figuraId, {
      'explorada': true,
      'ultimaPractica': FieldValue.serverTimestamp(),
    });
  }

  void registrarReto(String figuraId, bool correcto) {
    _guardar(figuraId, {
      // increment suma en el servidor: no se pierden aciertos aunque se
      // registren desde dos celulares al mismo tiempo.
      correcto ? 'aciertos' : 'errores': FieldValue.increment(1),
      'ultimaPractica': FieldValue.serverTimestamp(),
    });
  }

  void _guardar(String figuraId, Map<String, Object> cambios) {
    final coleccion = _coleccion;
    if (coleccion == null) return;
    // merge: true solo cambia esos campos y deja los demás como estaban.
    coleccion
        .doc(figuraId)
        .set(cambios, SetOptions(merge: true))
        .catchError((Object e) => debugPrint('Progreso: no se pudo guardar ($e)'));
  }

  @override
  void dispose() {
    _subAuth?.cancel();
    _subDatos?.cancel();
    super.dispose();
  }
}
