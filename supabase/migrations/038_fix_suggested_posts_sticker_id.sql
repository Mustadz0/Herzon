-- MIGRATION 038: Add sticker_id to get_suggested_posts RPC

DROP FUNCTION IF EXISTS public.get_suggested_posts(double precision, double precision, double precision, integer, uuid);

CREATE OR REPLACE FUNCTION public.get_suggested_posts(
  p_user_lat double precision, p_user_lng double precision,
  p_radius_meters double precision DEFAULT 2000, p_limit int DEFAULT 20, p_user_id uuid DEFAULT auth.uid()
)
RETURNS TABLE (id uuid, user_id uuid, content text, media_urls text[], context_tag text,
  latitude double precision, longitude double precision, created_at timestamptz,
  updated_at timestamptz, reaction_counts jsonb, comment_count int, share_count int,
  username text, display_name text, avatar_url text,
  distance_meters double precision, relevance_score float,
  sticker_id text)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE user_interest_tags text[];
BEGIN
  SELECT array_agg(tag) INTO user_interest_tags
  FROM (SELECT ui.tag FROM public.user_interests ui WHERE ui.user_id = p_user_id ORDER BY ui.weight DESC LIMIT 10) sub;
  RETURN QUERY
  SELECT p.id, p.user_id, p.content, p.media_urls, p.context_tag,
    ST_Y(p.location::geometry)::double precision, ST_X(p.location::geometry)::double precision,
    p.created_at, now()::timestamptz as updated_at, p.reaction_counts,
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::int as comment_count,
    0::int as share_count,
    pr.username, pr.display_name, pr.avatar_url,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography)::double precision,
    (0.4 * (1.0 - (ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography) / p_radius_meters)) +
     0.6 * COALESCE(CASE WHEN p.context_tag IS NOT NULL AND p.context_tag = ANY(user_interest_tags) THEN 1.0 ELSE 0.2 END, 0.0)) AS relevance_score,
    p.sticker_id
  FROM public.posts p
  JOIN public.profiles pr ON p.user_id = pr.id
  WHERE ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography, p_radius_meters)
    AND p.user_id NOT IN (SELECT get_blocked_user_ids(p_user_id))
  ORDER BY relevance_score DESC, p.created_at DESC
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION public.get_suggested_posts IS 'Suggested posts ranked by relevance. SECURITY INVOKER.';
