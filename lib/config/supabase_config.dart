/// Configuración de Supabase, que usamos solo para guardar las fotos de
/// perfil (Supabase Storage). El inicio de sesión sigue siendo Firebase Auth.
///
/// La URL y la clave publicable están hechas para ir dentro de la app: lo que
/// protege los datos son las políticas del bucket (ver supabase/politicas_storage.sql).
/// La clave "secret" / "service_role" NUNCA va en la app ni en el repositorio.
class SupabaseConfig {
  /// Supabase → Project Settings → Data API → Project URL.
  static const String url = 'https://usbsgawbwzavvirkkmyr.supabase.co';

  /// Supabase → Project Settings → API Keys → Publishable key (sb_publishable_...).
  static const String publishableKey =
      'sb_publishable_5zmcXdco904xVBN93yPVKA_f058CdEr';

  /// Bucket público donde se guardan los avatares.
  static const String bucketAvatares = 'avatares';
}
