-- ============================================================================
-- Flowday — photos de profil sur Supabase Storage
--
-- À exécuter UNE seule fois dans le « SQL Editor » du projet Supabase
-- (Dashboard → SQL Editor → New query → coller → Run).
--
-- Crée le bucket public `avatars` et les politiques RLS qui permettent à
-- chaque utilisateur connecté de gérer uniquement son propre dossier :
--   avatars/<user-id>/avatar.jpg
-- ============================================================================

-- 1. Bucket public « avatars » (5 Mo maximum, images uniquement)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2. Lecture publique (les avatars s'affichent via leur URL publique)
drop policy if exists "avatars lecture publique" on storage.objects;
create policy "avatars lecture publique"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- 3. Envoi : chaque utilisateur écrit dans son dossier <user-id>/…
drop policy if exists "avatars envoi proprietaire" on storage.objects;
create policy "avatars envoi proprietaire"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 4. Mise à jour (changement de photo : upsert sur le même chemin)
drop policy if exists "avatars mise a jour proprietaire" on storage.objects;
create policy "avatars mise a jour proprietaire"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 5. Suppression (retrait de la photo depuis le profil)
drop policy if exists "avatars suppression proprietaire" on storage.objects;
create policy "avatars suppression proprietaire"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
