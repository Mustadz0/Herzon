-- ============================================================
-- MIGRATION 020: Fix security_definer_view + rls_disabled_in_public
-- ============================================================

-- ============================================================
-- 1. Fix post_actors view: SECURITY DEFINER → SECURITY INVOKER
-- ============================================================
CREATE OR REPLACE VIEW public.post_actors
WITH (security_invoker = true)
AS
SELECT
    p.id,
    p.user_id,
    p.actor_type,
    p.actor_id,
    COALESCE(pag.name, pr.display_name) AS display_name,
    COALESCE(pag.avatar_url, pr.avatar_url) AS avatar_url
FROM posts p
    LEFT JOIN profiles pr ON p.user_id = pr.id
    LEFT JOIN pages pag ON p.actor_id = pag.id AND p.actor_type = 'page'
WHERE
    p.actor_type = 'page'
    OR (p.actor_type = 'user' AND p.user_id = pr.id);

-- ============================================================
-- 2. Enable RLS on PostGIS spatial_ref_sys table
--    This is a read-only reference table with coordinate system
--    definitions. We enable RLS and add a permissive policy for
--    authenticated users so spatial queries still work.
--    Must run as superuser via direct SQL query.
-- ============================================================
-- Done via Management API SQL query (see below) because the
-- migration runner lacks the necessary table ownership. The
-- equivalent SQL is:
--
--   ALTER TABLE spatial_ref_sys OWNER TO current_user;
--   ALTER TABLE spatial_ref_sys ENABLE ROW LEVEL SECURITY;
--   CREATE POLICY "authenticated_can_read_spatial_ref_sys"
--   ON spatial_ref_sys FOR SELECT TO authenticated USING (true);
--   REVOKE INSERT, UPDATE, DELETE ON spatial_ref_sys FROM anon, authenticated;
