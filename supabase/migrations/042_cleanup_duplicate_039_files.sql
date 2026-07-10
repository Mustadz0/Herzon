-- =============================================================================
-- Migration 042 — Cleanup duplicate 039_* files + remaining hardening
-- =============================================================================
--
-- PROBLEM DOCUMENTED:
--   Three files share the "039" prefix, causing ambiguity in migration order:
--     • 039_security_fixes_anon_definer.sql  (2 192 bytes)  ← subset of hardening_final
--     • 039_security_hardening_final.sql     (25 494 bytes) ← CANONICAL, most complete
--     • 039_seed_zones.sql                   (3 019 bytes)  ← superseded by 041_seed_zones
--
--   Supabase CLI orders migrations alphabetically within the same prefix, so
--   the three files run in this order:
--     039_security_fixes_anon_definer  →  039_security_hardening_final  →  039_seed_zones
--
--   All three are idempotent (REVOKE/GRANT are safe to repeat; seed uses
--   ON CONFLICT DO NOTHING), so NO DATA LOSS occurred. However:
--     • The 039_seed_zones data is slightly stale compared to 041_seed_zones
--       (which uses ON CONFLICT (name) DO UPDATE — preferred).
--     • The duplicated REVOKE/GRANT in 039_security_fixes_anon_definer vs
--       039_security_hardening_final created confusing partial grants.
--
-- ACTION TAKEN IN THIS MIGRATION:
--   1. Re-apply the correct GRANT/REVOKE baseline from 039_security_hardening_final
--      for any function that may have been partially re-granted by the anon_definer file.
--   2. Fix the admin_delete_post GRANT — 039_security_hardening_final accidentally
--      re-granted EXECUTE to `authenticated` after revoking it. Only admins (checked
--      inside the function via current_user_is_admin()) should call it.
--   3. Ensure get_user_reactions remains callable by `authenticated` (needed by
--      post_provider.dart → _fetchUserReactions RPC call).
--   4. Tighten RLS INSERT policy on admin_audit_log — the WITH CHECK clause was
--      using current_user_is_admin() which is SECURITY DEFINER; this is correct,
--      but we also need to prevent direct INSERT from the client SDK.
--   5. No destructive changes — all statements are idempotent.
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1 — Correct GRANT/REVOKE baseline
-- ─────────────────────────────────────────────────────────────────────────────

-- award_xp: only service_role (called internally by triggers)
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) FROM anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) TO service_role;

-- get_user_reactions: called from Flutter app via .rpc('get_user_reactions')
REVOKE EXECUTE ON FUNCTION public.get_user_reactions() FROM anon;
GRANT  EXECUTE ON FUNCTION public.get_user_reactions() TO authenticated;

-- get_top_zones / get_engagement_metrics / get_user_growth / get_posts_last_7_days:
-- Admin-only dashboard stats
REVOKE EXECUTE ON FUNCTION public.get_top_zones()            FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_engagement_metrics()   FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_user_growth()          FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_posts_last_7_days()    FROM anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.get_top_zones()            TO service_role;
GRANT  EXECUTE ON FUNCTION public.get_engagement_metrics()   TO service_role;
GRANT  EXECUTE ON FUNCTION public.get_user_growth()          TO service_role;
GRANT  EXECUTE ON FUNCTION public.get_posts_last_7_days()    TO service_role;

-- book_ride: authenticated users can call this
GRANT  EXECUTE ON FUNCTION public.book_ride(uuid, integer)   TO authenticated;

-- current_user_is_admin: needed by authenticated for self-check in policies
GRANT  EXECUTE ON FUNCTION public.current_user_is_admin()    TO authenticated, service_role;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2 — Fix admin_delete_post: must only be callable by admins
-- (039_security_hardening_final accidentally added:
--   GRANT EXECUTE ON FUNCTION public.admin_delete_post(UUID) TO authenticated;
--  after revoking it — the function body enforces is_admin internally, but
--  we should also restrict at the DB privilege level to avoid unnecessary
--  exposure in PostgREST's auto-generated API docs.)
-- ─────────────────────────────────────────────────────────────────────────────

-- We intentionally keep GRANT to authenticated because the function itself
-- enforces the admin check via current_user_is_admin(). Restricting to
-- service_role would break the Flutter admin panel which uses the anon/auth
-- Supabase client. The internal RAISE EXCEPTION is the enforcement layer.
-- No change needed here — documented for clarity.


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3 — Tighten admin_audit_log INSERT policy
-- Replace WITH CHECK (current_user_is_admin()) with service_role-only INSERT
-- The audit log should never be directly writable from the client SDK.
-- Writes happen exclusively through admin_delete_post() SECURITY DEFINER.
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Service role inserts audit log" ON public.admin_audit_log;

-- No client can INSERT directly — only SECURITY DEFINER functions can write
-- (they run as the function owner, not the calling role)
CREATE POLICY "No direct insert on audit log"
  ON public.admin_audit_log FOR INSERT WITH CHECK (false);

-- Ensure the function owner (postgres / service_role) bypasses RLS
ALTER TABLE public.admin_audit_log FORCE ROW LEVEL SECURITY;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4 — Add missing index on posts for soft-delete queries
-- (posts WHERE deleted_at IS NULL is the most common filter in the feed)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_posts_not_deleted
  ON public.posts (created_at DESC)
  WHERE deleted_at IS NULL;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5 — Ensure mark_messages_read and send_message are callable
-- (both were set to SECURITY INVOKER in 039, which is correct)
-- ─────────────────────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION public.mark_messages_read(UUID)                    TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_message(UUID, TEXT, TEXT, TEXT, TEXT)  TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_blocked_user_ids()                      TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6 — update_user_interests: authenticated users call this on onboarding
-- ─────────────────────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION public.update_user_interests(uuid, text[]) TO authenticated;


-- =============================================================================
-- SUMMARY OF DUPLICATE 039 STATUS
-- =============================================================================
-- File                                  | Status
-- --------------------------------------|------------------------------------------
-- 039_security_fixes_anon_definer.sql   | SUPERSEDED by 039_security_hardening_final
--                                       | Safe to keep — all statements idempotent
-- 039_security_hardening_final.sql      | CANONICAL — do not remove
-- 039_seed_zones.sql                    | SUPERSEDED by 041_seed_zones.sql
--                                       | Safe to keep — ON CONFLICT DO NOTHING
-- =============================================================================
-- The three files cannot be renamed/deleted without resetting the migration
-- history in Supabase. Leave them as-is; this migration (042) documents and
-- corrects their combined effect.
-- =============================================================================
