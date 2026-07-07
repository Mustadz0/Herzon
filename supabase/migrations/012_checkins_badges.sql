-- MIGRATION 012: Checkins + Badges + Loyalty
-- Adds checkin tracking, badge system, and loyalty scoring

-- ============================================
-- CHECKINS
-- ============================================
CREATE TABLE IF NOT EXISTS checkins (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  place_name text NOT NULL,
  place_lat double precision,
  place_lng double precision,
  checkin_count int NOT NULL DEFAULT 1,
  last_checkin_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE checkins IS 'User check-ins at places for loyalty/rewards tracking.';

ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own checkins"
  ON checkins FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create checkins"
  ON checkins FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS checkins_user_idx ON checkins(user_id);
CREATE INDEX IF NOT EXISTS checkins_place_idx ON checkins(place_name);

-- ============================================
-- BADGES
-- ============================================
CREATE TABLE IF NOT EXISTS badges (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL UNIQUE,
  description text,
  icon_url text, -- emoji or icon asset path
  category text DEFAULT 'exploration',
  required_xp int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE badges IS 'Achievement badges that users can unlock.';

-- Seed some default badges
INSERT INTO badges (name, description, icon_url, category, required_xp) VALUES
  ('Nouveau', 'Premiere publication', '🌱', 'engagement', 0),
  ('Explorateur', 'Avoir visite 10 lieux differents', '🔭', 'exploration', 10),
  ('Ambassadeur', 'Atteindre le niveau 5', '🏅', 'engagement', 50),
  ('Legende', 'Atteindre le niveau 10', '👑', 'engagement', 100),
  ('Essentiel', 'Verifier un lieu 5 fois', '✅', 'loyalty', 5),
  ('Influencer', 'Recevoir 100 reactions sur ses posts', '🔥', 'social', 100),
  ('Guide Local', 'A 10 evaluations de lieu', '📍', 'community', 10)
ON CONFLICT (name) DO NOTHING;

ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All badges are viewable"
  ON badges FOR SELECT USING (true);

-- ============================================
-- USER BADGES
-- ============================================
CREATE TABLE IF NOT EXISTS user_badges (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id uuid NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at timestamptz DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

COMMENT ON TABLE user_badges IS 'Links users to earned badges.';

ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own badges"
  ON user_badges FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS user_badges_user_idx ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS user_badges_badge_idx ON user_badges(badge_id);

-- ============================================
-- RPC: CHECK-IN + AUTO-UPDATE COUNTER
-- ============================================
CREATE OR REPLACE FUNCTION checkin_place(
  p_place_name text,
  p_place_lat double precision,
  p_place_lng double precision
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  existing checkins%ROWTYPE;
  new_count int;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Insert or increment
  INSERT INTO checkins (user_id, place_name, place_lat, place_lng, checkin_count, last_checkin_at)
  VALUES (current_user_id, p_place_name, p_place_lat, p_place_lng, 1, now())
  ON CONFLICT (user_id, place_name) DO UPDATE SET
    checkin_count = checkins.checkin_count + 1,
    last_checkin_at = now()
  RETURNING * INTO existing;

  -- Return updated checkin
  RETURN jsonb_build_object(
    'id', existing.id,
    'place_name', existing.place_name,
    'checkin_count', existing.checkin_count,
    'last_checkin_at', existing.last_checkin_at
  );
END;
$$;

-- ============================================
-- RPC: GET USER BADGES
-- ============================================
CREATE OR REPLACE FUNCTION get_user_badges(p_user_id uuid DEFAULT auth.uid())
RETURNS TABLE (badge_id uuid, name text, description text, icon_url text, earned_at timestamptz)
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT b.id, b.name, b.description, b.icon_url, ub.earned_at
  FROM user_badges ub
  JOIN badges b ON ub.badge_id = b.id
  WHERE ub.user_id = p_user_id
  ORDER BY ub.earned_at DESC;
$$;

-- ============================================
-- TRIGGER: auto-award badges based on activity
-- ============================================
CREATE OR REPLACE FUNCTION award_badges_on_milestone()
RETURNS TRIGGER AS $$
DECLARE
  user_total_posts int;
  user_total_checkins int;
  user_total_reactions int;
BEGIN
  -- Check different milestones
  IF TG_TABLE_NAME = 'posts' THEN
    -- Explorateur: 10 unique places
    SELECT count(DISTINCT place_name) INTO user_total_checkins
    FROM checkins WHERE user_id = NEW.user_id;
    
    -- Influencer: 100 reactions received
    SELECT count(*) INTO user_total_reactions
    FROM reactions WHERE post_id IN (SELECT id FROM posts WHERE user_id = NEW.user_id);
    
    -- Insert badges if not already earned (simplified; could be expanded)
    IF user_total_checkins >= 10 THEN
      INSERT INTO user_badges (user_id, badge_id)
      SELECT NEW.user_id, id FROM badges WHERE name = 'Explorateur'
      ON CONFLICT DO NOTHING;
    END IF;
    
    IF user_total_reactions >= 100 THEN
      INSERT INTO user_badges (user_id, badge_id)
      SELECT NEW.user_id, id FROM badges WHERE name = 'Influencer'
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_award_badges
  AFTER INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION award_badges_on_milestone();