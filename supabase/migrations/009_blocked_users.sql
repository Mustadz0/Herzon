-- MIGRATION 009: Blocked Users + Close Friends
-- Adds user blocking and close friends system

-- ============================================
-- BLOCKED USERS
-- ============================================
CREATE TABLE IF NOT EXISTS blocked_users (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  blocker_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(blocker_id, blocked_id)
);

COMMENT ON TABLE blocked_users IS 'Users blocking other users.';

-- Enable RLS
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own blocks"
  ON blocked_users FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Users can block"
  ON blocked_users FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock"
  ON blocked_users FOR DELETE USING (auth.uid() = blocker_id);

-- Index for fast filtering
CREATE INDEX IF NOT EXISTS blocked_users_blocker_idx ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS blocked_users_blocked_idx ON blocked_users(blocked_id);

-- ============================================
-- CLOSE FRIENDS
-- ============================================
CREATE TABLE IF NOT EXISTS close_friends (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  friend_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, friend_id)
);

COMMENT ON TABLE close_friends IS 'Users close friends list.';

-- Enable RLS
ALTER TABLE close_friends ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own close friends"
  ON close_friends FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can add close friends"
  ON close_friends FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove close friends"
  ON close_friends FOR DELETE USING (auth.uid() = user_id);

-- Index for fast filtering
CREATE INDEX IF NOT EXISTS close_friends_user_idx ON close_friends(user_id);
CREATE INDEX IF NOT EXISTS close_friends_friend_idx ON close_friends(friend_id);

-- ============================================
-- UPDATE EXISTING RPCs TO FILTER BLOCKED USERS
-- ============================================

-- Create helper function to get blocked user IDs for a given user
CREATE OR REPLACE FUNCTION get_blocked_user_ids(check_user_id uuid DEFAULT auth.uid())
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT blocked_id FROM blocked_users WHERE blocker_id = check_user_id
  UNION
  SELECT blocker_id FROM blocked_users WHERE blocked_id = check_user_id;
$$;

COMMENT ON FUNCTION get_blocked_user_ids(uuid) IS 'Returns all user IDs blocked by or blocking the given user.';