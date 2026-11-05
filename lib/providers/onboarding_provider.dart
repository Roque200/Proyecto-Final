import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/voz.dart';

class PaginaOnboarding {
  final IconData icono;
  final String titulo;
  final String texto;

  const PaginaOnboarding(this.icono, this.titulo, this.texto);
}

class OnboardingProvider extends ChangeNotifier {
  static const claveVisto = 'onboarding_visto';

  static const List<PaginaOnboarding> paginas = [
    PaginaOnboarding(
      Icons.touch_app,
      'Geometría que se siente',
      'Una app para que niñas y niños invidentes aprendan geometría con voz, vibración y gestos.',
    ),
    PaginaOnboarding(
      Icons.vibration,
      'Modo alumno',
      'El alumno recorre cada figura con el dedo. El celular vibra en los lados, vibra más fuerte en los vértices y dice lo que está tocando.',
    ),
    PaginaOnboarding(
      Icons.emoji_events,
      'Retos y progreso',
      'Retos por voz para practicar, y un registro de avances para que el tutor sepa cómo va el alumno.',
    ),
    PaginaOnboarding(
      Icons.notifications_active,
      'Planes y avisos',
      'Elige el plan que más te acomode y recibe avisos cuando haya lecciones nuevas.',
    ),
  ];

  final SharedPreferences _prefs;

  /// Ruta a la que se va al terminar (o al saltar) la bienvenida.
  final String destino;

  final PageController controlador = PageController();
  int _pagina = 0;

  OnboardingProvider(this._prefs, {this.destino = '/login'});

  int get pagina => _pagina;
  bool get esUltima => _pagina == paginas.length - 1;

  void narrarActual() {
    final p = paginas[_pagina];
    Voz.decir('${p.titulo}. ${p.texto}');
  }

  void alCambiarPagina(int nueva) {
    _pagina = nueva;
    notifyListeners();
    narrarActual();
  }

  void siguiente(BuildContext context) {
    if (esUltima) {
      terminar(context);
      return;
    }
    controlador.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> terminar(BuildContext context) async {
    await Voz.callar();
    await _prefs.setBool(claveVisto, true);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, destino);
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }
}
