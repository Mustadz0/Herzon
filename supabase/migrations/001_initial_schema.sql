-- Proximite - Initial Database Schema
-- Uses PostgreSQL with PostGIS extension for geospatial queries

-- Enable PostGIS extension for geospatial support
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE,
  display_name text,
  avatar_url text,
  bio text,
  is_anonymous boolean DEFAULT false,
  is_premium boolean DEFAULT false,
  premium_expires_at timestamptz,
  is_admin boolean DEFAULT false,
  privacy_settings jsonb DEFAULT '{"show_activity": true, "allow_messages": true}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- ZONES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  center_location geometry(Point, 4326) NOT NULL,
  atmosphere_score integer DEFAULT 0 CHECK (atmosphere_score >= 0 AND atmosphere_score <= 100),
  atmosphere_label text DEFAULT 'Calme' CHECK (atmosphere_label IN ('Calme', 'Actif', 'Tres anime')),
  active_users_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS zones_location_idx ON public.zones USING GIST (center_location);

ALTER TABLE public.zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Zones are viewable by everyone" ON public.zones FOR SELECT USING (true);

-- ============================================
-- POSTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  media_urls text[] DEFAULT '{}',
  media_type text DEFAULT 'text' CHECK (media_type IN ('text', 'image', 'video', 'vibe')),
  location geometry(Point, 4326) NOT NULL,
  context_tag text,
  reaction_counts jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS posts_location_idx ON public.posts USING GIST (location);
CREATE INDEX IF NOT EXISTS posts_created_at_idx ON public.posts (created_at DESC);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Posts are viewable by everyone" ON public.posts FOR SELECT USING (true);

CREATE POLICY "Users can insert their own posts"
  ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts"
  ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- REACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_id uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  reaction_type text NOT NULL CHECK (reaction_type IN ('fire', 'heart', 'laugh', 'wow')),
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, post_id, reaction_type)
);

CREATE INDEX IF NOT EXISTS reactions_post_id_idx ON public.reactions (post_id);

ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reactions are viewable by everyone" ON public.reactions FOR SELECT USING (true);

CREATE POLICY "Users can insert their own reactions"
  ON public.reactions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reactions"
  ON public.reactions FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- MESSAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS messages_conversation_idx ON public.messages (sender_id, receiver_id, created_at DESC);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages they sent or received"
  ON public.messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages"
  ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- ============================================
-- FOLLOWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.follows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (follower_id, following_id)
);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Follows are viewable by everyone" ON public.follows FOR SELECT USING (true);

CREATE POLICY "Users can follow others"
  ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
  ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- ============================================
-- REPORTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_id uuid REFERENCES public.posts(id) ON DELETE SET NULL,
  reason text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed', 'actioned')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can report content"
  ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- ============================================
-- TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at_trigger
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Auto-create profile row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'preferred_username', 'user_' || substr(NEW.id::text, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- FUNCTIONS
-- ============================================
CREATE OR REPLACE FUNCTION public.get_nearby_posts(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision DEFAULT 2000
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  content text,
  media_urls text[],
  media_type text,
  context_tag text,
  reaction_counts jsonb,
  created_at timestamptz,
  username text,
  display_name text,
  avatar_url text,
  distance double precision
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    p.id,
    p.user_id,
    p.content,
    p.media_urls,
    p.media_type,
    p.context_tag,
    p.reaction_counts,
    p.created_at,
    pr.username,
    pr.display_name,
    pr.avatar_url,
    ST_Distance(
      p.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) AS distance
  FROM public.posts p
  JOIN public.profiles pr ON p.user_id = pr.id
  WHERE ST_DWithin(
    p.location::geography,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
    radius_meters
  )
  ORDER BY p.created_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.get_zone_atmosphere(
  zone_lat double precision,
  zone_lng double precision,
  zone_radius double precision DEFAULT 2000
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  user_count integer;
  recent_posts integer;
  atmo_score integer;
  atmo_label text;
BEGIN
  SELECT COUNT(DISTINCT user_id)
  INTO user_count
  FROM public.posts
  WHERE ST_DWithin(
    location::geography,
    ST_SetSRID(ST_MakePoint(zone_lng, zone_lat), 4326)::geography,
    zone_radius
  )
  AND created_at > now() - interval '30 minutes';

  SELECT COUNT(*)
  INTO recent_posts
  FROM public.posts
  WHERE ST_DWithin(
    location::geography,
    ST_SetSRID(ST_MakePoint(zone_lng, zone_lat), 4326)::geography,
    zone_radius
  )
  AND created_at > now() - interval '1 hour';

  atmo_score := LEAST(100, (user_count * 10) + (recent_posts * 5));

  IF atmo_score < 30 THEN
    atmo_label := 'Calme';
  ELSIF atmo_score < 70 THEN
    atmo_label := 'Actif';
  ELSE
    atmo_label := 'Tres anime';
  END IF;

  RETURN jsonb_build_object(
    'score', atmo_score,
    'label', atmo_label,
    'active_users', user_count,
    'recent_posts', recent_posts
  );
END;
$$;
