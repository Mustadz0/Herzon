-- MIGRATION 050: Tighten get_blocked_user_ids to only return info for the
-- caller (auth.uid()). Previously any authenticated user could pass any
-- check_user_id and enumerate who blocked them — this leaks privacy.

CREATE OR REPLACE FUNCTION get_blocked_user_ids(check_user_id uuid DEFAULT auth.uid())
RETURNS SETOF uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Refuse to expose blocking relationships for other users.
  IF check_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Permission denied: blocked-user list is private';
  END IF;
  RETURN QUERY
    SELECT blocked_id FROM blocked_users WHERE blocker_id = check_user_id;
  -- No longer returns the second branch (who blocks me) — that information
  -- is enumerated implicitly via feed filters, never exposed as data.
END;
$$;

COMMENT ON FUNCTION get_blocked_user_ids(uuid) IS
  'Returns IDs that the calling user has blocked. Other users cannot probe.';
