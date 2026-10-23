CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_uid UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    primeiro_nome TEXT NOT NULL,
    sobrenome TEXT NOT NULL,
    apelido TEXT,
    data_nascimento DATE,
    telefone TEXT,
    telefone_emergencia TEXT,
    email TEXT,
    foto_url TEXT,
    modalidade_praticada TEXT,
    modalidades_praticadas TEXT[] DEFAULT '{}',
    pontuacao_chuteira DOUBLE PRECISION DEFAULT 0,
    altura DOUBLE PRECISION,
    peso DOUBLE PRECISION,
    marcas_chuteira_favoritas TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    estado VARCHAR(2),
    cidade TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_auth_uid ON public.user_profiles(auth_uid);
CREATE INDEX IF NOT EXISTS idx_user_profiles_cidade ON public.user_profiles(cidade);
CREATE INDEX IF NOT EXISTS idx_user_profiles_estado ON public.user_profiles(estado);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_profiles_select ON public.user_profiles;
CREATE POLICY user_profiles_select ON public.user_profiles
    FOR SELECT
    USING (auth_uid = auth.uid());

DROP POLICY IF EXISTS user_profiles_insert ON public.user_profiles;
CREATE POLICY user_profiles_insert ON public.user_profiles
    FOR INSERT
    WITH CHECK (auth_uid = auth.uid());

DROP POLICY IF EXISTS user_profiles_update ON public.user_profiles;
CREATE POLICY user_profiles_update ON public.user_profiles
    FOR UPDATE
    USING (auth_uid = auth.uid())
    WITH CHECK (auth_uid = auth.uid());

DROP POLICY IF EXISTS user_profiles_delete ON public.user_profiles;
CREATE POLICY user_profiles_delete ON public.user_profiles
    FOR DELETE
    USING (auth_uid = auth.uid());

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_nome_completo text;
    v_espaco_pos int;
BEGIN
    v_nome_completo := COALESCE(
        NEW.raw_user_meta_data->>'name',
        NEW.email,
        'Usuário'
    );
    v_espaco_pos := position(' ' in v_nome_completo);

    INSERT INTO public.user_profiles (
        auth_uid,
        primeiro_nome,
        sobrenome,
        apelido,
        email,
        foto_url,
        telefone,
        data_nascimento,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'primeiro_nome',
            NEW.raw_user_meta_data->>'first_name',
            CASE
                WHEN v_espaco_pos > 0 THEN substring(v_nome_completo from 1 for v_espaco_pos - 1)
                ELSE v_nome_completo
            END
        ),
        CASE
            WHEN NEW.raw_user_meta_data->>'sobrenome' IS NOT NULL
            THEN NEW.raw_user_meta_data->>'sobrenome'
            WHEN v_espaco_pos > 0
            THEN substring(v_nome_completo from v_espaco_pos + 1)
            ELSE ''
        END,
        NEW.raw_user_meta_data->>'apelido',
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
        NEW.raw_user_meta_data->>'telefone',
        (NEW.raw_user_meta_data->>'data_nascimento')::DATE,
        now(),
        now()
    )
    ON CONFLICT (auth_uid) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
