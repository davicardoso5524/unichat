-- ============================================
-- UniChat - Row Level Security (RLS)
-- Arquivo: 002_rls_policies.sql
-- Descrição: Políticas de segurança por usuário
-- ============================================

-- Ativar RLS em todas as tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES
-- ============================================

-- Qualquer usuário autenticado pode ver profiles (para buscar contatos)
CREATE POLICY "profiles_select_authenticated"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

-- Usuário só pode atualizar o próprio profile
CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================
-- CHATS
-- ============================================

-- Usuário só vê chats dos quais participa
CREATE POLICY "chats_select_participant"
    ON public.chats FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_participants
            WHERE chat_participants.chat_id = chats.id
            AND chat_participants.user_id = auth.uid()
        )
    );

-- Qualquer usuário autenticado pode criar chat
CREATE POLICY "chats_insert_authenticated"
    ON public.chats FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ============================================
-- CHAT_PARTICIPANTS
-- ============================================

-- Usuário só vê participantes de chats dos quais faz parte
CREATE POLICY "chat_participants_select"
    ON public.chat_participants FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_participants AS cp
            WHERE cp.chat_id = chat_participants.chat_id
            AND cp.user_id = auth.uid()
        )
    );

-- Usuário autenticado pode inserir participantes (ao criar chat)
CREATE POLICY "chat_participants_insert"
    ON public.chat_participants FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ============================================
-- MESSAGES
-- ============================================

-- Usuário só vê mensagens de chats dos quais participa
CREATE POLICY "messages_select_participant"
    ON public.messages FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_participants
            WHERE chat_participants.chat_id = messages.chat_id
            AND chat_participants.user_id = auth.uid()
        )
    );

-- Usuário só pode enviar mensagem como ele mesmo, em chats que participa
CREATE POLICY "messages_insert_own"
    ON public.messages FOR INSERT
    TO authenticated
    WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.chat_participants
            WHERE chat_participants.chat_id = messages.chat_id
            AND chat_participants.user_id = auth.uid()
        )
    );
