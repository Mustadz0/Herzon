-- Migration 042: Fix functions to use inline blocked user checks
-- (get_blocked_user_ids(uuid) was dropped; new parameterless version exists)

-- ── Fix get_suggested_posts (old signature used by app) ─────
DROP FUNCTION IF EXISTS public.get_suggested_posts(double precision, double precision, double precision, integer, uuid);

CREATE OR REPLACE FUNCTION public.get_suggested_posts(
  p_user_lat double precision,
  p_user_lng double precision,
  p_radius_meters double precision DEFAULT 500,
  p_limit integer DEFAULT 20,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS TABLE(
  id uuid, user_id uuid, content text,
  media_urls text[], context_tag text,
  comment_count integer, relevance_score double precision
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE user_interest_tags text[];
BEGIN
  SELECT array_agg(tag) INTO user_interest_tags
  FROM (SELECT ui.tag FROM public.user_interests ui WHERE ui.user_id = p_user_id ORDER BY ui.weight DESC LIMIT 10) sub;
  RETURN QUERY
  SELECT p.id, p.user_id, p.content, p.media_urls, p.context_tag,
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::int AS comment_count,
    (0.6 * COALESCE(CASE WHEN p.context_tag IS NOT NULL AND p.context_tag = ANY(user_interest_tags) THEN 1.0 ELSE 0.2 END, 0.0)) AS relevance_score
  FROM public.posts p
  WHERE ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography, p_radius_meters)
    AND p.deleted_at IS NULL
    AND p.user_id NOT IN (
      SELECT blocked_id FROM public.blocked_users WHERE blocker_id = p_user_id
      UNION
      SELECT blocker_id FROM public.blocked_users WHERE blocked_id = p_user_id
    )
  ORDER BY relevance_score DESC, p.created_at DESC
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_suggested_posts(double precision, double precision, double precision, integer, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_suggested_posts(double precision, double precision, double precision, integer, uuid) TO authenticated;

-- ── Fix get_nearby_posts (old signature used by app) ───────
-- Add blocked users filter + sticker_id
DROP FUNCTION IF EXISTS public.get_nearby_posts(double precision, double precision, double precision, integer, integer);

CREATE OR REPLACE FUNCTION public.get_nearby_posts(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision DEFAULT 2000,
  page integer DEFAULT 1,
  page_size integer DEFAULT 20
)
RETURNS TABLE(
  id uuid, user_id uuid, content text,
  media_urls text[], media_type text,
  context_tag text, sticker_id text,
  comment_count bigint, distance double precision
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
  SELECT p.id, p.user_id, p.content, p.media_urls, p.media_type,
    p.context_tag, p.sticker_id,
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::bigint AS comment_count,
    ST_Distance(p.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance
  FROM public.posts p
  JOIN public.profiles pr ON pr.id = p.user_id
  WHERE ST_DWithin(p.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
    AND p.deleted_at IS NULL
    AND p.user_id NOT IN (
      SELECT blocked_id FROM public.blocked_users WHERE blocker_id = v_uid
      UNION
      SELECT blocker_id FROM public.blocked_users WHERE blocked_id = v_uid
    )
  ORDER BY p.created_at DESC
  LIMIT page_size OFFSET (page - 1) * page_size;
END;
$$;

REVOKE ALL ON FUNCTION public.get_nearby_posts(double precision, double precision, double precision, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_nearby_posts(double precision, double precision, double precision, integer, integer) TO authenticated;

-- ── Keep the p_user_id/p_lat/p_lng variant for any future callers ──
DROP FUNCTION IF EXISTS public.get_nearby_posts(uuid, double precision, double precision, double precision, integer, integer);
DROP FUNCTION IF EXISTS public.get_suggested_posts(uuid, integer, integer);
