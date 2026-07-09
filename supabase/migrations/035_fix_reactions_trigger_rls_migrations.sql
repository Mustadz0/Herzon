-- Fix 1: Extend messages UPDATE policy to allow marking messages as read in own conversations
DROP POLICY IF EXISTS "Users can update own messages" ON messages;
CREATE POLICY "Users can update own messages" ON messages FOR UPDATE USING (
  auth.uid() = sender_id OR EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = messages.conversation_id
    AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
  )
);

-- Fix 2: Extend reactions trigger to handle UPDATE (changing reaction type)
DROP TRIGGER IF EXISTS on_reaction_change ON public.reactions;
CREATE TRIGGER on_reaction_change
  AFTER INSERT OR DELETE OR UPDATE ON public.reactions
  FOR EACH ROW EXECUTE FUNCTION public.update_reaction_counts();

-- Fix 3: Update reaction_counts function to handle UPDATE correctly
CREATE OR REPLACE FUNCTION public.update_reaction_counts()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts
    SET reaction_counts = COALESCE(reaction_counts, '{}'::jsonb) ||
      jsonb_build_object(NEW.reaction_type,
        COALESCE((reaction_counts ->> NEW.reaction_type)::int, 0) + 1)
    WHERE id = NEW.post_id;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts
    SET reaction_counts =
      CASE
        WHEN (reaction_counts ->> OLD.reaction_type)::int <= 1
        THEN reaction_counts - OLD.reaction_type
        ELSE jsonb_set(reaction_counts, ARRAY[OLD.reaction_type],
          to_jsonb(((reaction_counts ->> OLD.reaction_type)::int - 1)::text::int))
      END
    WHERE id = OLD.post_id;
    RETURN OLD;

  ELSIF TG_OP = 'UPDATE' AND OLD.reaction_type != NEW.reaction_type THEN
    UPDATE public.posts
    SET reaction_counts = COALESCE(reaction_counts, '{}'::jsonb) ||
      jsonb_build_object(NEW.reaction_type,
        COALESCE((reaction_counts ->> NEW.reaction_type)::int, 0) + 1)
    WHERE id = NEW.post_id;
    UPDATE public.posts
    SET reaction_counts =
      CASE
        WHEN (reaction_counts ->> OLD.reaction_type)::int <= 1
        THEN reaction_counts - OLD.reaction_type
        ELSE jsonb_set(reaction_counts, ARRAY[OLD.reaction_type],
          to_jsonb(((reaction_counts ->> OLD.reaction_type)::int - 1)::text::int))
      END
    WHERE id = OLD.post_id;
    RETURN NEW;
  END IF;

  RETURN NULL;
END;
$$;

-- Fix 4: Add get_user_reactions function (was only created via API, not in migrations)
CREATE OR REPLACE FUNCTION public.get_user_reactions()
RETURNS TABLE(post_id uuid, reaction_type text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT r.post_id, r.reaction_type
  FROM public.reactions r
  WHERE r.user_id = auth.uid();
END;
$$;
