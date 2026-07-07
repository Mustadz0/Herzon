-- MIGRATION 029: Fix 5 admin/ride errors
-- 1. Add last_active_at to profiles
-- 2. Add zone_id FK on posts → zones
-- 3. Add FK constraints on reports → profiles
-- 4. Create get_user_growth function
-- 5. Create get_engagement_metrics function

-- ============================================
-- #1: last_active_at column on profiles
-- ============================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_active_at timestamptz DEFAULT now();

CREATE INDEX IF NOT EXISTS profiles_last_active_idx ON public.profiles(last_active_at);

-- ============================================
-- #2: zone_id on posts → zones FK
-- ============================================
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS zone_id uuid;

-- Add FK only if zones table exists and the FK doesn't already exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'zones' AND table_schema = 'public') THEN
    -- Drop existing constraint if any
    ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_zone_id_fkey;
    ALTER TABLE public.posts
      ADD CONSTRAINT posts_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS posts_zone_idx ON public.posts(zone_id) WHERE zone_id IS NOT NULL;

-- ============================================
-- #3: FK constraints on reports → profiles
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reports' AND table_schema = 'public') THEN
    -- Add FK for reporter_id if not exists
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'reports_reporter_id_fkey' AND table_name = 'reports'
    ) THEN
      ALTER TABLE public.reports
        ADD CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;

    -- Add FK for reported_user_id if not exists
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'reports_reported_user_id_fkey' AND table_name = 'reports'
    ) THEN
      ALTER TABLE public.reports
        ADD CONSTRAINT reports_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- ============================================
-- #4: get_user_growth function
-- ============================================
CREATE OR REPLACE FUNCTION public.get_user_growth()
RETURNS TABLE (
  month DATE,
  new_users BIGINT,
  total_users BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  WITH monthly AS (
    SELECT
      date_trunc('month', created_at)::date AS m,
      COUNT(*)::bigint AS new_count
    FROM profiles
    GROUP BY 1
  ),
  cumulative AS (
    SELECT
      m,
      new_count,
      SUM(new_count) OVER (ORDER BY m) AS running_total
    FROM monthly
  )
  SELECT m AS month, new_count AS new_users, running_total AS total_users
  FROM cumulative
  ORDER BY m DESC
  LIMIT 12;
END;
$$;

COMMENT ON FUNCTION public.get_user_growth() IS 'Returns monthly new user count and cumulative total for the last 12 months.';

-- ============================================
-- #5: get_engagement_metrics function
-- ============================================
CREATE OR REPLACE FUNCTION public.get_engagement_metrics()
RETURNS TABLE (
  avg_likes NUMERIC,
  avg_comments NUMERIC,
  avg_shares NUMERIC,
  total_reactions BIGINT,
  total_comments BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  post_count BIGINT;
BEGIN
  SELECT COUNT(*) INTO post_count FROM posts;

  RETURN QUERY
  SELECT
    CASE WHEN post_count > 0 THEN
      (SELECT COALESCE(SUM(
        (COALESCE(reaction_counts->>'like','0'))::int
      ), 0)::numeric / post_count FROM posts)
    ELSE 0::numeric END AS avg_likes,
    CASE WHEN post_count > 0 THEN
      (SELECT COUNT(*)::numeric / post_count FROM comments)
    ELSE 0::numeric END AS avg_comments,
    0::numeric AS avg_shares,
    (SELECT COALESCE(SUM(
      (COALESCE(reaction_counts->>'like','0'))::int
    ), 0)::bigint FROM posts) AS total_reactions,
    (SELECT COUNT(*)::bigint FROM comments) AS total_comments;
END;
$$;

COMMENT ON FUNCTION public.get_engagement_metrics() IS 'Returns aggregate engagement metrics for the admin dashboard.';
