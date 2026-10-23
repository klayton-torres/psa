create extension if not exists pgcrypto;

create table if not exists public.peladas (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  organizador_id uuid not null,
  organizador_nome text not null,
  contato text not null,
  data_inicio timestamptz not null,
  data_fim timestamptz not null,
  recorrencia_grupo_id uuid,
  recorrencia_dias_semana int[] not null default '{}'::int[],
  hora_inicio text not null,
  hora_fim text not null,
  taxa numeric not null default 0,
  modalidade text not null default 'society',
  tipo_grama text not null default 'sintetica',
  tipo_chuteira text not null default 'livre',
  tipos_chuteira_permitidos text[] not null default '{}'::text[],
  categoria text not null default 'livreAdulto',
  cor_colete_index int not null default 0,
  cores_colete_indices int[] not null default '{}'::int[],
  cor_colete_personalizado text,
  endereco text not null default '',
  estado text not null default '',
  cidade text not null default '',
  latitude double precision,
  longitude double precision,
  status text not null default 'ativa',
  quorum_minimo int not null default 10,
  quorum_maximo int not null default 0,
  participantes_confirmados int not null default 0,
  avaliacao_media numeric not null default 0,
  total_avaliacoes int not null default 0,
  descricao text,
  checklist jsonb not null default '{}'::jsonb,
  fotos_capa jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.peladas_private (
  pelada_id uuid primary key references public.peladas(id) on delete cascade,
  organizador_id uuid not null,
  organizador_cpf text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists peladas_set_updated_at on public.peladas;
create trigger peladas_set_updated_at
before update on public.peladas
for each row
execute function public.set_updated_at();

drop trigger if exists peladas_private_set_updated_at on public.peladas_private;
create trigger peladas_private_set_updated_at
before update on public.peladas_private
for each row
execute function public.set_updated_at();

alter table public.peladas enable row level security;
alter table public.peladas_private enable row level security;

drop policy if exists peladas_select_public on public.peladas;
create policy peladas_select_public
on public.peladas
for select
using (true);

drop policy if exists peladas_insert_owner on public.peladas;
create policy peladas_insert_owner
on public.peladas
for insert
to authenticated
with check (auth.uid() = organizador_id);

drop policy if exists peladas_update_owner on public.peladas;
create policy peladas_update_owner
on public.peladas
for update
to authenticated
using (auth.uid() = organizador_id)
with check (auth.uid() = organizador_id);

drop policy if exists peladas_delete_owner on public.peladas;
create policy peladas_delete_owner
on public.peladas
for delete
to authenticated
using (auth.uid() = organizador_id);

drop policy if exists peladas_private_select_owner on public.peladas_private;
create policy peladas_private_select_owner
on public.peladas_private
for select
to authenticated
using (auth.uid() = organizador_id);

drop policy if exists peladas_private_insert_owner on public.peladas_private;
create policy peladas_private_insert_owner
on public.peladas_private
for insert
to authenticated
with check (auth.uid() = organizador_id);

drop policy if exists peladas_private_update_owner on public.peladas_private;
create policy peladas_private_update_owner
on public.peladas_private
for update
to authenticated
using (auth.uid() = organizador_id)
with check (auth.uid() = organizador_id);

drop policy if exists peladas_private_delete_owner on public.peladas_private;
create policy peladas_private_delete_owner
on public.peladas_private
for delete
to authenticated
using (auth.uid() = organizador_id);

alter table public.peladas replica identity full;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'peladas'
    ) then
      alter publication supabase_realtime add table public.peladas;
    end if;
  end if;
end;
$$;

