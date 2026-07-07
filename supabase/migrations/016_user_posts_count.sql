-- MIGRATION 016: Add get_user_posts_count helper RPC
-- Needed by home screen profile tab to show live post count.

CREATE OR REPLACE FUNCTION get_user_posts_count(target_user_id uuid)
RETURNS int
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public'
AS $func$
  SELECT count(*)::int FROM posts WHERE user_id = target_user_id;
$func$;

COMMENT ON FUNCTION get_user_posts_count IS 'Returns the total number of posts for a user (used by profile tab).';
