alter table public.campos_arenas
  add column if not exists horarios_disponiveis jsonb not null default '[]'::jsonb;
