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

DROP POLICY IF EXISTS "Comments are viewable by everyone" ON public.comments;
DROP POLICY IF EXISTS "Users can insert their own comments" ON public.comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;

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

DROP POLICY IF EXISTS "Stories are viewable by everyone" ON public.stories;
DROP POLICY IF EXISTS "Users can insert their own stories" ON public.stories;
DROP POLICY IF EXISTS "Users can delete their own stories" ON public.stories;

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

DROP POLICY IF EXISTS "Story views are viewable by everyone" ON public.story_views;
DROP POLICY IF EXISTS "Users can insert their own story views" ON public.story_views;

CREATE POLICY "Story views are viewable by everyone"
  ON public.story_views FOR SELECT USING (true);

CREATE POLICY "Users can insert their own story views"
  ON public.story_views FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Fix reaction type constraint to accept emojis
ALTER TABLE public.reactions DROP CONSTRAINT IF EXISTS reactions_reaction_type_check;
ALTER TABLE public.reactions ADD CONSTRAINT reactions_reaction_type_check
  CHECK (reaction_type IN ('🔥', '⚡', '👀', '⏳', 'fire', 'heart', 'laugh', 'wow'));

-- Trigger to auto-update reaction_counts on posts
-- NOTE: update_reaction_counts is maintained in migration 005+,
-- skipping here since remote already has 005 applied.
