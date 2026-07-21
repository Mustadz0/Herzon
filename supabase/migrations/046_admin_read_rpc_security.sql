-- MIGRATION 046: Admin read operations as SECURITY DEFINER RPCs
-- Replaces client-side _verifyAdmin() + direct table queries
-- All admin reads now go through checked RPCs

-- ============================================
-- #1: Admin get dashboard stats
-- ============================================
CREATE OR REPLACE FUNCTION public.admin_get_stats()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  result jsonb;
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  SELECT jsonb_build_object(
    'total_users',    (SELECT count(*) FROM profiles),
    'total_posts',    (SELECT count(*) FROM posts),
    'pending_reports',(SELECT count(*) FROM reports WHERE status = 'pending'),
    'active_today',   (SELECT count(*) FROM profiles WHERE last_active_at >= now() - interval '24 hours')
  ) INTO result;

  RETURN result;
END;
$$;

-- ============================================
-- #2: Admin search users
-- ============================================
CREATE OR REPLACE FUNCTION public.admin_get_users(search_term text DEFAULT NULL)
RETURNS jsonb[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  results jsonb[];
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  IF search_term IS NOT NULL AND search_term <> '' THEN
    SELECT array_agg(row_to_json(t)::jsonb) INTO results
    FROM (
      SELECT id, username, display_name, avatar_url, is_admin, created_at, last_active_at
      FROM profiles
      WHERE display_name ILIKE '%' || search_term || '%'
         OR username ILIKE '%' || search_term || '%'
      ORDER BY created_at DESC
    ) t;
  ELSE
    SELECT array_agg(row_to_json(t)::jsonb) INTO results
    FROM (
      SELECT id, username, display_name, avatar_url, is_admin, created_at, last_active_at
      FROM profiles
      ORDER BY created_at DESC
    ) t;
  END IF;

  RETURN COALESCE(results, ARRAY[]::jsonb[]);
END;
$$;

-- ============================================
-- #3: Admin get all posts with profiles
-- ============================================
CREATE OR REPLACE FUNCTION public.admin_get_posts(search_term text DEFAULT NULL)
RETURNS jsonb[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  results jsonb[];
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  IF search_term IS NOT NULL AND search_term <> '' THEN
    SELECT array_agg(row_to_json(t)::jsonb) INTO results
    FROM (
      SELECT p.*, 
             jsonb_build_object(
               'username', pr.username,
               'display_name', pr.display_name,
               'avatar_url', pr.avatar_url
             ) AS profiles
      FROM posts p
      LEFT JOIN profiles pr ON pr.id = p.user_id
      WHERE p.content ILIKE '%' || search_term || '%'
      ORDER BY p.created_at DESC
    ) t;
  ELSE
    SELECT array_agg(row_to_json(t)::jsonb) INTO results
    FROM (
      SELECT p.*,
             jsonb_build_object(
               'username', pr.username,
               'display_name', pr.display_name,
               'avatar_url', pr.avatar_url
             ) AS profiles
      FROM posts p
      LEFT JOIN profiles pr ON pr.id = p.user_id
      ORDER BY p.created_at DESC
    ) t;
  END IF;

  RETURN COALESCE(results, ARRAY[]::jsonb[]);
END;
$$;

-- ============================================
-- #4: Admin get reports with reporter/user names
-- ============================================
CREATE OR REPLACE FUNCTION public.admin_get_reports()
RETURNS jsonb[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  results jsonb[];
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  SELECT array_agg(row_to_json(t)::jsonb) INTO results
  FROM (
    SELECT r.*,
           reporter.display_name AS reporter_name,
           reported.display_name AS reported_user_name
    FROM reports r
    LEFT JOIN profiles reporter ON reporter.id = r.reporter_id
    LEFT JOIN profiles reported ON reported.id = r.reported_user_id
    ORDER BY r.created_at DESC
  ) t;

  RETURN COALESCE(results, ARRAY[]::jsonb[]);
END;
$$;

-- ============================================
-- #5: Admin toggle feature flag (replaces direct upsert)
-- ============================================
CREATE OR REPLACE FUNCTION public.admin_toggle_feature_flag(flag_key text, is_enabled boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  INSERT INTO feature_config (flag_key, is_enabled, updated_at)
  VALUES (flag_key, is_enabled, now())
  ON CONFLICT (flag_key) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    updated_at = now();
END;
$$;

-- ============================================
-- #6: RLS on feature_config — admin-only writes
-- ============================================
ALTER TABLE feature_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_write_feature_config" ON feature_config;
CREATE POLICY "admin_write_feature_config" ON feature_config
  FOR ALL
  TO authenticated
  USING (public.current_user_is_admin())
  WITH CHECK (public.current_user_is_admin());

DROP POLICY IF EXISTS "all_read_feature_config" ON feature_config;
CREATE POLICY "all_read_feature_config" ON feature_config
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- #7: Grant execute to authenticated
-- ============================================
GRANT EXECUTE ON FUNCTION public.admin_get_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_users(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_posts(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_reports() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_toggle_feature_flag(text, boolean) TO authenticated;
