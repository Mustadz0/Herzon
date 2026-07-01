-- Stories, Comments & Trending

CREATE TABLE IF NOT EXISTS public.comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS comments_post_id_idx ON public.comments (post_id);
CREATE INDEX IF NOT EXISTS comments_created_at_idx ON public.comments (created_at DESC);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are viewable by everyone"
  ON public.comments FOR SELECT USING (true);

CREATE POLICY "Users can insert their own comments"
  ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
  ON public.comments FOR DELETE USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.stories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  media_url text NOT NULL,
  media_type text NOT NULL DEFAULT 'image' CHECK (media_type IN ('image', 'video')),
  text_overlay text,
  location geometry(Point, 4326),
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz DEFAULT (now() + interval '24 hours')
);

CREATE INDEX IF NOT EXISTS stories_user_id_idx ON public.stories (user_id);
CREATE INDEX IF NOT EXISTS stories_expires_at_idx ON public.stories (expires_at);
CREATE INDEX IF NOT EXISTS stories_location_idx ON public.stories USING GIST (location);

ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Stories are viewable by everyone"
  ON public.stories FOR SELECT USING (true);

CREATE POLICY "Users can insert their own stories"
  ON public.stories FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own stories"
  ON public.stories FOR DELETE USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.story_views (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id uuid NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (story_id, user_id)
);

CREATE INDEX IF NOT EXISTS story_views_story_id_idx ON public.story_views (story_id);
CREATE INDEX IF NOT EXISTS story_views_user_id_idx ON public.story_views (user_id);

ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Story views are viewable by everyone"
  ON public.story_views FOR SELECT USING (true);

CREATE POLICY "Users can insert their own story views"
  ON public.story_views FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Fix reaction type constraint to accept emojis
ALTER TABLE public.reactions DROP CONSTRAINT IF EXISTS reactions_reaction_type_check;
ALTER TABLE public.reactions ADD CONSTRAINT reactions_reaction_type_check
  CHECK (reaction_type IN ('🔥', '⚡', '👀', '⏳', 'fire', 'heart', 'laugh', 'wow'));

-- Trigger to auto-update reaction_counts on posts
CREATE OR REPLACE FUNCTION public.update_reaction_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.posts
  SET reaction_counts = (
    SELECT COALESCE(jsonb_object_agg(reaction_type, cnt), '{}'::jsonb)
    FROM (
      SELECT reaction_type, COUNT(*)::int as cnt
      FROM public.reactions
      WHERE post_id = COALESCE(NEW.post_id, OLD.post_id)
      GROUP BY reaction_type
    ) sub
  )
  WHERE id = COALESCE(NEW.post_id, OLD.post_id);
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS reaction_insert_trigger ON public.reactions;
CREATE TRIGGER reaction_insert_trigger
  AFTER INSERT ON public.reactions
  FOR EACH ROW EXECUTE FUNCTION public.update_reaction_counts();

DROP TRIGGER IF EXISTS reaction_delete_trigger ON public.reactions;
CREATE TRIGGER reaction_delete_trigger
  AFTER DELETE ON public.reactions
  FOR EACH ROW EXECUTE FUNCTION public.update_reaction_counts();

CREATE OR REPLACE FUNCTION public.get_active_stories(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision DEFAULT 2000
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  media_url text,
  media_type text,
  text_overlay text,
  created_at timestamptz,
  expires_at timestamptz,
  username text,
  display_name text,
  avatar_url text
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    s.id,
    s.user_id,
    s.media_url,
    s.media_type,
    s.text_overlay,
    s.created_at,
    s.expires_at,
    pr.username,
    pr.display_name,
    pr.avatar_url
  FROM public.stories s
  JOIN public.profiles pr ON s.user_id = pr.id
  WHERE s.expires_at > now()
  AND ST_DWithin(
    COALESCE(s.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326))::geography,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
    radius_meters
  )
  ORDER BY s.created_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.get_trending_posts(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision DEFAULT 2000,
  result_limit integer DEFAULT 20
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
  distance double precision,
  trending_score double precision
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
    ) AS distance,
    (
      COALESCE((SELECT SUM(COALESCE(value::int, 0)) FROM jsonb_each_text(p.reaction_counts)), 0) * 2.0 +
      COALESCE((SELECT COUNT(*) FROM public.comments c WHERE c.post_id = p.id), 0) * 3.0 +
      CASE
        WHEN p.created_at > now() - interval '1 hour' THEN 10.0
        WHEN p.created_at > now() - interval '3 hours' THEN 5.0
        WHEN p.created_at > now() - interval '6 hours' THEN 2.0
        ELSE 0.0
      END
    ) AS trending_score
  FROM public.posts p
  JOIN public.profiles pr ON p.user_id = pr.id
  WHERE ST_DWithin(
    p.location::geography,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
    radius_meters
  )
  ORDER BY trending_score DESC, p.created_at DESC
  LIMIT result_limit;
$$;
