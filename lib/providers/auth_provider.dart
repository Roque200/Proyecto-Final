import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

enum Proveedor { correo, google, github }

/// Datos del tutor que usa la interfaz, sacados del User de Firebase.
class Usuario {
  final String nombre;
  final String correo;
  final Proveedor proveedor;
  final String? fotoUrl;
  final bool verificado;

  const Usuario({
    required this.nombre,
    required this.correo,
    required this.proveedor,
    this.fotoUrl,
    this.verificado = false,
  });

  factory Usuario.deFirebase(User u) {
    final ids = u.providerData.map((p) => p.providerId).toSet();
    final proveedor = ids.contains('google.com')
        ? Proveedor.google
        : ids.contains('github.com')
            ? Proveedor.github
            : Proveedor.correo;
    final correo = u.email ?? '';
    final nombre = (u.displayName?.trim().isNotEmpty ?? false)
        ? u.displayName!.trim()
        : correo.split('@').first;
    return Usuario(
      nombre: nombre,
      correo: correo,
      proveedor: proveedor,
      fotoUrl: u.photoURL,
      verificado: u.emailVerified,
    );
  }

  bool get puedeEditarFoto => proveedor == Proveedor.correo;

  /// Google y GitHub ya verifican el correo; solo las cuentas de correo
  /// tienen que confirmar el enlace antes de entrar.
  bool get necesitaVerificar => proveedor == Proveedor.correo && !verificado;

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    final primera = partes.first[0];
    final segunda = partes.length > 1 ? partes[1][0] : '';
    return (primera + segunda).toUpperCase();
  }

  String get nombreProveedor => switch (proveedor) {
        Proveedor.correo => 'Correo y contraseña',
        Proveedor.google => 'Google',
        Proveedor.github => 'GitHub',
      };
}

/// Autenticación del tutor con Firebase Auth.
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _sub;

  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _correoRecuperacionEnviado = false;
  bool _googleListo = false;
  int _segundosReenvio = 0;
  Timer? _timer;

  // Campos de los formularios
  String nombre = '';
  String correo = '';
  String password = '';
  String confirmar = '';
  final Map<String, String> _errores = {};

  AuthProvider() {
    // Los correos de verificación y recuperación llegan en español.
    _auth.setLanguageCode('es');
    // userChanges avisa al iniciar o cerrar sesión y también cuando cambia
    // el perfil (nombre, foto o verificación del correo).
    _sub = _auth.userChanges().listen((_) => notifyListeners());
  }

  /// Ruta con la que debe arrancar la app según la sesión guardada.
  static String rutaInicial() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return '/login';
    return Usuario.deFirebase(u).necesitaVerificar ? '/verificar' : '/';
  }

  Usuario? get usuario {
    final u = _auth.currentUser;
    return u == null ? null : Usuario.deFirebase(u);
  }

  bool get cargando => _cargando;
  bool get ocultarPassword => _ocultarPassword;
  bool get correoRecuperacionEnviado => _correoRecuperacionEnviado;
  int get segundosReenvio => _segundosReenvio;
  bool get puedeReenviar => _segundosReenvio == 0;
  String? error(String campo) => _errores[campo];

  /// Cambia cada vez que se limpia el formulario; las pantallas la usan como
  /// key para que los campos de texto se vuelvan a crear vacíos.
  int get versionFormulario => _versionFormulario;
  int _versionFormulario = 0;

  void alternarPassword() {
    _ocultarPassword = !_ocultarPassword;
    notifyListeners();
  }

  void limpiarFormulario() {
    _versionFormulario++;
    nombre = '';
    correo = '';
    password = '';
    confirmar = '';
    _errores.clear();
    _ocultarPassword = true;
    _correoRecuperacionEnviado = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------- Validación

  static final _regexCorreo = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  bool _validar({bool conNombre = false, bool conPassword = true, bool conConfirmar = false}) {
    _errores.clear();
    if (conNombre && nombre.trim().length < 3) {
      _errores['nombre'] = 'Escribe tu nombre completo';
    }
    if (!_regexCorreo.hasMatch(correo.trim())) {
      _errores['correo'] = 'Escribe un correo válido';
    }
    if (conPassword && password.length < 6) {
      _errores['password'] = 'Mínimo 6 caracteres';
    }
    if (conConfirmar && confirmar != password) {
      _errores['confirmar'] = 'Las contraseñas no coinciden';
    }
    notifyListeners();
    return _errores.isEmpty;
  }

  /// Ejecuta una llamada a Firebase con indicador de carga y manejo de errores.
  Future<bool> _ejecutar(BuildContext context, Future<void> Function() accion) async {
    _cargando = true;
    notifyListeners();
    try {
      await accion();
      return true;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) _mostrar(context, _mensaje(e.code));
      return false;
    } on GoogleSignInException catch (e) {
      // Si el tutor cerró la ventana de Google no es un error: no se avisa nada.
      if (e.code != GoogleSignInExceptionCode.canceled && context.mounted) {
        _mostrar(context, 'No se pudo entrar con Google');
      }
      return false;
    } catch (_) {
      if (context.mounted) _mostrar(context, 'Algo salió mal. Intenta de nuevo.');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  static String _mensaje(String codigo) => switch (codigo) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Correo o contraseña incorrectos',
        'invalid-email' => 'El correo no es válido',
        'user-disabled' => 'Esta cuenta fue deshabilitada',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo',
        'weak-password' => 'La contraseña es muy débil',
        'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
        'account-exists-with-different-credential' =>
          'Ese correo ya está registrado con otro método de acceso',
        'web-context-canceled' || 'canceled' => 'Se canceló el inicio de sesión',
        'network-request-failed' => 'Sin conexión a internet',
        _ => 'No se pudo completar ($codigo)',
      };

  static void _mostrar(BuildContext context, String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ---------------------------------------------------------------- Acciones

  Future<void> entrarConCorreo(BuildContext context) async {
    if (!_validar()) return;
    final ok = await _ejecutar(context, () async {
      await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );
    });
    if (ok && context.mounted) _irDespuesDeEntrar(context);
  }

  /// Inicializa Google Sign-In una sola vez. En iOS necesita el client ID,
  /// que viene en firebase_options.dart; en Android lo toma solo del
  /// google-services.json.
  Future<void> _iniciarGoogle() async {
    if (_googleListo) return;
    await GoogleSignIn.instance.initialize(
      clientId: Platform.isIOS ? DefaultFirebaseOptions.currentPlatform.iosClientId : null,
    );
    _googleListo = true;
  }

  /// Google da un idToken; con él se crea la credencial de Firebase.
  Future<void> entrarConGoogle(BuildContext context) async {
    final ok = await _ejecutar(context, () async {
      await _iniciarGoogle();
      final cuenta = await GoogleSignIn.instance.authenticate();
      final credencial = GoogleAuthProvider.credential(
        idToken: cuenta.authentication.idToken,
      );
      await _auth.signInWithCredential(credencial);
    });
    if (ok && context.mounted) _irDespuesDeEntrar(context);
  }

  /// GitHub no necesita paquete extra: Firebase abre la página de GitHub
  /// en el navegador y regresa a la app con la sesión iniciada.
  Future<void> entrarConGithub(BuildContext context) async {
    final ok = await _ejecutar(context, () async {
      final github = GithubAuthProvider()..addScope('read:user')..addScope('user:email');
      await _auth.signInWithProvider(github);
    });
    if (ok && context.mounted) _irDespuesDeEntrar(context);
  }

  Future<void> registrar(BuildContext context) async {
    if (!_validar(conNombre: true, conConfirmar: true)) return;
    final ok = await _ejecutar(context, () async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(nombre.trim());
      await cred.user!.sendEmailVerification();
    });
    if (!ok || !context.mounted) return;
    _iniciarCuentaRegresiva();
    Navigator.pushNamedAndRemoveUntil(context, '/verificar', (_) => false);
  }

  Future<void> reenviarCorreo(BuildContext context) async {
    final u = _auth.currentUser;
    if (!puedeReenviar || u == null) return;
    final ok = await _ejecutar(context, () => u.sendEmailVerification());
    if (!ok || !context.mounted) return;
    _iniciarCuentaRegresiva();
    _mostrar(context, 'Te reenviamos el correo a ${u.email}');
  }

  /// Firebase no avisa solo cuando se abre el enlace del correo:
  /// hay que recargar el usuario y volver a revisar emailVerified.
  Future<void> confirmarVerificacion(BuildContext context) async {
    final u = _auth.currentUser;
    if (u == null) return;
    final ok = await _ejecutar(context, () => u.reload());
    if (!ok || !context.mounted) return;
    if (_auth.currentUser?.emailVerified ?? false) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } else {
      _mostrar(context, 'Todavía no confirmas el correo. Revisa tu bandeja o el spam.');
    }
  }

  /// Firebase manda un enlace para que el tutor cree una contraseña nueva.
  Future<void> enviarRecuperacion(BuildContext context) async {
    if (!_validar(conPassword: false)) return;
    final ok = await _ejecutar(context, () async {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    });
    if (!ok) return;
    _correoRecuperacionEnviado = true;
    notifyListeners();
  }

  Future<void> cerrarSesion(BuildContext context) async {
    _timer?.cancel();
    _segundosReenvio = 0;
    // Cierra también la sesión de Google para que la próxima vez
    // deje elegir otra cuenta.
    if (usuario?.proveedor == Proveedor.google) {
      try {
        await _iniciarGoogle();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
    limpiarFormulario();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _irDespuesDeEntrar(BuildContext context) {
    final u = usuario;
    if (u == null) return;
    limpiarFormulario();
    Navigator.pushNamedAndRemoveUntil(
      context,
      u.necesitaVerificar ? '/verificar' : '/',
      (_) => false,
    );
  }

  void _iniciarCuentaRegresiva() {
    _timer?.cancel();
    _segundosReenvio = 60;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _segundosReenvio--;
      if (_segundosReenvio <= 0) {
        _segundosReenvio = 0;
        t.cancel();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
