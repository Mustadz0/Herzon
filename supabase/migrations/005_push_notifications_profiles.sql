-- Enable pg_net for async HTTP calls from triggers
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Device tokens table for FCM push notifications
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token text NOT NULL,
  platform text NOT NULL DEFAULT 'android',
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, platform)
);

CREATE INDEX IF NOT EXISTS device_tokens_user_id_idx ON public.device_tokens (user_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own device tokens"
  ON public.device_tokens FOR ALL USING (auth.uid() = user_id);

-- Auto-delete stories older than 24 hours
CREATE OR REPLACE FUNCTION public.delete_expired_stories()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.stories WHERE created_at < now() - interval '24 hours';
END;
$$;

-- Manual cleanup: SELECT public.delete_expired_stories();
-- Schedule via pg_cron (Supabase dashboard > Database > Extensions > pg_cron):
-- SELECT cron.schedule('delete-expired-stories', '0 * * * *', $$SELECT public.delete_expired_stories();$$);

-- Update get_active_stories to filter expired stories (adds 24h time window)
DROP FUNCTION IF EXISTS public.get_active_stories(double precision, double precision, double precision);
CREATE OR REPLACE FUNCTION public.get_active_stories(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 2000
)
RETURNS TABLE(
  id uuid,
  user_id uuid,
  media_url text,
  media_type text,
  text_overlay text,
  created_at timestamptz,
  username text,
  display_name text,
  avatar_url text,
  distance double precision
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.user_id,
    s.media_url,
    s.media_type,
    s.text_overlay,
    s.created_at,
    p.username,
    p.display_name,
    p.avatar_url,
    ST_DistanceSphere(
      s.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) as distance
  FROM stories s
  JOIN profiles p ON p.id = s.user_id
  WHERE s.created_at > now() - interval '24 hours'
    AND ST_DWithin(
      s.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      radius_meters
    )
  ORDER BY s.created_at DESC;
END;
$$;

-- Paginated version of get_nearby_posts
DROP FUNCTION IF EXISTS public.get_nearby_posts(double precision, double precision, double precision);
CREATE OR REPLACE FUNCTION public.get_nearby_posts(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 2000,
  page integer default 1,
  page_size integer default 20
)
RETURNS TABLE(
  id uuid,
  user_id uuid,
  content text,
  media_urls text[],
  media_type text,
  context_tag text,
  reaction_counts jsonb,
  comment_count bigint,
  created_at timestamptz,
  username text,
  display_name text,
  avatar_url text,
  distance double precision
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.user_id,
    p.content,
    p.media_urls,
    p.media_type,
    p.context_tag,
    COALESCE(p.reaction_counts, '{}'::jsonb) as reaction_counts,
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::bigint as comment_count,
    p.created_at,
    pr.username,
    pr.display_name,
    pr.avatar_url,
    ST_DistanceSphere(
      p.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) as distance
  FROM posts p
  JOIN profiles pr ON pr.id = p.user_id
  WHERE ST_DWithin(
    p.location::geography,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
    radius_meters
  )
  ORDER BY p.created_at DESC
  LIMIT page_size
  OFFSET (page - 1) * page_size;
END;
$$;

-- Count of nearby posts (for pagination)
CREATE OR REPLACE FUNCTION public.get_nearby_posts_count(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 2000
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  total bigint;
BEGIN
  SELECT count(*) INTO total
  FROM posts p
  WHERE ST_DWithin(
    p.location::geography,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
    radius_meters
  );
  RETURN total;
END;
$$;

-- Function to get user's posts (for profile screen)
CREATE OR REPLACE FUNCTION public.get_user_posts(
  target_user_id uuid,
  page integer default 1,
  page_size integer default 20
)
RETURNS TABLE(
  id uuid,
  content text,
  media_urls text[],
  media_type text,
  context_tag text,
  reaction_counts jsonb,
  comment_count bigint,
  created_at timestamptz,
  username text,
  display_name text,
  avatar_url text,
  distance double precision
)
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.content,
    p.media_urls,
    p.media_type,
    p.context_tag,
    COALESCE(p.reaction_counts, '{}'::jsonb) as reaction_counts,
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::bigint as comment_count,
    p.created_at,
    pr.username,
    pr.display_name,
    pr.avatar_url,
    0::double precision as distance
  FROM posts p
  JOIN profiles pr ON pr.id = p.user_id
  WHERE p.user_id = target_user_id
  ORDER BY p.created_at DESC
  LIMIT page_size
  OFFSET (page - 1) * page_size;
END;
$$;
