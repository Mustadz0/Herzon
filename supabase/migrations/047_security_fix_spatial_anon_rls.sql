-- MIGRATION 047: Fix Supabase Security Advisor warnings
-- Run this in Supabase Dashboard SQL Editor
-- Fixes: spatial_ref_sys RLS, anon function exposure, anon table access

begin;

-- ============================================
-- 🔴 ERROR: spatial_ref_sys — no RLS
-- ============================================
ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_read_spatial_ref_sys" ON public.spatial_ref_sys;
CREATE POLICY "allow_read_spatial_ref_sys"
  ON public.spatial_ref_sys FOR SELECT USING (true);

-- ============================================
-- 🟠 WARN: Function — create_post_with_location exposed to anon
-- ============================================
REVOKE EXECUTE ON FUNCTION public.create_post_with_location(
  p_user_id text,
  p_content text,
  p_media_urls text[],
  p_media_type text,
  p_lat double precision,
  p_lng double precision,
  p_context_tag text,
  p_sticker_id text,
  p_zone_id text,
  p_poll jsonb
) FROM anon;

-- ============================================
-- 🟠 WARN: pgcrypto digest exposed to anon
-- ============================================
REVOKE EXECUTE ON FUNCTION public.digest(text, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.digest(bytea, text) FROM anon, public;

-- ============================================
-- 🟠 WARN: PostGIS st_estimatedextent exposed to anon
-- ============================================
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text) FROM anon, public;

-- ============================================
-- 🟠 WARN: update_user_interests exposed to anon
-- ============================================
REVOKE EXECUTE ON FUNCTION public.update_user_interests(text, text[]) FROM anon;

-- ============================================
-- 🟡 WARN: crash_reports — RLS WITH CHECK always true
-- ============================================
DROP POLICY IF EXISTS "Users can insert own crash reports" ON public.crash_reports;
CREATE POLICY "Users can insert own crash reports"
  ON public.crash_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Admins can view crash reports" ON public.crash_reports;
CREATE POLICY "Admins can view crash reports"
  ON public.crash_reports FOR SELECT
  TO authenticated
  USING (public.current_user_is_admin());

-- ============================================
-- 🟡 WARN: Anonymous access on key tables
-- Restrict INSERT/UPDATE/DELETE to authenticated users
-- Preserve SELECT for anon where appropriate (public reads)
-- ============================================

-- Helper: drop permissive anon policies on a table
CREATE OR REPLACE FUNCTION public._fix_table_anon_policies(tbl text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  rec record;
BEGIN
  FOR rec IN
    SELECT polname, polcmd
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = tbl
      AND roles::text = '{anon}'
      AND (polcmd = 'INSERT' OR polcmd = 'UPDATE' OR polcmd = 'DELETE')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', rec.polname, tbl);
  END LOOP;

  -- Add an authenticated-only write policy if one doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = tbl
      AND roles::text LIKE '%authenticated%'
      AND (polcmd = 'INSERT' OR polcmd = 'UPDATE' OR polcmd = 'DELETE')
  ) THEN
    EXECUTE format(
      'CREATE POLICY "auth_write_%s" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (auth.uid() IS NOT NULL)',
      tbl, tbl
    );
  END IF;
END;
$$;

-- Apply to known user-writable tables
SELECT public._fix_table_anon_policies(t)
FROM (VALUES
  ('posts'), ('comments'), ('reactions'), ('reports'),
  ('messages'), ('conversations'), ('conversation_participants'),
  ('stories'), ('story_views'), ('notifications'),
  ('device_tokens'), ('user_interests'), ('hidden_posts'),
  ('blocked_users'), ('marketplace_listings'), ('ride_shares'),
  ('checkins'), ('badges'), ('pages'), ('page_followers'),
  ('ab_test_assignments'), ('poll_votes'),
  ('crash_reports')
) AS t(t);

-- Clean up helper
DROP FUNCTION IF EXISTS public._fix_table_anon_policies(text);

commit;
