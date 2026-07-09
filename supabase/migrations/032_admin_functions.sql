-- MIGRATION 032: Admin dashboard fixes

-- ============================================
-- #1: Create get_posts_last_7_days function
-- ============================================
CREATE OR REPLACE FUNCTION public.get_posts_last_7_days()
RETURNS TABLE (day DATE, count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  RETURN QUERY
  SELECT
    d.day::date,
    COALESCE(p.cnt, 0)::bigint AS count
  FROM generate_series(
    (CURRENT_DATE - INTERVAL '6 days')::date,
    CURRENT_DATE::date,
    '1 day'::interval
  ) AS d(day)
  LEFT JOIN LATERAL (
    SELECT COUNT(*)::bigint AS cnt
    FROM posts
    WHERE DATE(created_at) = d.day
  ) p ON true
  ORDER BY d.day;
END;
$$;

-- ============================================
-- #2: Create get_top_zones function
-- ============================================
CREATE OR REPLACE FUNCTION public.get_top_zones()
RETURNS TABLE (zone_name TEXT, post_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(z.name, 'Unknown')::text AS zone_name,
    COUNT(p.id)::bigint AS post_count
  FROM posts p
  LEFT JOIN zones z ON z.id = p.zone_id
  WHERE p.created_at > NOW() - INTERVAL '30 days'
  GROUP BY z.name
  ORDER BY post_count DESC
  LIMIT 10;
END;
$$;
