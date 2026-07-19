-- ============================================
-- UniChat - RPCs de chats, grupos e mensagens
-- ============================================

CREATE OR REPLACE FUNCTION public.create_chat(other_user_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  current_user_role text;
  current_user_course text;
  other_user_course text;
  existing_chat_id integer;
  new_chat_id integer;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  IF other_user_id IS NULL OR other_user_id = current_user_id THEN
    RAISE EXCEPTION 'Usuário selecionado inválido';
  END IF;

  SELECT role, course
  INTO current_user_role, current_user_course
  FROM public.profiles
  WHERE id = current_user_id;

  SELECT course
  INTO other_user_course
  FROM public.profiles
  WHERE id = other_user_id;

  IF other_user_course IS NULL THEN
    RAISE EXCEPTION 'Usuário selecionado não encontrado';
  END IF;

  IF current_user_role = 'student'
      AND current_user_course IS DISTINCT FROM other_user_course THEN
    RAISE EXCEPTION 'Alunos só podem conversar com pessoas do mesmo curso';
  END IF;

  SELECT cp.chat_id
  INTO existing_chat_id
  FROM public.chat_participants cp
  JOIN public.chats c ON c.id = cp.chat_id
  WHERE COALESCE(c.is_group, false) = false
    AND cp.user_id IN (current_user_id, other_user_id)
  GROUP BY cp.chat_id
  HAVING COUNT(DISTINCT cp.user_id) = 2
     AND COUNT(*) = 2
  LIMIT 1;

  IF existing_chat_id IS NOT NULL THEN
    RETURN existing_chat_id;
  END IF;

  INSERT INTO public.chats (is_group)
  VALUES (false)
  RETURNING id INTO new_chat_id;

  INSERT INTO public.chat_participants (chat_id, user_id, role)
  VALUES
    (new_chat_id, current_user_id, 'member'),
    (new_chat_id, other_user_id, 'member');

  RETURN new_chat_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_group(
  group_name text,
  group_image_url text DEFAULT NULL,
  member_ids uuid[] DEFAULT '{}'
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  new_chat_id integer;
  member_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  IF group_name IS NULL OR trim(group_name) = '' THEN
    RAISE EXCEPTION 'Nome do grupo é obrigatório';
  END IF;

  INSERT INTO public.chats (is_group, group_name, group_image_url, owner_id)
  VALUES (true, trim(group_name), group_image_url, current_user_id)
  RETURNING id INTO new_chat_id;

  INSERT INTO public.chat_participants (chat_id, user_id, role)
  VALUES (new_chat_id, current_user_id, 'owner');

  FOREACH member_id IN ARRAY member_ids
  LOOP
    IF member_id IS NOT NULL AND member_id != current_user_id THEN
      INSERT INTO public.chat_participants (chat_id, user_id, role)
      VALUES (new_chat_id, member_id, 'member')
      ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;

  RETURN new_chat_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.add_group_member(
  p_chat_id integer,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  chat_owner_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  SELECT owner_id INTO chat_owner_id
  FROM public.chats
  WHERE id = p_chat_id AND is_group = true;

  IF chat_owner_id IS NULL THEN
    RAISE EXCEPTION 'Grupo não encontrado';
  END IF;

  IF chat_owner_id != current_user_id THEN
    RAISE EXCEPTION 'Apenas o dono do grupo pode adicionar membros';
  END IF;

  INSERT INTO public.chat_participants (chat_id, user_id, role)
  VALUES (p_chat_id, p_user_id, 'member')
  ON CONFLICT DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_group_member(
  p_chat_id integer,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  chat_owner_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  SELECT owner_id INTO chat_owner_id
  FROM public.chats
  WHERE id = p_chat_id AND is_group = true;

  IF chat_owner_id IS NULL THEN
    RAISE EXCEPTION 'Grupo não encontrado';
  END IF;

  IF chat_owner_id != current_user_id THEN
    RAISE EXCEPTION 'Apenas o dono do grupo pode remover membros';
  END IF;

  IF p_user_id = current_user_id THEN
    RAISE EXCEPTION 'O dono não pode ser removido do grupo';
  END IF;

  DELETE FROM public.chat_participants
  WHERE chat_id = p_chat_id AND user_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_group(
  p_chat_id integer,
  p_group_name text DEFAULT NULL,
  p_group_image_url text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  chat_owner_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  SELECT owner_id INTO chat_owner_id
  FROM public.chats
  WHERE id = p_chat_id AND is_group = true;

  IF chat_owner_id IS NULL THEN
    RAISE EXCEPTION 'Grupo não encontrado';
  END IF;

  IF chat_owner_id != current_user_id THEN
    RAISE EXCEPTION 'Apenas o dono pode editar o grupo';
  END IF;

  UPDATE public.chats SET
    group_name = COALESCE(p_group_name, group_name),
    group_image_url = COALESCE(p_group_image_url, group_image_url)
  WHERE id = p_chat_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.pin_message(
  p_chat_id integer,
  p_message_id integer,
  p_duration_hours integer DEFAULT 24
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  chat_owner_id uuid;
  is_group_chat boolean;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  SELECT is_group, owner_id INTO is_group_chat, chat_owner_id
  FROM public.chats
  WHERE id = p_chat_id;

  IF NOT is_group_chat THEN
    RAISE EXCEPTION 'Fixar mensagem só é permitido em grupos';
  END IF;

  IF chat_owner_id != current_user_id THEN
    RAISE EXCEPTION 'Apenas o dono do grupo pode fixar mensagens';
  END IF;

  IF p_duration_hours NOT IN (24, 168) THEN
    RAISE EXCEPTION 'Duração deve ser 24 horas ou 7 dias (168 horas)';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.messages
    WHERE id = p_message_id AND chat_id = p_chat_id
  ) THEN
    RAISE EXCEPTION 'Mensagem não pertence ao grupo informado';
  END IF;

  INSERT INTO public.pinned_messages (chat_id, message_id, pinned_by, expires_at)
  VALUES (p_chat_id, p_message_id, current_user_id, now() + (p_duration_hours || ' hours')::interval)
  ON CONFLICT (chat_id, message_id) DO UPDATE SET
    expires_at = now() + (p_duration_hours || ' hours')::interval,
    pinned_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.unpin_message(
  p_chat_id integer,
  p_message_id integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
  chat_owner_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  SELECT owner_id INTO chat_owner_id
  FROM public.chats
  WHERE id = p_chat_id AND is_group = true;

  IF chat_owner_id != current_user_id THEN
    RAISE EXCEPTION 'Apenas o dono do grupo pode desafixar mensagens';
  END IF;

  DELETE FROM public.pinned_messages
  WHERE chat_id = p_chat_id AND message_id = p_message_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_messages_read(p_chat_id integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.chat_participants
    WHERE chat_id = p_chat_id AND user_id = current_user_id
  ) THEN
    RAISE EXCEPTION 'Usuário não participa deste chat';
  END IF;

  INSERT INTO public.message_read_receipts (message_id, user_id)
  SELECT m.id, current_user_id
  FROM public.messages m
  WHERE m.chat_id = p_chat_id
    AND m.sender_id != current_user_id
    AND NOT EXISTS (
      SELECT 1 FROM public.message_read_receipts r
      WHERE r.message_id = m.id AND r.user_id = current_user_id
    )
  ON CONFLICT DO NOTHING;

  UPDATE public.messages
  SET status = 'read'
  WHERE chat_id = p_chat_id
    AND sender_id != current_user_id
    AND status != 'read';
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_chat(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_group(text, text, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_group_member(integer, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_group_member(integer, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_group(integer, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pin_message(integer, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unpin_message(integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_messages_read(integer) TO authenticated;
GRANT UPDATE ON public.messages TO authenticated;

DROP POLICY IF EXISTS messages_update_status ON public.messages;
CREATE POLICY messages_update_status ON public.messages
  FOR UPDATE TO authenticated
  USING (chat_id IN (SELECT public.get_my_chat_ids()))
  WITH CHECK (chat_id IN (SELECT public.get_my_chat_ids()));
