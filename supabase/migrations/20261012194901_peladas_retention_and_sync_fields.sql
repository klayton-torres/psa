-- Keep each pelada available until 15 days after its finish time, then purge it.
-- pg_cron runs this cleanup every 15 minutes so the retention window stays close
-- to the requested 15 days instead of extending by an entire day.
create extension if not exists pg_cron with schema pg_catalog;

grant usage on schema cron to postgres;
grant all privileges on all tables in schema cron to postgres;

-- Bring the remote table in line with fields currently stored by Pelada.toMap().
alter table public.peladas
  add column if not exists local_arena text not null default '',
  add column if not exists cep text,
  add column if not exists categoria_genero text not null default 'misto',
  add column if not exists beneficio_goleiro boolean,
  add column if not exists foto_braseao jsonb,
  add column if not exists foto_arena jsonb,
  add column if not exists foto_galera jsonb;

-- Make the finish date/time calculation explicit in one immutable helper.
create or replace function public.pelada_fim_em(data_fim timestamptz, hora_fim text)
returns timestamptz
language sql
stable
strict
as $$
  select ((((data_fim at time zone 'UTC')::date + hora_fim::time)
    at time zone 'America/Sao_Paulo'));
$$;

create index if not exists peladas_data_fim_idx on public.peladas (data_fim);

-- Replace an existing job with the same name to keep this migration repeatable.
do $$
declare
  old_job record;
begin
  for old_job in select jobid from cron.job where jobname = 'purge_expired_peladas'
  loop
    perform cron.unschedule(old_job.jobid);
  end loop;
end;
$$;

select cron.schedule(
  'purge_expired_peladas',
  '*/15 * * * *',
  $$delete from public.peladas
    where public.pelada_fim_em(data_fim, hora_fim) <= now() - interval '15 days';$$
);
