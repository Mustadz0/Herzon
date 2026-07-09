-- Fix ambiguous conversation_id in messages RLS policies
-- Problem: PostgreSQL cannot resolve conversation_id when both messages and conversations tables are in scope
-- Solution: Drop and recreate RLS policies with explicit table references

-- Drop existing policies
DROP POLICY IF EXISTS "Users see messages in own conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages in own conversations" ON messages;

-- Recreate with explicit table qualification
CREATE POLICY "Users see messages in own conversations"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = messages.conversation_id
      AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
  );

CREATE POLICY "Users can send messages in own conversations"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = messages.conversation_id
      AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
  );
