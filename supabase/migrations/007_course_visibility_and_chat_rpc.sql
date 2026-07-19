-- ============================================
-- UniChat - Cursos, visibilidade por curso e hardening de RPCs
-- ============================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS course VARCHAR(80) NOT NULL DEFAULT 'Sistemas de Informação';

UPDATE public.profiles
SET course = 'Sistemas de Informação'
WHERE course IS NULL OR trim(course) = '';

DO $$
BEGIN
  ALTER TABLE public.profiles
    ADD CONSTRAINT profiles_course_check CHECK (
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
    );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE INDEX IF NOT EXISTS idx_profiles_course ON public.profiles(course);

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

DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;
CREATE POLICY "profiles_select_authenticated"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (public.can_view_profile(id, course));

DROP POLICY IF EXISTS "chat_participants_insert" ON public.chat_participants;
CREATE POLICY "chat_participants_insert"
  ON public.chat_participants FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

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

GRANT EXECUTE ON FUNCTION public.get_my_chat_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_view_profile(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_chat(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_messages_read(integer) TO authenticated;
