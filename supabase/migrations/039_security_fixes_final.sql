-- ============================================================
-- Migration 039: Security Fixes Final
-- Fixes all security advisors:
-- 1. Revoke anon EXECUTE on SECURITY DEFINER functions
-- 2. Enable RLS on spatial_ref_sys
-- 3. Fix mutable search_path on update_user_interests
-- ============================================================

-- ============================================================
-- 1. REVOKE anon EXECUTE on all SECURITY DEFINER functions
--    that should NOT be callable without authentication
-- ============================================================

-- Gamification
REVOKE EXECUTE ON FUNCTION public.award_badges_on_milestone() FROM anon;
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_comment_xp() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_post_xp() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_xp() FROM anon;

-- Rides
REVOKE EXECUTE ON FUNCTION public.book_ride(uuid, integer) FROM anon;

-- Stories
REVOKE EXECUTE ON FUNCTION public.delete_expired_stories() FROM anon;

-- Notifications
REVOKE EXECUTE ON FUNCTION public.handle_comment_notification() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_follow_notification() FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_notification() FROM anon;

-- Admin / Internal functions
REVOKE EXECUTE ON FUNCTION public.get_engagement_metrics() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_posts_last_7_days() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_top_zones() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_growth() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_reactions() FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM anon;

-- Auth / User management
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;

-- Votes
REVOKE EXECUTE ON FUNCTION public.prevent_vote_own_post() FROM anon;

-- PostGIS functions exposed via RPC (revoke from both anon and public)
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text) FROM PUBLIC;

-- Also revoke from authenticated where appropriate (admin-only functions)
REVOKE EXECUTE ON FUNCTION public.get_engagement_metrics() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_posts_last_7_days() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_top_zones() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_user_growth() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM authenticated;

-- Re-grant authenticated access to functions that SHOULD work when logged in
GRANT EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.book_ride(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_reactions() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_expired_stories() TO service_role;
GRANT EXECUTE ON FUNCTION public.award_badges_on_milestone() TO service_role;
GRANT EXECUTE ON FUNCTION public.rls_auto_enable() TO service_role;

-- ============================================================
-- 2. Enable RLS on spatial_ref_sys (PostGIS table)
-- ============================================================

ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read spatial reference systems (needed for PostGIS queries)
DROP POLICY IF EXISTS "Allow authenticated read spatial_ref_sys" ON public.spatial_ref_sys;
CREATE POLICY "Allow authenticated read spatial_ref_sys"
  ON public.spatial_ref_sys
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow service_role full access
DROP POLICY IF EXISTS "Allow service_role full access spatial_ref_sys" ON public.spatial_ref_sys;
CREATE POLICY "Allow service_role full access spatial_ref_sys"
  ON public.spatial_ref_sys
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- 3. Fix mutable search_path on update_user_interests
-- ============================================================

ALTER FUNCTION public.update_user_interests()
  SET search_path = public, pg_temp;

-- ============================================================
-- Done
-- ============================================================
