-- Step 1: Drop all foreign key constraints that reference uuid columns
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT conname, conrelid::regclass AS table_name
    FROM pg_constraint
    WHERE contype = 'f'
    AND confrelid IN (
      SELECT c.oid FROM pg_class c
      JOIN pg_namespace n ON c.relnamespace = n.oid
      WHERE n.nspname = 'public'
    )
  LOOP
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', r.table_name, r.conname);
    RAISE NOTICE 'Dropped FK: % on %', r.conname, r.table_name;
  END LOOP;
END $$;

-- Step 2: Drop all policies (clean slate)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- Step 3: Now change all uuid columns to text
DO $$
DECLARE
  t RECORD;
BEGIN
  FOR t IN
    SELECT table_name, column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND data_type = 'uuid'
  LOOP
    BEGIN
      EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE text', t.table_name, t.column_name);
      RAISE NOTICE 'OK: %.%', t.table_name, t.column_name;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'SKIP: %.% - %', t.table_name, t.column_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- Step 4: Recreate RLS policies for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid()::text = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid()::text = id);
CREATE POLICY "Users can delete own profile" ON profiles FOR DELETE USING (auth.uid()::text = id);

-- Step 5: Verify
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND data_type IN ('text','uuid')
AND column_name IN ('id','user_id','follower_id','following_id','blocker_id','blocked_id','sender_id','receiver_id','reporter_id','reported_user_id','owner_id','passenger_id','driver_id','admin_id','friend_id','user1_id','user2_id')
ORDER BY table_name, column_name;
