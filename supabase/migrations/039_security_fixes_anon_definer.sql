-- ============================================================
-- Migration 039: Security Fixes
-- Revoke EXECUTE on SECURITY DEFINER functions from anon/public
-- Note: spatial_ref_sys RLS is a PostGIS system table owned by
--       the superuser; handled separately via Supabase dashboard.
-- ============================================================

-- Revoke EXECUTE from anon + public on all exposed SECURITY DEFINER functions
REVOKE EXECUTE ON FUNCTION public.award_badges_on_milestone() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.book_ride(uuid, integer) FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.delete_expired_stories() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_engagement_metrics() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_posts_last_7_days() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_top_zones() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_user_growth() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_user_reactions() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_comment_notification() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_comment_xp() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_follow_notification() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_post_xp() FROM anon, PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_notification() FROM anon, PUBLIC;

-- Grant EXECUTE back to authenticated only for user-facing RPC functions
GRANT EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.book_ride(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_engagement_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_posts_last_7_days() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_top_zones() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_growth() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_reactions() TO authenticated;
