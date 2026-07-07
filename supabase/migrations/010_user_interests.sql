-- MIGRATION 010: User Interests + Content Scoring
-- Adds user interests, interaction tracking, and smart suggestions

-- ============================================
-- USER INTERESTS (tag-based)
-- ============================================
CREATE TABLE IF NOT EXISTS user_interests (
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tag text NOT NULL,
  weight float DEFAULT 1.0 CHECK (weight >= 0),
  last_interaction timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, tag)
);

COMMENT ON TABLE user_interests IS 'Weighted interests per user, updated by interactions.';

-- Enable RLS
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own interests"
  ON user_interests FOR SELECT USING (auth.uid() = user_id);

-- App-level policy (service role / background job only; triggers run as definer)

-- Index for fast retrieval
CREATE INDEX IF NOT EXISTS user_interests_tag_idx ON user_interests(tag);
CREATE INDEX IF NOT EXISTS user_interests_weight_idx ON user_interests(weight DESC);

-- ============================================
-- USER INTERACTIONS (history for scoring)
-- ============================================
CREATE TABLE IF NOT EXISTS user_interactions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  item_id uuid NOT NULL, -- post_id, story_id, etc.
  item_type text NOT NULL CHECK (item_type IN ('post', 'story', 'marketplace_item', 'event')),
  action_type text NOT NULL CHECK (action_type IN ('view', 'like', 'comment', 'share', 'click')),
  duration_seconds int, -- how long they viewed
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE user_interactions IS 'Track user interactions with content for recommendation scoring.';

-- Enable RLS
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own interactions"
  ON user_interactions FOR SELECT USING (auth.uid() = user_id);

-- Index for fast aggregation
CREATE INDEX IF NOT EXISTS user_interactions_user_idx ON user_interactions(user_id);
CREATE INDEX IF NOT EXISTS user_interactions_item_idx ON user_interactions(item_id, item_type);
CREATE INDEX IF NOT EXISTS user_interactions_created_at_idx ON user_interactions(created_at DESC);

-- ============================================
-- TRIGGER: auto-update user_interests on interactions
-- ============================================
CREATE OR REPLACE FUNCTION update_user_interests()
RETURNS TRIGGER AS $$
DECLARE
  post_tags text[];
  tag_weight float;
BEGIN
  -- Only handle post interactions for now
  IF NEW.item_type = 'post' AND NEW.action_type IN ('like', 'comment', 'share') THEN
    -- Get tags from the post
    SELECT tags INTO post_tags FROM posts WHERE id = NEW.item_id;
    
    IF post_tags IS NOT NULL THEN
      FOR i IN 1..array_length(post_tags, 1) LOOP
        tag_weight := CASE NEW.action_type
          WHEN 'like' THEN 1.0
          WHEN 'comment' THEN 2.0
          WHEN 'share' THEN 3.0
          ELSE 0.5
        END;
        
        INSERT INTO user_interests (user_id, tag, weight, last_interaction)
        VALUES (NEW.user_id, post_tags[i], tag_weight, now())
        ON CONFLICT (user_id, tag) DO UPDATE SET
          weight = user_interests.weight + tag_weight,
          last_interaction = now();
      END LOOP;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_interests_on_interaction
  AFTER INSERT ON user_interactions
  FOR EACH ROW EXECUTE FUNCTION update_user_interests();

-- ============================================
-- RPC: GET SUGGESTED POSTS (interest-based feed)
-- ============================================
CREATE OR REPLACE FUNCTION get_suggested_posts(
  p_user_lat double precision,
  p_user_lng double precision,
  p_radius_meters double precision DEFAULT 2000,
  p_limit int DEFAULT 20,
  p_user_id uuid DEFAULT auth.uid()
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  content text,
  media_urls text[],
  context_tag text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz,
  updated_at timestamptz,
  reaction_counts jsonb,
  comment_count int,
  share_count int,
  username text,
  display_name text,
  avatar_url text,
  distance_meters double precision,
  relevance_score float
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  user_interest_tags text[];
BEGIN
  -- Get user's top interests (tags with highest weight)
  SELECT array_agg(tag) INTO user_interest_tags
  FROM (
    SELECT tag FROM user_interests WHERE user_id = p_user_id ORDER BY weight DESC LIMIT 10
  ) sub;

  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.content,
    p.media_urls,
    p.context_tag,
    ST_Y(p.location::geometry)::double precision,
    ST_X(p.location::geometry)::double precision,
    p.created_at,
    now()::timestamptz as updated_at,
    p.reaction_counts,
    COALESCE((SELECT count(*) FROM public.comments c WHERE c.post_id = p.id), 0)::int as comment_count,
    0::int as share_count,
    pr.username,
    pr.display_name,
    pr.avatar_url,
    ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography)::double precision AS distance_meters,
    (0.4 * (1.0 - (ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography) / p_radius_meters)) +
    (0.6 * COALESCE(
      CASE 
        WHEN p.context_tag IS NOT NULL AND p.context_tag = ANY(user_interest_tags) THEN 1.0
        ELSE 0.2 
      END, 0.0
    ))) AS relevance_score
  FROM public.posts p
  JOIN public.profiles pr ON p.user_id = pr.id
  WHERE ST_DWithin(
    p.location,
    ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
    p_radius_meters
  )
  AND p.user_id NOT IN (SELECT get_blocked_user_ids(p_user_id))
  ORDER BY relevance_score DESC, p.created_at DESC
  LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION get_suggested_posts IS 'Returns posts ranked by relevance (location + user interests). Requires PostGIS.';