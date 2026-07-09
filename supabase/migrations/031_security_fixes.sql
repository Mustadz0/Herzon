-- MIGRATION 031: Security fixes — RLS, admin checks, race conditions

-- ============================================
-- #1 CRITICAL: Fix crash_reports INSERT policy
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can insert crash reports" ON crash_reports;
CREATE POLICY "Users can insert own crash reports"
  ON crash_reports FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- #2 CRITICAL: Admin-only RPC functions
-- ============================================
CREATE OR REPLACE FUNCTION public.get_user_growth()
RETURNS TABLE (
  month DATE,
  new_users BIGINT,
  total_users BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Admin-only check
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  RETURN QUERY
  WITH monthly AS (
    SELECT
      date_trunc('month', created_at)::date AS m,
      COUNT(*)::bigint AS new_count
    FROM profiles
    GROUP BY 1
  ),
  cumulative AS (
    SELECT
      m,
      new_count,
      SUM(new_count) OVER (ORDER BY m) AS running_total
    FROM monthly
  )
  SELECT m AS month, new_count AS new_users, running_total AS total_users
  FROM cumulative
  ORDER BY m DESC
  LIMIT 12;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_engagement_metrics()
RETURNS TABLE (
  avg_likes NUMERIC,
  avg_comments NUMERIC,
  avg_shares NUMERIC,
  total_reactions BIGINT,
  total_comments BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  post_count BIGINT;
BEGIN
  -- Admin-only check
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  SELECT COUNT(*) INTO post_count FROM posts;

  RETURN QUERY
  SELECT
    CASE WHEN post_count > 0 THEN
      (SELECT COALESCE(SUM(
        (COALESCE(reaction_counts->>'like','0'))::int
      ), 0)::numeric / post_count FROM posts)
    ELSE 0::numeric END AS avg_likes,
    CASE WHEN post_count > 0 THEN
      (SELECT COUNT(*)::numeric / post_count FROM comments)
    ELSE 0::numeric END AS avg_comments,
    0::numeric AS avg_shares,
    (SELECT COALESCE(SUM(
      (COALESCE(reaction_counts->>'like','0'))::int
    ), 0)::bigint FROM posts) AS total_reactions,
    (SELECT COUNT(*)::bigint FROM comments) AS total_comments;
END;
$$;

-- ============================================
-- #3 HIGH: Add missing RLS policies for user_interests
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_interests' AND table_schema = 'public') THEN
    -- Insert policy
    DROP POLICY IF EXISTS "Users can insert own interests" ON user_interests;
    CREATE POLICY "Users can insert own interests"
      ON user_interests FOR INSERT WITH CHECK (auth.uid() = user_id);

    -- Update policy
    DROP POLICY IF EXISTS "Users can update own interests" ON user_interests;
    CREATE POLICY "Users can update own interests"
      ON user_interests FOR UPDATE USING (auth.uid() = user_id);

    -- Delete policy
    DROP POLICY IF EXISTS "Users can delete own interests" ON user_interests;
    CREATE POLICY "Users can delete own interests"
      ON user_interests FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================
-- #4 HIGH: Add missing RLS policies for user_interactions
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_interactions' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can insert own interactions" ON user_interactions;
    CREATE POLICY "Users can insert own interactions"
      ON user_interactions FOR INSERT WITH CHECK (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can read own interactions" ON user_interactions;
    CREATE POLICY "Users can read own interactions"
      ON user_interactions FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================
-- #5 HIGH: Fix book_ride() race condition
-- ============================================
CREATE OR REPLACE FUNCTION book_ride(
  p_ride_id uuid,
  p_seats int DEFAULT 1
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_seats_available int;
  v_driver_id uuid;
BEGIN
  -- Lock the row to prevent race condition
  SELECT seats_available, driver_id INTO v_seats_available, v_driver_id
  FROM ride_shares
  WHERE id = p_ride_id AND status = 'active'
  FOR UPDATE;

  -- Check if ride exists and has enough seats
  IF v_seats_available IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Ride not found or inactive');
  END IF;

  IF v_seats_available < p_seats THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not enough seats available');
  END IF;

  -- Check if already booked
  IF EXISTS (SELECT 1 FROM ride_passengers WHERE ride_id = p_ride_id AND passenger_id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Already booked');
  END IF;

  -- Atomically decrement seats and insert booking
  UPDATE ride_shares SET seats_available = seats_available - p_seats WHERE id = p_ride_id;

  INSERT INTO ride_passengers (ride_id, passenger_id, seats_booked, status)
  VALUES (p_ride_id, auth.uid(), p_seats, 'pending');

  RETURN jsonb_build_object('success', true, 'status', 'pending');
END;
$$;

-- ============================================
-- #6 MEDIUM: Add CHECK constraints for prices
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'marketplace_items' AND column_name = 'price') THEN
    ALTER TABLE marketplace_items DROP CONSTRAINT IF EXISTS marketplace_items_price_check;
    ALTER TABLE marketplace_items ADD CONSTRAINT marketplace_items_price_check CHECK (price >= 0);
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ride_shares' AND column_name = 'price_per_seat') THEN
    ALTER TABLE ride_shares DROP CONSTRAINT IF EXISTS ride_shares_price_check;
    ALTER TABLE ride_shares ADD CONSTRAINT ride_shares_price_check CHECK (price_per_seat >= 0);
  END IF;
END $$;

-- ============================================
-- #7 MEDIUM: Add message_type CHECK constraint
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'messages' AND table_schema = 'public') THEN
    ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_message_type_check;
    ALTER TABLE messages ADD CONSTRAINT messages_message_type_check
      CHECK (message_type IN ('text', 'image', 'video', 'sticker', 'location', 'poll'));
  END IF;
END $$;
