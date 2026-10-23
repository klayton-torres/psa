ALTER TABLE public.peladas
ADD COLUMN IF NOT EXISTS local_arena TEXT NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_peladas_local_arena ON public.peladas(local_arena);
