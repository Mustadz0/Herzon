-- ============================================================
-- MIGRATION 018: Fix PostGIS compatibility & code quality
--   - Replace deprecated ST_DistanceSphere with ST_Distance
--   - Fix ambiguous column references
--   - Fix ON CONFLICT without unique constraint
-- ============================================================

-- 1. get_nearby_posts: ST_DistanceSphere → ST_Distance
DROP FUNCTION IF EXISTS public.get_nearby_posts(double precision, double precision, double precision, integer, integer);
CREATE OR REPLACE FUNCTION public.get_nearby_posts(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 2000,
  page integer default 1,
  page_size integer default 20
)
RETURNS TABLE(id uuid, user_id uuid, content text, media_urls text[], media_type text,
  context_tag text, reaction_counts jsonb, comment_count bigint, created_at timestamptz,
  username text, display_name text, avatar_url text, distance double precision)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.user_id, p.content, p.media_urls, p.media_type, p.context_tag,
    COALESCE(p.reaction_counts, '{}'::jsonb),
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::bigint,
    p.created_at, pr.username, pr.display_name, pr.avatar_url,
    ST_Distance(p.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance
  FROM public.posts p
  JOIN public.profiles pr ON pr.id = p.user_id
  WHERE ST_DWithin(p.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
  ORDER BY p.created_at DESC
  LIMIT page_size OFFSET (page - 1) * page_size;
END;
$$;

-- 2. get_active_stories: ST_DistanceSphere → ST_Distance
DROP FUNCTION IF EXISTS public.get_active_stories(double precision, double precision, double precision);
CREATE OR REPLACE FUNCTION public.get_active_stories(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 2000
)
RETURNS TABLE(id uuid, user_id uuid, media_url text, media_type text, text_overlay text,
  created_at timestamptz, username text, display_name text, avatar_url text, distance double precision)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT s.id, s.user_id, s.media_url, s.media_type, s.text_overlay, s.created_at,
    p.username, p.display_name, p.avatar_url,
    ST_Distance(s.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance
  FROM public.stories s
  JOIN public.profiles p ON p.id = s.user_id
  WHERE s.created_at > now() - interval '24 hours'
    AND ST_DWithin(s.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
  ORDER BY s.created_at DESC;
END;
$$;

-- 3. get_nearby_marketplace_items: ST_DistanceSphere → ST_Distance
DROP FUNCTION IF EXISTS public.get_nearby_marketplace_items(double precision, double precision, double precision, text, integer, integer);
CREATE OR REPLACE FUNCTION public.get_nearby_marketplace_items(
  user_lat double precision, user_lng double precision,
  radius_meters double precision default 2000, filter_category text default null,
  page integer default 1, page_size integer default 20
)
RETURNS TABLE(id uuid, user_id uuid, title text, description text, price numeric,
  currency text, item_category text, images text[], status text, created_at timestamptz,
  username text, display_name text, avatar_url text, distance double precision)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT mi.id, mi.user_id, mi.title, mi.description, mi.price, mi.currency,
    mi.category AS item_category, mi.images, mi.status, mi.created_at,
    p.username, p.display_name, p.avatar_url,
    ST_Distance(mi.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance
  FROM public.marketplace_items mi
  JOIN public.profiles p ON p.id = mi.user_id
  WHERE mi.status = 'active'
    AND (filter_category IS NULL OR mi.category = filter_category)
    AND ST_DWithin(mi.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
  ORDER BY mi.created_at DESC
  LIMIT page_size OFFSET (page - 1) * page_size;
END;
$$;

-- 4. Fix assign_user_to_experiment: ambiguous column "variants"
DROP FUNCTION IF EXISTS public.assign_user_to_experiment(uuid);
CREATE OR REPLACE FUNCTION public.assign_user_to_experiment(p_experiment_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  exp_variants jsonb;
  selected_variant text;
  total_weight float;
  rand float;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  SELECT variant_name INTO selected_variant
  FROM public.experiment_assignments
  WHERE user_id = current_user_id AND experiment_id = p_experiment_id;
  IF selected_variant IS NOT NULL THEN RETURN selected_variant; END IF;
  SELECT e.variants INTO exp_variants FROM public.experiments e WHERE e.id = p_experiment_id;
  IF exp_variants IS NULL OR jsonb_array_length(exp_variants) = 0 THEN
    RAISE EXCEPTION 'Experiment not found or has no variants';
  END IF;
  SELECT SUM((v->>'weight')::float) INTO total_weight FROM jsonb_array_elements(exp_variants) AS v;
  SELECT random() INTO rand;
  WITH variant_rows AS (
    SELECT v->>'name' AS vname, (v->>'weight')::float / total_weight AS weight,
      SUM((v->>'weight')::float / total_weight) OVER (ORDER BY idx) AS cumulative
    FROM jsonb_array_elements(exp_variants) WITH ORDINALITY AS e(v, idx)
  )
  SELECT vname INTO selected_variant FROM variant_rows WHERE cumulative >= rand ORDER BY cumulative LIMIT 1;
  INSERT INTO public.experiment_assignments (user_id, experiment_id, variant_name)
  VALUES (current_user_id, p_experiment_id, selected_variant);
  RETURN selected_variant;
END;
$$;

-- 5. Fix get_nearby_rides: ambiguous column "status"
DROP FUNCTION IF EXISTS public.get_nearby_rides(double precision, double precision, double precision, integer);
CREATE OR REPLACE FUNCTION public.get_nearby_rides(
  p_user_lat double precision, p_user_lng double precision,
  p_radius_meters double precision DEFAULT 10000, p_limit int DEFAULT 20
)
RETURNS TABLE (id uuid, driver_id uuid, origin_name text, destination_name text,
  departure_time timestamptz, seats_available int, price_per_seat double precision,
  description text, ride_status text, distance_meters double precision,
  driver_username text, driver_display_name text, driver_avatar_url text,
  seats_booked bigint, created_at timestamptz)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT rs.id, rs.driver_id, rs.origin_name, rs.destination_name,
    rs.departure_time, rs.seats_available, rs.price_per_seat,
    rs.description, rs.status::text,
    ST_Distance(ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(COALESCE(rs.origin_lng, 0), COALESCE(rs.origin_lat, 0)), 4326)::geography)::double precision,
    pr.username, pr.display_name, pr.avatar_url,
    COALESCE((SELECT count(*) FROM public.ride_passengers rp WHERE rp.ride_id = rs.id AND rp.status IN ('pending', 'confirmed')), 0)::bigint,
    rs.created_at
  FROM public.ride_shares rs
  JOIN public.profiles pr ON rs.driver_id = pr.id
  WHERE rs.status = 'active' AND rs.departure_time > now()
    AND ST_DWithin(ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(COALESCE(rs.origin_lng, 0), COALESCE(rs.origin_lat, 0)), 4326)::geography, p_radius_meters)
    AND rs.driver_id NOT IN (SELECT get_blocked_user_ids(auth.uid()))
    AND rs.driver_id <> COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  ORDER BY rs.departure_time ASC, distance_meters
  LIMIT p_limit;
END;
$$;

-- 6. Fix get_suggested_posts: ambiguous column "user_id"
DROP FUNCTION IF EXISTS public.get_suggested_posts(double precision, double precision, double precision, integer, uuid);
CREATE OR REPLACE FUNCTION public.get_suggested_posts(
  p_user_lat double precision, p_user_lng double precision,
  p_radius_meters double precision DEFAULT 2000, p_limit int DEFAULT 20, p_user_id uuid DEFAULT auth.uid()
)
RETURNS TABLE (id uuid, user_id uuid, content text, media_urls text[], context_tag text,
  latitude double precision, longitude double precision, created_at timestamptz,
  updated_at timestamptz, reaction_counts jsonb, comment_count int, share_count int,
  username text, display_name text, avatar_url text,
  distance_meters double precision, relevance_score float)
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
     0.6 * COALESCE(CASE WHEN p.context_tag IS NOT NULL AND p.context_tag = ANY(user_interest_tags) THEN 1.0 ELSE 0.2 END, 0.0)) AS relevance_score
  FROM public.posts p
  JOIN public.profiles pr ON p.user_id = pr.id
  WHERE ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography, p_radius_meters)
    AND p.user_id NOT IN (SELECT get_blocked_user_ids(p_user_id))
  ORDER BY relevance_score DESC, p.created_at DESC
  LIMIT p_limit;
END;
$$;

-- 7. Fix checkin_place: add unique constraint for ON CONFLICT
-- First drop existing conflicting rows, then add constraint
DELETE FROM public.checkins c1 USING public.checkins c2
WHERE c1.ctid < c2.ctid AND c1.user_id = c2.user_id AND c1.place_name = c2.place_name;
ALTER TABLE public.checkins ADD CONSTRAINT checkins_user_place_unique UNIQUE (user_id, place_name);

DROP FUNCTION IF EXISTS public.checkin_place(text, double precision, double precision);
CREATE OR REPLACE FUNCTION public.checkin_place(p_place_name text, p_place_lat double precision, p_place_lng double precision)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  existing public.checkins%ROWTYPE;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  INSERT INTO public.checkins (user_id, place_name, place_lat, place_lng, checkin_count, last_checkin_at)
  VALUES (current_user_id, p_place_name, p_place_lat, p_place_lng, 1, now())
  ON CONFLICT ON CONSTRAINT checkins_user_place_unique DO UPDATE SET
    checkin_count = public.checkins.checkin_count + 1, last_checkin_at = now()
  RETURNING * INTO existing;
  RETURN jsonb_build_object('id', existing.id, 'place_name', existing.place_name,
    'checkin_count', existing.checkin_count, 'last_checkin_at', existing.last_checkin_at);
END;
$$;

-- 8. Handle leaked password protection documentation
-- NOTE: The Supabase setting "Leaked Password Protection" must be enabled
-- via the Supabase Dashboard at: Authentication → Settings → Security

COMMENT ON FUNCTION public.get_nearby_posts IS 'Nearby posts with pagination. SECURITY INVOKER.';
COMMENT ON FUNCTION public.get_active_stories IS 'Active stories within radius. SECURITY INVOKER.';
COMMENT ON FUNCTION public.get_nearby_marketplace_items IS 'Nearby marketplace items. SECURITY INVOKER.';
COMMENT ON FUNCTION public.get_nearby_rides IS 'Nearby ride shares. SECURITY INVOKER.';
COMMENT ON FUNCTION public.get_suggested_posts IS 'Suggested posts ranked by relevance. SECURITY INVOKER.';
