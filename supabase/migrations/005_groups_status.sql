-- ============================================
-- UniChat - Status de mensagens, grupos e mensagens fixadas
-- ============================================

DO $$
BEGIN
  CREATE TYPE public.message_status_enum AS ENUM ('sent', 'delivered', 'read');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS status public.message_status_enum NOT NULL DEFAULT 'sent';

CREATE TABLE IF NOT EXISTS public.message_read_receipts (
  message_id integer NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  read_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (message_id, user_id)
);

ALTER TABLE public.chats
  ADD COLUMN IF NOT EXISTS is_group boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS group_name text,
  ADD COLUMN IF NOT EXISTS group_image_url text,
  ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES auth.users(id);

ALTER TABLE public.chat_participants
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'member';

CREATE TABLE IF NOT EXISTS public.pinned_messages (
  id serial PRIMARY KEY,
  chat_id integer NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  message_id integer NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  pinned_by uuid NOT NULL REFERENCES auth.users(id),
  pinned_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  UNIQUE(chat_id, message_id)
);

CREATE INDEX IF NOT EXISTS idx_message_read_receipts_message ON public.message_read_receipts(message_id);
CREATE INDEX IF NOT EXISTS idx_message_read_receipts_user ON public.message_read_receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_pinned_messages_chat ON public.pinned_messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_pinned_messages_expires ON public.pinned_messages(expires_at);
CREATE INDEX IF NOT EXISTS idx_chats_is_group ON public.chats(is_group);
CREATE INDEX IF NOT EXISTS idx_messages_status ON public.messages(status);

ALTER TABLE public.message_read_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pinned_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS message_read_receipts_select ON public.message_read_receipts;
CREATE POLICY message_read_receipts_select ON public.message_read_receipts
  FOR SELECT TO authenticated
  USING (message_id IN (
    SELECT m.id FROM public.messages m
    WHERE m.chat_id IN (SELECT public.get_my_chat_ids())
  ));

DROP POLICY IF EXISTS message_read_receipts_insert ON public.message_read_receipts;
CREATE POLICY message_read_receipts_insert ON public.message_read_receipts
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND message_id IN (
      SELECT m.id FROM public.messages m
      WHERE m.chat_id IN (SELECT public.get_my_chat_ids())
    )
  );

DROP POLICY IF EXISTS pinned_messages_select ON public.pinned_messages;
CREATE POLICY pinned_messages_select ON public.pinned_messages
  FOR SELECT TO authenticated
  USING (chat_id IN (SELECT public.get_my_chat_ids()));

DROP POLICY IF EXISTS pinned_messages_insert ON public.pinned_messages;
CREATE POLICY pinned_messages_insert ON public.pinned_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    chat_id IN (SELECT public.get_my_chat_ids())
    AND pinned_by = auth.uid()
  );

DROP POLICY IF EXISTS pinned_messages_delete ON public.pinned_messages;
CREATE POLICY pinned_messages_delete ON public.pinned_messages
  FOR DELETE TO authenticated
  USING (
    chat_id IN (SELECT public.get_my_chat_ids())
    AND pinned_by = auth.uid()
  );

GRANT SELECT, INSERT ON public.message_read_receipts TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.pinned_messages TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.pinned_messages_id_seq TO authenticated;
