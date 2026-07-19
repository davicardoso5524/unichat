-- ============================================
-- UniChat - Supabase Schema
-- Arquivo: 001_create_tables.sql
-- Descrição: Criação das tabelas principais
-- ============================================

-- ============================================
-- 1. TABELA: profiles (extensão do auth.users)
-- ============================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'professor')),
    course VARCHAR(80) NOT NULL DEFAULT 'Sistemas de Informação' CHECK (
        course IN (
            'Sistemas de Informação',
            'Química',
            'Física',
            'Letras',
            'Pedagogia',
            'Ciências Biológicas',
            'Administração',
            'Ciências Contábeis'
        )
    ),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para busca por email
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_course ON public.profiles(course);

-- ============================================
-- 2. TABELA: chats
-- ============================================
CREATE TABLE public.chats (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- 3. TABELA: chat_participants (associativa)
-- ============================================
CREATE TABLE public.chat_participants (
    chat_id INT NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (chat_id, user_id)
);

-- Índice para buscar chats de um usuário rapidamente
CREATE INDEX idx_chat_participants_user ON public.chat_participants(user_id);

CREATE OR REPLACE FUNCTION public.get_my_chat_ids()
RETURNS SETOF integer
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT chat_id
    FROM public.chat_participants
    WHERE user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.can_view_profile(
    target_user_id uuid,
    target_course text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_role text;
    current_course text;
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN false;
    END IF;

    IF target_user_id = auth.uid() THEN
        RETURN true;
    END IF;

    SELECT role, course
    INTO current_role, current_course
    FROM public.profiles
    WHERE id = auth.uid();

    IF current_role = 'professor' THEN
        RETURN true;
    END IF;

    RETURN current_course IS NOT NULL
        AND current_course <> ''
        AND current_course = target_course;
END;
$$;

-- ============================================
-- 4. TABELA: messages
-- ============================================
CREATE TABLE public.messages (
    id SERIAL PRIMARY KEY,
    chat_id INT NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    file_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para listar mensagens de um chat ordenadas
CREATE INDEX idx_messages_chat_created ON public.messages(chat_id, created_at);
-- Índice para buscar mensagens por sender
CREATE INDEX idx_messages_sender ON public.messages(sender_id);

-- ============================================
-- 5. FUNCTION: criar profile automaticamente ao signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, role, course)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'Usuário'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
        COALESCE(NEW.raw_user_meta_data->>'course', 'Sistemas de Informação')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: dispara ao criar novo usuário no auth
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 6. FUNCTION: atualizar updated_at automaticamente
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
