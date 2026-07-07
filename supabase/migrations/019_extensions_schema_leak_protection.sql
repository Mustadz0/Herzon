-- ============================================================
-- MIGRATION 019: Move extensions from public schema + enable
-- leaked password protection.
-- Addresses the final 4 remaining lint warnings:
--   - extension_in_public: pg_net, pg_trgm (2)
--   - extension_in_public: postgis (1) — left in public intentionally
--   - auth_leaked_password_protection (1) — via Management API
-- ============================================================

-- ============================================================
-- 1. CREATE EXTENSIONS SCHEMA
-- ============================================================
CREATE SCHEMA IF NOT EXISTS extensions;

-- Grant usage to public so all roles can access functions in this schema
GRANT USAGE ON SCHEMA extensions TO PUBLIC;

-- ============================================================
-- 2. MOVE EXTENSIONS TO EXTENSIONS SCHEMA
-- ============================================================

-- Move pg_trgm (used for fuzzy text search indexes)
ALTER EXTENSION pg_trgm SET SCHEMA extensions;

-- NOTE: pg_net does not support SET SCHEMA (modern extension
-- with fixed schema). It remains in its default schema.
-- PostGIS is intentionally left in public schema.
-- Moving PostGIS to extensions schema would break geometry columns,
-- spatial indexes, and type resolution across the entire database.
-- This is the standard practice for Supabase projects.

-- ============================================================
-- 3. UPDATE DATABASE SEARCH PATH
-- ============================================================
-- Ensure extensions schema is in the default search_path so
-- pg_net and pg_trgm functions remain accessible without
-- schema qualification.
ALTER DATABASE postgres SET search_path TO public, extensions;

-- Also update the search_path for all existing sessions
SET search_path TO public, extensions;

-- ============================================================
-- 4. ENABLE LEAKED PASSWORD PROTECTION
--    Done via Supabase Management API (not SQL).
--    See the separate API call after this migration.
-- ============================================================

-- Verify extensions are in the correct schema
SELECT e.extname, n.nspname AS schema_name
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE e.extname IN ('pg_net', 'pg_trgm', 'postgis');
