insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('anaira-media','anaira-media',true,10485760,ARRAY['image/jpeg','image/png','image/webp','image/gif','image/avif']::text[])
on conflict(id) do update set public=true,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists anaira_media_select_authenticated on storage.objects;
create policy anaira_media_select_authenticated on storage.objects for select to authenticated
using (bucket_id='anaira-media' and (public.anaira_current_is_super_admin() or split_part(name,'/',1)=coalesce(public.anaira_current_restaurant_id()::text,'')));

drop policy if exists anaira_media_insert_authenticated on storage.objects;
create policy anaira_media_insert_authenticated on storage.objects for insert to authenticated
with check (bucket_id='anaira-media' and (public.anaira_current_is_super_admin() or split_part(name,'/',1)=coalesce(public.anaira_current_restaurant_id()::text,'')));

drop policy if exists anaira_media_update_authenticated on storage.objects;
create policy anaira_media_update_authenticated on storage.objects for update to authenticated
using (bucket_id='anaira-media' and (public.anaira_current_is_super_admin() or split_part(name,'/',1)=coalesce(public.anaira_current_restaurant_id()::text,'')))
with check (bucket_id='anaira-media' and (public.anaira_current_is_super_admin() or split_part(name,'/',1)=coalesce(public.anaira_current_restaurant_id()::text,'')));

drop policy if exists anaira_media_delete_authenticated on storage.objects;
create policy anaira_media_delete_authenticated on storage.objects for delete to authenticated
using (bucket_id='anaira-media' and (public.anaira_current_is_super_admin() or split_part(name,'/',1)=coalesce(public.anaira_current_restaurant_id()::text,'')));
