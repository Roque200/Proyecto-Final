-- Políticas de Supabase Storage para Pulssó.
--
-- 1) Crear el bucket desde el panel: Storage → New bucket
--      Name: avatares
--      Public bucket: activado (las fotos se leen con su URL pública)
--      Restrict file size: 5 MB
--      Allowed MIME types: image/*
--
-- 2) Ejecutar esto en SQL Editor para permitir que la app suba fotos.
--    La app inicia sesión con Firebase Auth, no con Supabase, por eso la
--    política es para el rol "anon" (la clave publicable). El tamaño y el
--    tipo de archivo los limita la configuración del bucket.

create policy "Pulsso: subir avatares"
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'avatares');
