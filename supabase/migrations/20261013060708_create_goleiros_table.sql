create table public.goleiros (
  id uuid primary key default gen_random_uuid(),
  foto jsonb,
  nome text not null,
  sobrenome text not null,
  apelido text,
  data_nascimento date,
  telefone text,
  cep text,
  uf text,
  cidade text,
  bairro text,
  situacao_federativa text,
  com_auxiliares boolean,
  atuacao text[] not null default '{}'::text[],
  equipamentos text[] not null default '{}'::text[],
  modalidades text[] not null default '{}'::text[],
  taxa_arbitragem numeric(10, 2),
  proprietario_id uuid references public.user_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.goleiros enable row level security;

grant select on public.goleiros to anon, authenticated;
grant insert, update, delete on public.goleiros to authenticated;

create policy goleiros_select_public_all
  on public.goleiros for select
  to anon, authenticated
  using (true);

create policy goleiros_insert_owner
  on public.goleiros for insert
  to authenticated
  with check (
    proprietario_id in (
      select up.id from public.user_profiles up where up.auth_uid = (select auth.uid())
    )
  );

create policy goleiros_update_owner
  on public.goleiros for update
  to authenticated
  using (
    proprietario_id in (
      select up.id from public.user_profiles up where up.auth_uid = (select auth.uid())
    )
  )
  with check (
    proprietario_id in (
      select up.id from public.user_profiles up where up.auth_uid = (select auth.uid())
    )
  );

create policy goleiros_delete_owner
  on public.goleiros for delete
  to authenticated
  using (
    proprietario_id in (
      select up.id from public.user_profiles up where up.auth_uid = (select auth.uid())
    )
  );
