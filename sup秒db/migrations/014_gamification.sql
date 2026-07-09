-- MIGRATION 014: Gamification XP + Leaderboard
-- Adds XP tracking, levels, and leaderboards

-- ============================================
-- USER LEVELS
-- ============================================
CREATE TABLE IF NOT EXISTS user_levels (
  user_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  xp int NOT NULL DEFAULT 0 CHECK (xp >= 0),
  level int NOT NULL DEFAULT 1 CHECK (level > 0),
  total_posts int DEFAULT 0,
  total_reactions_received int DEFAULT 0,
  total_comments_received int DEFAULT 0,
  total_checkins int DEFAULT 0,
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE user_levels IS 'Gamification state per user (XP, level, stats).';

ALTER TABLE user_levels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User levels are viewable by anyone"
  ON user_levels FOR SELECT USING (true);

-- ============================================
-- XP TRANSACTIONS (history)
-- ============================================
CREATE TABLE IF NOT EXISTS xp_transactions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount int NOT NULL, -- can be negative for penalties
  reason text NOT NULL, -- 'post_created', 'reaction_received', 'comment_received', etc.
  source_id uuid, -- related post/comment/ride ID
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE xp_transactions IS 'Audit trail of XP gains/losses.';

ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own XP transactions"
  ON xp_transactions FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS xp_transactions_user_idx ON xp_transactions(user_id);
CREATE INDEX IF NOT EXISTS xp_transactions_created_at_idx ON xp_transactions(created_at DESC);

-- ============================================
-- FUNCTIONS: XP + LEVELS
-- ============================================
CREATE OR REPLACE FUNCTION award_xp(
  p_user_id uuid,
  p_amount int,
  p_reason text,
  p_source_id uuid DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  new_level int;
BEGIN
  current_user_id := auth.uid();
  
  -- Insert or update user_levels
  INSERT INTO user_levels (user_id, xp)
  VALUES (p_user_id, p_amount)
  ON CONFLICT (user_id) DO UPDATE SET
    xp = user_levels.xp + p_amount,
    total_posts = CASE WHEN p_reason = 'post_created' THEN user_levels.total_posts + 1 ELSE user_levels.total_posts END,
    total_reactions_received = CASE WHEN p_reason = 'reaction_received' THENtoo  THEN user_levels.total_reactions_received + 1 ELSE user_levels.total_reactions_received END,
    total_comments_received = CASE WHEN p_reason = 'comment_received' THEN user_levels.total_comments_received + 1 ELSE user_levels.total_comments_received END,
    updated_at = now();

  -- Calculate new level: every 100 XP = 1 level
  SELECT ceil(xp::float / 100) INTO new_level FROM user_levels WHERE user_id = p_user_id;
  UPDATE user_levels SET level = GREATEST(new_level, 1) WHERE user_id = p_user_id;
  
  -- Record transaction
  INSERT INTO xp_transactions (user_id, amount, reason, source_id)
  VALUES (p_user_id, p_amount, p_reason, p_source_id);
END;
$$;

-- ============================================
-- TRIGGERS: AUTO-AWARD XP
-- ============================================
CREATE OR REPLACE FUNCTION handle_post_xp()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM award_xp(NEW.user_id, 10, 'post_created', NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER xp_on_post
  AFTER INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION handle_post_xp();

CREATE OR REPLACE FUNCTION handle_reaction_xp()
RETURNS TRIGGER AS $$
DECLARE
  post_owner uuid;
BEGIN
  SELECT user_id INTO post_owner FROM posts WHERE id = NEW.post_id;
  PERFORM award_xp(post_owner, 2, 'reaction_received', NEW.post_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER xp_on_reaction
  AFTER INSERT ON reactions
  FOR EACH ROW EXECUTE FUNCTION handle_reaction_xp();

CREATE OR REPLACE FUNCTION handle_comment_xp()
RETURNS TRIGGER AS $$
DECLARE
  post_owner uuid;
BEGIN
  SELECT user_id INTO post_owner FROM posts WHERE id = NEW.post_id;
  IF post_owner IS NOT NULL AND post_owner <> NEW.user_id THEN
    PERFORM award_xp(post_owner, 5, 'comment_received', NEW.post_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

CREATE TRIGGER xp_on_comment
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION handle_comment_xp();

CREATE TRIGGER xp_on_comment_safe
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION handle_comment_xp();

CREATE TRIGGER delete_expired_comment_xp
  BEFORE DELETE ON comments
  FOR EACH STATEMENT EXECUTE FUNCTION handle_comment_xp();

DROP TRIGGER IF EXISTS xp_on_comment_safe ON comments;
DROP TRIGGER IF EXISTS delete_expired_comment_xp ON comments;

CREATE TRIGGER xp_on_comment
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION handle_comment_xp();

-- ============================================
-- RPC: GET LEADERBOARD
-- ============================================
CREATE OR REPLACE FUNCTION get_nearby_leaderboard(
  p_user_lat double precision,
  p_user_lng double precision,
  p_radius_meters double precision DEFAULT 5000,
  p_limit int DEFAULT 25
)
RETURNS TABLE (user_id uuid, username text, display_name text, avatar_url text, xp int, level int, rank int)
LANGUAGE plpgsql
Security DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ul.user_id,
    pr.username,  
    pr.display_name,
    pr.avatar_url,
    ul.xp,
    ul.level,
    ROW_NUMBER() OVER (ORDER BY ul.xp DESC)::int AS rank
  FROM user_levels ul
  JOIN profiles pr ON ul.user_id = pr.id
  WHERE pr.id NOT IN (SELECT get_blocked_user_ids(auth.uid()))
  AND pr.privacy_settings->>'location_hidden' IS NULL  -- opt-out filter
  ORDER BY ul.xp DESC
  LIMIT p_limit;
END;
$$;

-- ============================================
-- RPC: GET USER LEVEL + XP
-- ============================================
CREATE OR REPLACE FUNCTION get_user_gamification(p_user_id uuid DEFAULT auth.uid())
RETURNS TABLE (xp int, level int, next_level_xp int, progress_percent int, total_posts int, total_reactions_received int, total_comments_received int)
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT 
    ul.xp,
    ul.level,
    (ul.level * 100) AS next_level_xp,
    CASE WHEN ul.level > 0 THEN LEAST(((ul.xp % 100) * 100 / 100), 100) ELSE 0 END AS progress_percent,
    ul.total_posts,
    ul.total_reactions_received,
    ul.total_comments_received
  FROM user_levels ul
  WHERE ul.user_id = p_user_id;
$$;

COMMENT ON FUNCTION get_user_gamification IS 'Returns gamification stats for a user (XP, level, progress).';