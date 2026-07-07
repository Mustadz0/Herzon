-- Migration 024: Full Messenger System (idempotent)
-- Adds conversations table, extends messages with conversation_id, creates RPCs

-- Conversations table (1:1 between two users)
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user1_id, user2_id),
  CHECK (user1_id < user2_id)
);

-- Add conversation_id to messages if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'conversation_id'
  ) THEN
    ALTER TABLE messages ADD COLUMN conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add message_type if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'message_type'
  ) THEN
    ALTER TABLE messages ADD COLUMN message_type TEXT NOT NULL DEFAULT 'text';
  END IF;
END $$;

-- Add media_url if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'media_url'
  ) THEN
    ALTER TABLE messages ADD COLUMN media_url TEXT;
  END IF;
END $$;

-- Add sticker_id if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'sticker_id'
  ) THEN
    ALTER TABLE messages ADD COLUMN sticker_id TEXT;
  END IF;
END $$;

-- Add is_read if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'is_read'
  ) THEN
    ALTER TABLE messages ADD COLUMN is_read BOOLEAN NOT NULL DEFAULT false;
  END IF;
END $$;

-- Add read_at if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'read_at'
  ) THEN
    ALTER TABLE messages ADD COLUMN read_at TIMESTAMPTZ;
  END IF;
END $$;

-- Indexes (safe to re-create)
CREATE INDEX IF NOT EXISTS idx_conversations_users ON conversations(user1_id, user2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(conversation_id, sender_id, is_read) WHERE is_read = false;

-- Function to get or create conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(other_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
  conv_id UUID;
  u1 UUID;
  u2 UUID;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id < other_user_id THEN
    u1 := current_user_id;
    u2 := other_user_id;
  ELSE
    u1 := other_user_id;
    u2 := current_user_id;
  END IF;
  
  SELECT id INTO conv_id
  FROM conversations
  WHERE user1_id = u1 AND user2_id = u2;
  
  IF conv_id IS NULL THEN
    INSERT INTO conversations (user1_id, user2_id)
    VALUES (u1, u2)
    RETURNING id INTO conv_id;
  END IF;
  
  RETURN conv_id;
END;
$$;

-- Function to send a message
CREATE OR REPLACE FUNCTION send_message(
  p_conversation_id UUID,
  p_content TEXT,
  p_message_type TEXT DEFAULT 'text',
  p_media_url TEXT DEFAULT NULL,
  p_sticker_id TEXT DEFAULT NULL
)
RETURNS messages
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  new_message messages;
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();
  
  IF NOT EXISTS (
    SELECT 1 FROM conversations
    WHERE id = p_conversation_id
    AND (user1_id = current_user_id OR user2_id = current_user_id)
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
  
  INSERT INTO messages (conversation_id, sender_id, content, message_type, media_url, sticker_id)
  VALUES (p_conversation_id, current_user_id, p_content, p_message_type, p_media_url, p_sticker_id)
  RETURNING * INTO new_message;
  
  UPDATE conversations
  SET last_message_at = now(), updated_at = now()
  WHERE id = p_conversation_id;
  
  RETURN new_message;
END;
$$;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_read(p_conversation_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  UPDATE messages
  SET is_read = true, read_at = now()
  WHERE conversation_id = p_conversation_id
  AND sender_id != auth.uid()
  AND is_read = false;
END;
$$;

-- Function to get conversation list with last message
CREATE OR REPLACE FUNCTION get_conversations()
RETURNS TABLE (
  conversation_id UUID,
  other_user_id UUID,
  other_user_name TEXT,
  other_user_avatar TEXT,
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count BIGINT
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();
  
  RETURN QUERY
  SELECT
    c.id AS conversation_id,
    CASE WHEN c.user1_id = current_user_id THEN c.user2_id ELSE c.user1_id END AS other_user_id,
    p.display_name AS other_user_name,
    p.avatar_url AS other_user_avatar,
    lm.content AS last_message,
    c.last_message_at,
    COALESCE(unread.cnt, 0) AS unread_count
  FROM conversations c
  JOIN profiles p ON p.id = CASE WHEN c.user1_id = current_user_id THEN c.user2_id ELSE c.user1_id END
  LEFT JOIN LATERAL (
    SELECT content
    FROM messages
    WHERE conversation_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) lm ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS cnt
    FROM messages
    WHERE conversation_id = c.id
    AND sender_id != current_user_id
    AND is_read = false
  ) unread ON true
  WHERE c.user1_id = current_user_id OR c.user2_id = current_user_id
  ORDER BY c.last_message_at DESC NULLS LAST;
END;
$$;

-- RLS policies (safe to re-create)
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users see own conversations" ON conversations;
CREATE POLICY "Users see own conversations"
  ON conversations FOR SELECT
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can update own conversations" ON conversations;
CREATE POLICY "Users can update own conversations"
  ON conversations FOR UPDATE
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users see messages in own conversations" ON messages;
CREATE POLICY "Users see messages in own conversations"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE id = conversation_id
      AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can send messages in own conversations" ON messages;
CREATE POLICY "Users can send messages in own conversations"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE id = conversation_id
      AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update own messages" ON messages;
CREATE POLICY "Users can update own messages"
  ON messages FOR UPDATE
  USING (auth.uid() = sender_id);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Grant execute
GRANT EXECUTE ON FUNCTION get_or_create_conversation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION send_message(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_messages_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversations() TO authenticated;
