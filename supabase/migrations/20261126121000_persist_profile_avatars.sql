insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('topgram-profile-avatars','topgram-profile-avatars',false,1500000,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public=false,file_size_limit=1500000,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "TopGram avatar owner read" on storage.objects;
create policy "TopGram avatar owner read" on storage.objects
for select to authenticated
using (bucket_id='topgram-profile-avatars' and (storage.foldername(name))[1]=(select auth.uid()::text));

drop policy if exists "TopGram avatar owner upload" on storage.objects;
create policy "TopGram avatar owner upload" on storage.objects
for insert to authenticated
with check (bucket_id='topgram-profile-avatars' and (storage.foldername(name))[1]=(select auth.uid()::text));

drop policy if exists "TopGram avatar owner update" on storage.objects;
create policy "TopGram avatar owner update" on storage.objects
for update to authenticated
using (bucket_id='topgram-profile-avatars' and (storage.foldername(name))[1]=(select auth.uid()::text))
with check (bucket_id='topgram-profile-avatars' and (storage.foldername(name))[1]=(select auth.uid()::text));

drop policy if exists "TopGram avatar owner delete" on storage.objects;
create policy "TopGram avatar owner delete" on storage.objects
for delete to authenticated
using (bucket_id='topgram-profile-avatars' and (storage.foldername(name))[1]=(select auth.uid()::text));
