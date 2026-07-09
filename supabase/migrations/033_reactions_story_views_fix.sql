-- MIGRATION 033: Reactions fix + Story views fix

-- ============================================
-- #1: Reactions INSERT policy
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own reactions' AND tablename = 'reactions'
  ) THEN
    CREATE POLICY "Users can insert own reactions"
      ON public.reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================
-- #2: Reactions DELETE policy
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete own reactions' AND tablename = 'reactions'
  ) THEN
    CREATE POLICY "Users can delete own reactions"
      ON public.reactions FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================
-- #3: Reactions UPDATE policy (for upsert)
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own reactions' AND tablename = 'reactions'
  ) THEN
    CREATE POLICY "Users can update own reactions"
      ON public.reactions FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================
-- #4: Story views UPDATE policy (for upsert)
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own story views' AND tablename = 'story_views'
  ) THEN
    CREATE POLICY "Users can update own story views"
      ON public.story_views FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================
-- #5: Ensure update_reaction_counts trigger function exists
-- ============================================
CREATE OR REPLACE FUNCTION public.update_reaction_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  reaction_count INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT COUNT(*) INTO reaction_count
    FROM reactions WHERE post_id = NEW.post_id;

    UPDATE posts
    SET reaction_counts = COALESCE(reaction_counts, '{}'::jsonb) ||
      jsonb_build_object(NEW.reaction_type, reaction_count)
    WHERE id = NEW.post_id;

    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    SELECT COUNT(*) INTO reaction_count
    FROM reactions WHERE post_id = OLD.post_id;

    IF reaction_count = 0 THEN
      UPDATE posts
      SET reaction_counts = reaction_counts - OLD.reaction_type
      WHERE id = OLD.post_id;
    ELSE
      UPDATE posts
      SET reaction_counts = COALESCE(reaction_counts, '{}'::jsonb) ||
        jsonb_build_object(OLD.reaction_type, reaction_count)
      WHERE id = OLD.post_id;
    END IF;

    RETURN OLD;
  END IF;
END;
$$;

-- Recreate trigger on reactions
DROP TRIGGER IF EXISTS on_reaction_change ON public.reactions;
CREATE TRIGGER on_reaction_change
  AFTER INSERT OR DELETE ON public.reactions
  FOR EACH ROW EXECUTE FUNCTION public.update_reaction_counts();
