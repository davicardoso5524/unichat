-- ============================================
-- UniChat - Storage Setup
-- Arquivo: 003_storage.sql
-- Descrição: Bucket para uploads de arquivos
-- NOTA: Idempotente — pode ser executado múltiplas vezes sem erro
-- ============================================

-- Criar bucket para uploads de chat (PDFs, imagens)
-- ON CONFLICT: se já existe, não faz nada
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-uploads', 'chat-uploads', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STORAGE POLICIES
-- ============================================

-- Remove policies existentes para recriar (idempotente)
DROP POLICY IF EXISTS "chat_uploads_insert" ON storage.objects;
DROP POLICY IF EXISTS "chat_uploads_select" ON storage.objects;
DROP POLICY IF EXISTS "chat_uploads_delete_own" ON storage.objects;

-- Qualquer usuário autenticado pode fazer upload na sua pasta
CREATE POLICY "chat_uploads_insert"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'chat-uploads'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Usuário só pode listar/ver arquivos da sua própria pasta
-- (Arquivos públicos ainda são acessíveis via URL direta, sem policy)
CREATE POLICY "chat_uploads_select"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'chat-uploads'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Usuário só pode deletar seus próprios uploads
CREATE POLICY "chat_uploads_delete_own"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'chat-uploads'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
