/// Configuración de Stripe (modo de prueba).
///
/// La clave publicable (pk_test_...) está hecha para ir dentro de la app:
/// solo sirve para tokenizar tarjetas, no para cobrar ni para leer datos.
/// La clave secreta (sk_test_...) NUNCA va en la app ni en el repositorio.
class StripeConfig {
  /// Copia aquí tu clave de dashboard.stripe.com → Desarrolladores → Claves de API.
  static const String publishableKey =
      'pk_test_51UbmEEGStrqkThCKlkTLXbs2MyLu6vNn0u5mjmlbGEH1xFnr2PA3I77tieocTJvYvsMmOS7hHryzlfYIaHYdivUZ00nWyf1aOU';

  /// Tarjetas de prueba de Stripe (cualquier fecha futura y cualquier CVC):
  /// 4242 4242 4242 4242 → aprobada
  /// 4000 0000 0000 0002 → la simulamos como rechazada por el banco
  static const String terminacionRechazada = '0002';
}
