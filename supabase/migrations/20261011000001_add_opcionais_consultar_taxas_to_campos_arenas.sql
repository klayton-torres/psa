alter table public.campos_arenas
add column if not exists opcionais_consultar_taxas text[] not null default '{}'::text[];
