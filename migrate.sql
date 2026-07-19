-- Run this in Supabase SQL Editor
-- https://supabase.com/dashboard/project/xhjglurrmnmpqzbvctgn/sql/new

DO $$ 
DECLARE 
  t RECORD;
  col RECORD;
BEGIN
  FOR t IN 
    SELECT c.table_name, c.column_name 
    FROM information_schema.columns c
    JOIN information_schema.table_constraints tc
      ON c.table_name = tc.table_name 
      AND c.table_schema = tc.table_schema
    WHERE c.table_schema = 'public' 
    AND c.data_type = 'uuid'
    AND c.column_name IN ('id','user_id','follower_id','following_id','blocker_id','blocked_id','sender_id','receiver_id','reporter_id','reported_user_id','owner_id','passenger_id','driver_id','admin_id','friend_id','user1_id','user2_id')
  LOOP
    BEGIN
      EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE text', t.table_name, t.column_name);
      RAISE NOTICE 'OK: %.%', t.table_name, t.column_name;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'SKIP: %.% - %', t.table_name, t.column_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- Verify
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND column_name IN ('id','user_id','follower_id','following_id','blocker_id','blocked_id','sender_id','receiver_id','reporter_id','reported_user_id','owner_id','passenger_id','driver_id','admin_id','friend_id','user1_id','user2_id')
AND data_type IN ('text','uuid')
ORDER BY table_name, column_name;
