-- ============================================================
-- MIGRATION 040: Comprehensive Security Fixes
-- Date: 2026-07-10
-- Fixes all issues found by Supabase security advisor:
-- 1. REVOKE anon access from sensitive/dangerous functions
-- 2. REVOKE authenticated from admin-only functions → service_role
-- 3. Fix mutable search_path on 7 functions
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. REVOKE anon access from dangerous functions
-- ─────────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) FROM authenticated;
GRANT  EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_expired_stories() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_engagement_metrics() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_posts_last_7_days() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_top_zones() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_growth() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_comment_notification() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_follow_notification() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_notification() FROM anon;
REVOKE EXECUTE ON FUNCTION public.award_badges_on_milestone() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_post_xp() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_xp() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_comment_xp() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_reactions() FROM anon;
REVOKE EXECUTE ON FUNCTION public.prevent_vote_own_post() FROM anon;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'book_ride'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.book_ride(uuid, integer) FROM anon';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'rls_auto_enable'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM anon';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────
-- 2. REVOKE authenticated from admin-only functions
--    Grant only to service_role
-- ─────────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.admin_delete_post(uuid) FROM authenticated;
GRANT  EXECUTE ON FUNCTION public.admin_delete_post(uuid) TO service_role;

REVOKE EXECUTE ON FUNCTION public.admin_set_user_admin(uuid, boolean) FROM authenticated;
GRANT  EXECUTE ON FUNCTION public.admin_set_user_admin(uuid, boolean) TO service_role;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'admin_set_user_vibes'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.admin_set_user_vibes(uuid, boolean) FROM authenticated';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.admin_set_user_vibes(uuid, boolean) TO service_role';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'admin_update_report_status'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.admin_update_report_status(uuid, text) FROM authenticated';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.admin_update_report_status(uuid, text) TO service_role';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────
-- 3. FIX search_path on 7 vulnerable functions
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.prevent_vote_own_post()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id = (SELECT user_id FROM public.posts WHERE id = NEW.post_id) THEN
    RAISE EXCEPTION 'Cannot vote on your own post';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_poll_vote_counts()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.poll_options
    SET vote_count = vote_count + 1
    WHERE id = NEW.option_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.poll_options
    SET vote_count = GREATEST(vote_count - 1, 0)
    WHERE id = OLD.option_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user_interests(
  p_user_id uuid,
  p_interests text[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.user_interests WHERE user_id = p_user_id;
  INSERT INTO public.user_interests (user_id, interest)
  SELECT p_user_id, unnest(p_interests);
END;
$$;

CREATE OR REPLACE FUNCTION public.award_badges_on_milestone()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_post_count integer;
BEGIN
  SELECT COUNT(*) INTO v_post_count
  FROM public.posts
  WHERE user_id = NEW.user_id AND deleted_at IS NULL;

  IF v_post_count >= 1 THEN
    INSERT INTO public.user_badges (user_id, badge_id)
    SELECT NEW.user_id, id FROM public.badges WHERE slug = 'first_post'
    ON CONFLICT DO NOTHING;
  END IF;

  IF v_post_count >= 10 THEN
    INSERT INTO public.user_badges (user_id, badge_id)
    SELECT NEW.user_id, id FROM public.badges WHERE slug = 'active_poster'
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_post_xp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.award_xp(NEW.user_id, 10, 'post_created', NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_reaction_xp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.award_xp(NEW.user_id, 2, 'reaction_given', NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_comment_xp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.award_xp(NEW.user_id, 5, 'comment_created', NEW.id);
  END IF;
  RETURN NEW;
END;
$$;
