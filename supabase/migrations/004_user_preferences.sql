-- ============================================
-- UniChat - User Preferences
-- Arquivo: 004_user_preferences.sql
-- Descrição: Tabela de preferências do usuário
--            (tema, notificações, sons, vibração)
-- ============================================

-- ============================================
-- 1. TABELA: user_preferences
-- ============================================
CREATE TABLE public.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    dark_mode BOOLEAN NOT NULL DEFAULT false,
    push_notifications BOOLEAN NOT NULL DEFAULT true,
    sound_notifications BOOLEAN NOT NULL DEFAULT true,
    vibration BOOLEAN NOT NULL DEFAULT true,
    new_contact_notifications BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- 2. ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Usuário só pode ver suas próprias preferências
CREATE POLICY "user_preferences_select_own"
    ON public.user_preferences FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Usuário só pode atualizar suas próprias preferências
CREATE POLICY "user_preferences_update_own"
    ON public.user_preferences FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Usuário só pode inserir preferências para si mesmo
CREATE POLICY "user_preferences_insert_own"
    ON public.user_preferences FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 3. TRIGGER: atualizar updated_at automaticamente
-- ============================================
CREATE TRIGGER user_preferences_updated_at
    BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- 4. REALTIME (messages já está em supabase_realtime)
-- ============================================
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
-- ^ Já habilitado anteriormente. Descomente se necessário.
