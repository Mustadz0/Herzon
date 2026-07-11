-- Migration 045: Fix security issues from Explorer Zones + audit report
-- 1. Revoke anon from new explorer functions
-- 2. Restrict refresh_zone_heat to service_role only
-- 3. Restrict validate_privacy_settings to service_role only
-- 4. Hide spatial_ref_sys from PostgREST API

-- ─────────────────────────────────────────────────────────────
-- 1. Revoke PUBLIC + anon EXECUTE from explorer RPCs
-- ─────────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.get_nearby_zones(double precision, double precision, integer) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_zone_posts(text, double precision, double precision, integer, integer) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.refresh_zone_heat() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.validate_privacy_settings() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.get_nearby_zones(double precision, double precision, integer) TO authenticated;
GRANT  EXECUTE ON FUNCTION public.get_zone_posts(text, double precision, double precision, integer, integer) TO authenticated;

-- ─────────────────────────────────────────────────────────────
-- 2. Restrict refresh_zone_heat to service_role only
-- ─────────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.refresh_zone_heat() FROM authenticated;
GRANT  EXECUTE ON FUNCTION public.refresh_zone_heat() TO service_role;

-- ─────────────────────────────────────────────────────────────
-- 3. Restrict validate_privacy_settings to service_role only
-- ─────────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.validate_privacy_settings() FROM authenticated;
GRANT  EXECUTE ON FUNCTION public.validate_privacy_settings() TO service_role;

-- ─────────────────────────────────────────────────────────────
-- 4. spatial_ref_sys (PostGIS) — cannot enable RLS (superuser-owned)
--    Resolution: currently blocked; requires moving PostGIS to extensions schema.
--    Manually exclude spatial_ref_sys from PostgREST via Supabase Dashboard:
--    Settings → API → PostgREST → Expose schemas: just "public"
--    OR use `REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM anon` if acceptable.
-- ─────────────────────────────────────────────────────────────
-- ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;  -- fails (superuser-owned)

-- ─────────────────────────────────────────────────────────────
-- 5. Revoke anon EXECUTE from PostGIS functions
-- ─────────────────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN ('st_estimatedextent', 'st_estimated_2d_aggr')
      AND has_function_privilege('anon', p.oid, 'EXECUTE')
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM anon', r.nspname, r.proname, r.args);
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM PUBLIC', r.nspname, r.proname, r.args);
  END LOOP;
END $$;
