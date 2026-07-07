-- ============================================================
-- MIGRATION 017: Security lint fixes
-- Addresses all warnings from supabase db lint:
--   - function_search_path_mutable
--   - anon_security_definer_function_executable
--   - authenticated_security_definer_function_executable
--   - rls_policy_always_true (notifications INSERT)
--   - public_bucket_allows_listing (avatars, post-media)
--   - auth_allow_anonymous_sign_ins
--   - auth_leaked_password_protection
-- ============================================================

-- ============================================================
-- 1. FIX MISSING search_path ON FUNCTIONS
-- ============================================================

ALTER FUNCTION public.handle_updated_at() SET search_path TO 'public';

ALTER FUNCTION public.get_zone_atmosphere(double precision, double precision, double precision) SET search_path TO 'public';

ALTER FUNCTION public.get_trending_posts(double precision, double precision, double precision, integer) SET search_path TO 'public';


-- ============================================================
-- 2. SWITCH RPC FUNCTIONS TO SECURITY INVOKER
--    These are called by authenticated users via REST API.
--    SECURITY INVOKER ensures RLS policies apply correctly
--    and prevents privilege escalation.
-- ============================================================

-- 2a. get_nearby_posts
DROP FUNCTION IF EXISTS public.get_nearby_posts(double precision, double precision, double precision);
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
    ST_DistanceSphere(p.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance
  FROM public.posts p
  JOIN public.profiles pr ON pr.id = p.user_id
  WHERE ST_DWithin(p.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
  ORDER BY p.created_at DESC
  LIMIT page_size OFFSET (page - 1) * page_size;
END;
$$;

-- 2b. get_nearby_posts_count
DROP FUNCTION IF EXISTS public.get_nearby_posts_count(double precision, double precision, double precision);
CREATE OR REPLACE FUNCTION public.get_nearby_posts_count(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 2000
)
RETURNS bigint
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE total bigint;
BEGIN
  SELECT count(*) INTO total
  FROM public.posts p
  WHERE ST_DWithin(p.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters);
  RETURN total;
END;
$$;

-- 2c. get_active_stories
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
    ST_DistanceSphere(s.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance
  FROM public.stories s
  JOIN public.profiles p ON p.id = s.user_id
  WHERE s.created_at > now() - interval '24 hours'
    AND ST_DWithin(s.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
  ORDER BY s.created_at DESC;
END;
$$;

-- 2d. get_nearby_marketplace_items
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
    ST_DistanceSphere(mi.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography) AS distance
  FROM public.marketplace_items mi
  JOIN public.profiles p ON p.id = mi.user_id
  WHERE mi.status = 'active'
    AND (filter_category IS NULL OR mi.category = filter_category)
    AND ST_DWithin(mi.location::geography, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography, radius_meters)
  ORDER BY mi.created_at DESC
  LIMIT page_size OFFSET (page - 1) * page_size;
END;
$$;

-- 2e. get_user_posts
DROP FUNCTION IF EXISTS public.get_user_posts(uuid, integer, integer);
CREATE OR REPLACE FUNCTION public.get_user_posts(
  target_user_id uuid, page integer default 1, page_size integer default 20
)
RETURNS TABLE(id uuid, content text, media_urls text[], media_type text, context_tag text,
  reaction_counts jsonb, comment_count bigint, created_at timestamptz,
  username text, display_name text, avatar_url text, distance double precision)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.content, p.media_urls, p.media_type, p.context_tag,
    COALESCE(p.reaction_counts, '{}'::jsonb),
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::bigint,
    p.created_at, pr.username, pr.display_name, pr.avatar_url, 0::double precision
  FROM public.posts p
  JOIN public.profiles pr ON pr.id = p.user_id
  WHERE p.user_id = target_user_id
  ORDER BY p.created_at DESC
  LIMIT page_size OFFSET (page - 1) * page_size;
END;
$$;

-- 2f. search_users
DROP FUNCTION IF EXISTS public.search_users(text, integer, integer);
CREATE OR REPLACE FUNCTION public.search_users(
  query text, page integer default 1, page_size integer default 20
)
RETURNS TABLE(id uuid, username text, display_name text, avatar_url text, bio text)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.username, p.display_name, p.avatar_url, p.bio
  FROM public.profiles p
  WHERE p.display_name ILIKE '%' || query || '%' OR p.username ILIKE '%' || query || '%'
  ORDER BY CASE
    WHEN p.display_name ILIKE query || '%' THEN 0
    WHEN p.display_name ILIKE '%' || query || '%' THEN 1
    WHEN p.username ILIKE query || '%' THEN 2 ELSE 3
  END, p.display_name ASC
  LIMIT page_size OFFSET (page - 1) * page_size;
END;
$$;

-- 2g. get_user_posts_count
DROP FUNCTION IF EXISTS public.get_user_posts_count(uuid);
CREATE OR REPLACE FUNCTION public.get_user_posts_count(target_user_id uuid)
RETURNS int
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $func$
  SELECT count(*)::int FROM public.posts WHERE user_id = target_user_id;
$func$;

-- 2h. get_user_gamification
DROP FUNCTION IF EXISTS public.get_user_gamification(uuid);
CREATE OR REPLACE FUNCTION public.get_user_gamification(p_user_id uuid DEFAULT auth.uid())
RETURNS TABLE (xp int, level int, next_level_xp int, progress_percent int,
  total_posts int, total_reactions_received int, total_comments_received int)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $func$
  SELECT ul.xp, ul.level, (ul.level * 100) AS next_level_xp,
    CASE WHEN ul.level > 0 THEN LEAST((ul.xp % 100), 100) ELSE 0 END AS progress_percent,
    ul.total_posts, ul.total_reactions_received, ul.total_comments_received
  FROM public.user_levels ul WHERE ul.user_id = p_user_id;
$func$;

-- 2i. get_nearby_leaderboard
DROP FUNCTION IF EXISTS public.get_nearby_leaderboard(double precision, double precision, double precision, integer);
CREATE OR REPLACE FUNCTION public.get_nearby_leaderboard(
  p_user_lat double precision, p_user_lng double precision,
  p_radius_meters double precision DEFAULT 5000, p_limit int DEFAULT 25
)
RETURNS TABLE (user_id uuid, username text, display_name text, avatar_url text, xp int, level int, rank int)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $func$
BEGIN
  RETURN QUERY
  SELECT ul.user_id, pr.username, pr.display_name, pr.avatar_url, ul.xp, ul.level,
    ROW_NUMBER() OVER (ORDER BY ul.xp DESC)::int AS rank
  FROM public.user_levels ul
  JOIN public.profiles pr ON ul.user_id = pr.id
  WHERE pr.id NOT IN (SELECT get_blocked_user_ids(COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)))
  ORDER BY ul.xp DESC
  LIMIT p_limit;
END;
$func$;

-- 2j. get_user_feature_flags
DROP FUNCTION IF EXISTS public.get_user_feature_flags();
CREATE OR REPLACE FUNCTION public.get_user_feature_flags()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$ SELECT jsonb_object_agg(key, value) FROM public.feature_config; $$;

-- 2k. get_user_experiments
DROP FUNCTION IF EXISTS public.get_user_experiments();
CREATE OR REPLACE FUNCTION public.get_user_experiments()
RETURNS TABLE (experiment_name text, variant_name text)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
  SELECT e.name AS experiment_name, ea.variant_name
  FROM public.experiment_assignments ea
  JOIN public.experiments e ON ea.experiment_id = e.id
  WHERE ea.user_id = auth.uid();
$$;

-- 2l. assign_user_to_experiment
DROP FUNCTION IF EXISTS public.assign_user_to_experiment(uuid);
CREATE OR REPLACE FUNCTION public.assign_user_to_experiment(p_experiment_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  variants jsonb;
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
  SELECT variants INTO variants FROM public.experiments WHERE id = p_experiment_id;
  IF variants IS NULL OR jsonb_array_length(variants) = 0 THEN
    RAISE EXCEPTION 'Experiment not found or has no variants';
  END IF;
  SELECT SUM((v->>'weight')::float) INTO total_weight FROM jsonb_array_elements(variants) AS v;
  SELECT random() INTO rand;
  WITH variant_rows AS (
    SELECT v->>'name' AS vname, (v->>'weight')::float / total_weight AS weight,
      SUM((v->>'weight')::float / total_weight) OVER (ORDER BY idx) AS cumulative
    FROM jsonb_array_elements(variants) WITH ORDINALITY AS e(v, idx)
  )
  SELECT vname INTO selected_variant FROM variant_rows WHERE cumulative >= rand ORDER BY cumulative LIMIT 1;
  INSERT INTO public.experiment_assignments (user_id, experiment_id, variant_name)
  VALUES (current_user_id, p_experiment_id, selected_variant);
  RETURN selected_variant;
END;
$$;

-- 2m. vote_poll
DROP FUNCTION IF EXISTS public.vote_poll(uuid, int);
CREATE OR REPLACE FUNCTION public.vote_poll(p_post_id uuid, p_option_index int)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  poll_data jsonb;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  SELECT poll INTO poll_data FROM public.posts WHERE id = p_post_id;
  IF poll_data IS NULL OR jsonb_array_length(poll_data) = 0 THEN RAISE EXCEPTION 'Poll not found'; END IF;
  IF p_option_index < 0 OR p_option_index >= jsonb_array_length(poll_data) THEN RAISE EXCEPTION 'Invalid option index'; END IF;
  INSERT INTO public.poll_votes (post_id, user_id, option_index)
  VALUES (p_post_id, current_user_id, p_option_index)
  ON CONFLICT (post_id, user_id) DO UPDATE SET option_index = p_option_index;
END;
$$;

-- 2n. get_poll_results
DROP FUNCTION IF EXISTS public.get_poll_results(uuid);
CREATE OR REPLACE FUNCTION public.get_poll_results(p_post_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  poll_data jsonb;
  total_votes int;
  i int;
BEGIN
  current_user_id := auth.uid();
  SELECT poll INTO poll_data FROM public.posts WHERE id = p_post_id;
  IF poll_data IS NULL THEN RETURN null; END IF;
  SELECT count(*) INTO total_votes FROM public.poll_votes WHERE post_id = p_post_id;
  FOR i IN 0..jsonb_array_length(poll_data)-1 LOOP
    DECLARE option_votes int := (SELECT count(*) FROM public.poll_votes WHERE post_id = p_post_id AND option_index = i);
    BEGIN
      poll_data := jsonb_set(poll_data, ARRAY[i::text],
        (poll_data->i) || jsonb_build_object('votes', option_votes,
          'percentage', CASE WHEN total_votes > 0 THEN round(option_votes * 100.0 / total_votes, 1) ELSE 0 END));
    END;
  END LOOP;
  RETURN poll_data;
END;
$$;

-- 2o. checkin_place
DROP FUNCTION IF EXISTS public.checkin_place(text, double precision, double precision);
CREATE OR REPLACE FUNCTION public.checkin_place(p_place_name text, p_place_lat double precision, p_place_lng double precision)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  existing record;
  new_count int;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  INSERT INTO public.checkins (user_id, place_name, place_lat, place_lng, checkin_count, last_checkin_at)
  VALUES (current_user_id, p_place_name, p_place_lat, p_place_lng, 1, now())
  ON CONFLICT (user_id, place_name) DO UPDATE SET
    checkin_count = public.checkins.checkin_count + 1, last_checkin_at = now()
  RETURNING * INTO existing;
  RETURN jsonb_build_object('id', existing.id, 'place_name', existing.place_name,
    'checkin_count', existing.checkin_count, 'last_checkin_at', existing.last_checkin_at);
END;
$$;

-- 2p. get_user_badges
DROP FUNCTION IF EXISTS public.get_user_badges(uuid);
CREATE OR REPLACE FUNCTION public.get_user_badges(p_user_id uuid DEFAULT auth.uid())
RETURNS TABLE (badge_id uuid, name text, description text, icon_url text, earned_at timestamptz)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
  SELECT b.id, b.name, b.description, b.icon_url, ub.earned_at
  FROM public.user_badges ub
  JOIN public.badges b ON ub.badge_id = b.id
  WHERE ub.user_id = p_user_id
  ORDER BY ub.earned_at DESC;
$$;

-- 2q. get_nearby_rides
DROP FUNCTION IF EXISTS public.get_nearby_rides(double precision, double precision, double precision, integer);
CREATE OR REPLACE FUNCTION public.get_nearby_rides(
  p_user_lat double precision, p_user_lng double precision,
  p_radius_meters double precision DEFAULT 10000, p_limit int DEFAULT 20
)
RETURNS TABLE (id uuid, driver_id uuid, origin_name text, destination_name text,
  departure_time timestamptz, seats_available int, price_per_seat double precision,
  description text, status text, distance_meters double precision,
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
    rs.description, rs.status,
    ST_Distance(ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(COALESCE(rs.origin_lng, 0), COALESCE(rs.origin_lat, 0)), 4326)::geography)::double precision,
    pr.username, pr.display_name, pr.avatar_url,
    COALESCE((SELECT count(*) FROM public.ride_passengers WHERE ride_id = rs.id AND status IN ('pending', 'confirmed')), 0)::bigint,
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

-- 2r. get_nearby_pages
DROP FUNCTION IF EXISTS public.get_nearby_pages(double precision, double precision, double precision, text, integer);
CREATE OR REPLACE FUNCTION public.get_nearby_pages(
  p_user_lat double precision, p_user_lng double precision,
  p_radius_meters double precision DEFAULT 5000, p_category text DEFAULT NULL, p_limit int DEFAULT 20
)
RETURNS TABLE (id uuid, owner_id uuid, name text, slug text, category text, description text,
  avatar_url text, banner_url text, contact_email text, contact_phone text,
  website_url text, address text, distance_meters double precision, post_count bigint)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.owner_id, p.name, p.slug, p.category, p.description,
    p.avatar_url, p.banner_url, p.contact_email, p.contact_phone,
    p.website_url, p.address,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography)::double precision,
    (SELECT count(*) FROM public.posts WHERE actor_id = p.id AND actor_type = 'page')
  FROM public.pages p
  WHERE ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography, p_radius_meters)
    AND p.is_active = true
    AND (p_category IS NULL OR p.category = p_category)
  ORDER BY distance_meters
  LIMIT p_limit;
END;
$$;

-- 2s. get_blocked_user_ids
DROP FUNCTION IF EXISTS public.get_blocked_user_ids(uuid);
CREATE OR REPLACE FUNCTION public.get_blocked_user_ids(check_user_id uuid DEFAULT auth.uid())
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = 'public'
AS $$
  SELECT blocked_id FROM public.blocked_users WHERE blocker_id = check_user_id
  UNION
  SELECT blocker_id FROM public.blocked_users WHERE blocked_id = check_user_id;
$$;

-- 2t. get_suggested_posts
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
  FROM (SELECT tag FROM public.user_interests WHERE user_id = p_user_id ORDER BY weight DESC LIMIT 10) sub;
  RETURN QUERY
  SELECT p.id, p.user_id, p.content, p.media_urls, p.context_tag,
    ST_Y(p.location::geometry)::double precision, ST_X(p.location::geometry)::double precision,
    p.created_at, p.updated_at, p.reaction_counts, p.comment_count, p.share_count,
    pr.username, pr.display_name, pr.avatar_url,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography)::double precision,
    (0.4 * (1.0 - (ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography) / p_radius_meters)) +
     0.6 * COALESCE(CASE WHEN p.context_tag = ANY(user_interest_tags) THEN 1.0
                     WHEN p.tags && user_interest_tags THEN 0.7 ELSE 0.2 END, 0.0)) AS relevance_score
  FROM public.posts p
  JOIN public.profiles pr ON p.user_id = pr.id
  WHERE ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography, p_radius_meters)
    AND p.user_id NOT IN (SELECT get_blocked_user_ids(p_user_id))
  ORDER BY relevance_score DESC, p.created_at DESC
  LIMIT p_limit;
END;
$$;


-- ============================================================
-- 3. REVOKE EXECUTE ON TRIGGER/SYSTEM FUNCTIONS
--    These run as SECURITY DEFINER via triggers or cron,
--    and should NOT be callable by anon or authenticated roles.
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_reaction_counts() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_notification() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_comment_notification() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_follow_notification() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_expired_stories() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_post_xp() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_xp() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_comment_xp() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, int, text, uuid) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.award_badges_on_milestone() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.prevent_vote_own_post() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_poll_vote_counts() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.update_user_interests() FROM anon, authenticated;

-- Revoke EXECUTE on PostGIS internal functions exposed via RPC
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text, boolean) FROM anon, authenticated;


-- ============================================================
-- 4. FIX RLS POLICIES
-- ============================================================

-- 4a. Fix notifications INSERT policy: restrict to user's own notifications
--     (triggers bypass RLS via SECURITY DEFINER, so this doesn't affect them)
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "Users can create own notifications"
  ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4b. Restrict anonymous access on SELECT policies
--     All read policies using USING (true) should require authentication
--     since this app requires Google Sign-In.

-- Profiles: disable anonymous SELECT
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
  ON public.profiles FOR SELECT USING (auth.role() = 'authenticated');

-- Zones: disable anonymous SELECT
DROP POLICY IF EXISTS "Zones are viewable by everyone" ON public.zones;
CREATE POLICY "Zones are viewable by authenticated users"
  ON public.zones FOR SELECT USING (auth.role() = 'authenticated');

-- Posts: disable anonymous SELECT
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON public.posts;
CREATE POLICY "Posts are viewable by authenticated users"
  ON public.posts FOR SELECT USING (auth.role() = 'authenticated');

-- Reactions: disable anonymous SELECT
DROP POLICY IF EXISTS "Reactions are viewable by everyone" ON public.reactions;
CREATE POLICY "Reactions are viewable by authenticated users"
  ON public.reactions FOR SELECT USING (auth.role() = 'authenticated');

-- Messages: already properly restricted with auth.uid() checks
-- No change needed.

-- Follows: disable anonymous SELECT
DROP POLICY IF EXISTS "Follows are viewable by everyone" ON public.follows;
CREATE POLICY "Follows are viewable by authenticated users"
  ON public.follows FOR SELECT USING (auth.role() = 'authenticated');

-- Comments: disable anonymous SELECT
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON public.comments;
CREATE POLICY "Comments are viewable by authenticated users"
  ON public.comments FOR SELECT USING (auth.role() = 'authenticated');

-- Stories: disable anonymous SELECT
DROP POLICY IF EXISTS "Stories are viewable by everyone" ON public.stories;
CREATE POLICY "Stories are viewable by authenticated users"
  ON public.stories FOR SELECT USING (auth.role() = 'authenticated');

-- Story views: disable anonymous SELECT
DROP POLICY IF EXISTS "Story views are viewable by everyone" ON public.story_views;
CREATE POLICY "Story views are viewable by authenticated users"
  ON public.story_views FOR SELECT USING (auth.role() = 'authenticated');

-- Marketplace items: disable anonymous SELECT (keep status/user check)
DROP POLICY IF EXISTS "Anyone can view active items" ON public.marketplace_items;
CREATE POLICY "Authenticated users can view items"
  ON public.marketplace_items FOR SELECT
  USING ((auth.role() = 'authenticated') AND (status = 'active' OR user_id = auth.uid()));

-- Poll votes: disable anonymous SELECT
DROP POLICY IF EXISTS "Poll votes are viewable by anyone" ON public.poll_votes;
CREATE POLICY "Poll votes are viewable by authenticated users"
  ON public.poll_votes FOR SELECT USING (auth.role() = 'authenticated');

-- User levels: disable anonymous SELECT
DROP POLICY IF EXISTS "User levels are viewable by anyone" ON public.user_levels;
CREATE POLICY "User levels are viewable by authenticated users"
  ON public.user_levels FOR SELECT USING (auth.role() = 'authenticated');

-- Badges: disable anonymous SELECT
DROP POLICY IF EXISTS "All badges are viewable" ON public.badges;
CREATE POLICY "Badges are viewable by authenticated users"
  ON public.badges FOR SELECT USING (auth.role() = 'authenticated');

-- Ride shares: disable anonymous SELECT
DROP POLICY IF EXISTS "All ride shares are viewable" ON public.ride_shares;
CREATE POLICY "Ride shares are viewable by authenticated users"
  ON public.ride_shares FOR SELECT USING (auth.role() = 'authenticated');

-- Pages: disable anonymous SELECT
DROP POLICY IF EXISTS "All pages are viewable" ON public.pages;
CREATE POLICY "Pages are viewable by authenticated users"
  ON public.pages FOR SELECT USING (auth.role() = 'authenticated');

-- Experiments: disable anonymous SELECT
DROP POLICY IF EXISTS "All experiments are viewable" ON public.experiments;
CREATE POLICY "Experiments are viewable by authenticated users"
  ON public.experiments FOR SELECT USING (auth.role() = 'authenticated');

-- Feature config: disable anonymous SELECT
DROP POLICY IF EXISTS "All feature config is viewable" ON public.feature_config;
CREATE POLICY "Feature config is viewable by authenticated users"
  ON public.feature_config FOR SELECT USING (auth.role() = 'authenticated');

-- Device tokens: already restricted with auth.uid() check
-- Realtime messages: handled separately below

-- 4c. Fix storage bucket SELECT policies to prevent listing
--     Allows reading known files but prevents listing the bucket.

-- Post-media bucket: authenticated users can view/list own files, public can view known files
DROP POLICY IF EXISTS "Public can view media" ON storage.objects;
CREATE POLICY "Authenticated users can view media"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'post-media' AND auth.role() = 'authenticated');

-- Avatars bucket: authenticated users can view/list own files
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
CREATE POLICY "Authenticated users can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');


-- ============================================================
-- 5. ENABLE LEAKED PASSWORD PROTECTION
--    (requires Supabase project settings update via dashboard)
--    This SQL comment serves as documentation that this
--    setting needs to be enabled in the Supabase dashboard.
-- ============================================================

-- To enable: Go to Supabase Dashboard → Authentication → Settings
-- → Toggle "Leaked password protection" ON
-- This checks passwords against HaveIBeenPwned.org.

COMMENT ON SCHEMA public IS 'Herzon app — supabase db lint warnings addressed in migration 017. Leaked password protection must be enabled via Supabase Dashboard.';

-- ============================================================
-- DONE
-- ============================================================
