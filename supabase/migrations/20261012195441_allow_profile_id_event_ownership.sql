-- The app stores user_profiles.id in peladas.organizador_id. Let the owner
-- policies resolve that profile to the authenticated Supabase UID.
drop policy if exists peladas_insert_owner on public.peladas;
create policy peladas_insert_owner
on public.peladas
for insert to authenticated
with check (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas.organizador_id and up.auth_uid = auth.uid()
  )
);

drop policy if exists peladas_update_owner on public.peladas;
create policy peladas_update_owner
on public.peladas
for update to authenticated
using (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas.organizador_id and up.auth_uid = auth.uid()
  )
)
with check (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas.organizador_id and up.auth_uid = auth.uid()
  )
);

drop policy if exists peladas_delete_owner on public.peladas;
create policy peladas_delete_owner
on public.peladas
for delete to authenticated
using (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas.organizador_id and up.auth_uid = auth.uid()
  )
);

drop policy if exists peladas_private_select_owner on public.peladas_private;
create policy peladas_private_select_owner
on public.peladas_private
for select to authenticated
using (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas_private.organizador_id and up.auth_uid = auth.uid()
  )
);

drop policy if exists peladas_private_insert_owner on public.peladas_private;
create policy peladas_private_insert_owner
on public.peladas_private
for insert to authenticated
with check (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas_private.organizador_id and up.auth_uid = auth.uid()
  )
);

drop policy if exists peladas_private_update_owner on public.peladas_private;
create policy peladas_private_update_owner
on public.peladas_private
for update to authenticated
using (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas_private.organizador_id and up.auth_uid = auth.uid()
  )
)
with check (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas_private.organizador_id and up.auth_uid = auth.uid()
  )
);

drop policy if exists peladas_private_delete_owner on public.peladas_private;
create policy peladas_private_delete_owner
on public.peladas_private
for delete to authenticated
using (
  auth.uid() = organizador_id
  or exists (
    select 1 from public.user_profiles up
    where up.id = peladas_private.organizador_id and up.auth_uid = auth.uid()
  )
);
