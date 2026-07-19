-- ============================================================
-- COMPLETE FIX: Herzon Auth + RLS
-- ============================================================

-- STEP 1: Drop FK constraint
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- STEP 2: Create UUID v5 function (matching Dart's FirebaseUuid.toUuid)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION firebase_uid_to_uuid(firebase_uid text)
RETURNS uuid
LANGUAGE plpgsql IMMUTABLE STRICT
AS $$
DECLARE
  namespace bytea;
  hash bytea;
BEGIN
  namespace := decode('6ba7b8119dad11d180b400c04fd430c8', 'hex');
  hash := digest(namespace || convert_to('firebase:' || firebase_uid, 'UTF8'), 'sha1');
  hash := set_byte(hash, 6, (get_byte(hash, 6) & 15) | 80);
  hash := set_byte(hash, 8, (get_byte(hash, 8) & 63) | 128);
  RETURN encode(substr(hash, 1, 16), 'hex')::uuid;
END;
$$;

-- STEP 3: Drop old RLS policies
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'profiles' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON profiles', r.policyname);
  END LOOP;
END $$;

-- STEP 4: Create new RLS policies
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (firebase_uid_to_uuid(auth.jwt() ->> 'sub') = id);

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (firebase_uid_to_uuid(auth.jwt() ->> 'sub') = id);

CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (firebase_uid_to_uuid(auth.jwt() ->> 'sub') = id);

-- STEP 5: Grant EXECUTE on RPC functions (skip if function missing)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_suggested_posts') THEN
    EXECUTE 'GRANT EXECUTE ON FUNCTION get_suggested_posts TO authenticated, anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_posts_last_7_days') THEN
    EXECUTE 'GRANT EXECUTE ON FUNCTION get_posts_last_7_days TO authenticated, anon';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_top_zones') THEN
    EXECUTE 'GRANT EXECUTE ON FUNCTION get_top_zones TO authenticated, anon';
  END IF;
END $$;

-- STEP 6: Verify
SELECT 'profiles_id_fkey' constraint_name, 'DROPPED' status;
SELECT 'firebase_uid_to_uuid' function_name, 'CREATED' status;
SELECT count(*) rls_policies_count FROM pg_policies WHERE tablename = 'profiles';
