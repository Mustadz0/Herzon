-- MIGRATION 008: Polls
-- Adds poll tables and voting system

-- Poll options stored as JSONB array within posts
ALTER TABLE posts ADD COLUMN IF NOT EXISTS poll jsonb;
COMMENT ON COLUMN posts.poll IS 'JSON array of {option: string, votes: int}';

-- Table for individual votes (prevents double voting, enables analytics)
CREATE TABLE IF NOT EXISTS poll_votes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  option_index int NOT NULL CHECK (option_index >= 0),
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);

COMMENT ON TABLE poll_votes IS 'Individual votes on polls; one per user per poll.';

-- Enable RLS
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Poll votes are viewable by anyone"
  ON poll_votes FOR SELECT USING (true);

CREATE POLICY "Authenticated users can vote"
  ON poll_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own vote"
  ON poll_votes FOR DELETE USING (auth.uid() = user_id);

-- Trigger: prevent voting on own poll (optional - can be relaxed later)
CREATE OR REPLACE FUNCTION prevent_vote_own_post()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM posts WHERE id = NEW.post_id AND user_id = NEW.user_id) THEN
    RAISE EXCEPTION 'Cannot vote on your own poll';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_no_own_vote
  BEFORE INSERT ON poll_votes
  FOR EACH ROW EXECUTE FUNCTION prevent_vote_own_post();

-- Trigger: auto-update vote counts in posts.poll JSONB
CREATE OR REPLACE FUNCTION update_poll_vote_counts()
RETURNS TRIGGER AS $$
DECLARE
  new_poll jsonb;
  option_text text;
  opt_idx int;
BEGIN
  -- Get the poll options from the post
  SELECT poll INTO new_poll FROM posts WHERE id = COALESCE(NEW.post_id, OLD.post_id);
  
  IF new_poll IS NULL OR jsonb_array_length(new_poll) = 0 THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  opt_idx := (COALESCE(NEW, OLD)).option_index;
  option_text := new_poll->opt_idx->>'option';
  
  -- Recalculate vote counts for all options
  new_poll := (
    SELECT jsonb_agg(jsonb_set(opt, '{votes}', 
      COALESCE(
        (SELECT to_jsonb(count(*))::int FROM poll_votes WHERE post_id = COALESCE(NEW.post_id, OLD.post_id) AND option_index = (opt.row_number - 1)), 
        0
      )
    ))
    FROM jsonb_array_elements(new_poll) WITH ORDINALITY AS opt(value, row_number)
  );
  
  UPDATE posts SET poll = new_poll WHERE id = COALESCE(NEW.post_id, OLD.post_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER poll_votes_update_counts
  AFTER INSERT OR UPDATE OR DELETE ON poll_votes
  FOR EACH ROW EXECUTE FUNCTION update_poll_vote_counts();

-- RPC: cast vote on poll
CREATE OR REPLACE FUNCTION vote_poll(
  p_post_id uuid,
  p_option_index int
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  poll_data jsonb;
BEGIN
  current_user_id := auth.uid();
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Verify poll exists and option is valid
  SELECT poll INTO poll_data FROM posts WHERE id = p_post_id;
  IF poll_data IS NULL OR jsonb_array_length(poll_data) = 0 THEN
    RAISE EXCEPTION 'Poll not found';
  END IF;
  IF p_option_index < 0 OR p_option_index >= jsonb_array_length(poll_data) THEN
    RAISE EXCEPTION 'Invalid option index';
  END IF;

  -- Insert or update vote
  INSERT INTO poll_votes (post_id, user_id, option_index)
  VALUES (p_post_id, current_user_id, p_option_index)
  ON CONFLICT (post_id, user_id) DO UPDATE SET option_index = p_option_index;
  
END;
$$;

-- RPC: get poll results with user vote
CREATE OR REPLACE FUNCTION get_poll_results(
  p_post_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  current_user_id uuid;
  poll_data jsonb;
  total_votes int;
  i int;
BEGIN
  current_user_id := auth.uid();
  SELECT poll INTO poll_data FROM posts WHERE id = p_post_id;
  IF poll_data IS NULL THEN RETURN null; END IF;
  
  SELECT count(*) INTO total_votes FROM poll_votes WHERE post_id = p_post_id;
  
  -- Add results to each option
  FOR i IN 0..jsonb_array_length(poll_data)-1 LOOP
    DECLARE
      option_votes int := (SELECT count(*) FROM poll_votes WHERE post_id = p_post_id AND option_index = i);
    BEGIN
      poll_data := jsonb_set(
        poll_data, 
        ARRAY[i::text], 
        (poll_data->i) || jsonb_build_object(
          'votes', option_votes,
          'percentage', CASE WHEN total_votes > 0 THEN round(option_votes * 100.0 / total_votes, 1) ELSE 0 END
        )
      );
    END;
  END LOOP;
  
  RETURN poll_data;  
END;
$$;
