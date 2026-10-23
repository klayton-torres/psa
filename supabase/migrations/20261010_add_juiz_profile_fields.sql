alter table public.juizes
  add column if not exists situacao_federativa text,
  add column if not exists com_auxiliares boolean,
  add column if not exists atuacao text[] not null default '{}'::text[],
  add column if not exists equipamentos text[] not null default '{}'::text[],
  add column if not exists modalidades text[] not null default '{}'::text[],
  add column if not exists taxa_arbitragem numeric(10, 2);
