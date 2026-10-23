alter table if exists public.peladas
add column if not exists bairro text not null default '';

