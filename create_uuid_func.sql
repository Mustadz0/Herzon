-- Create UUID v5 function matching Dart's FirebaseUuid.toUuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION firebase_uid_to_uuid(firebase_uid text)
RETURNS uuid AS $$
DECLARE
  namespace bytea := '\x6ba7b8119dad11d180b400c04fd430c8';
  hash bytea;
BEGIN
  hash := digest(namespace || convert_to('firebase:' || firebase_uid, 'UTF8'), 'sha1');

  -- Set version to 5 (0101 in upper 4 bits of byte 6)
  hash := set_byte(hash, 6, (get_byte(hash, 6) & 15) | 80);
  -- Set variant to RFC 4122 (10xx in upper 2 bits of byte 8)
  hash := set_byte(hash, 8, (get_byte(hash, 8) & 63) | 128);

  -- First 16 bytes as hex -> UUID (PostgreSQL accepts hex without hyphens)
  RETURN encode(substr(hash, 1, 16), 'hex')::uuid;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- Drop old policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Profiles select own" ON profiles;
DROP POLICY IF EXISTS "Profiles update own" ON profiles;
DROP POLICY IF EXISTS "Profiles insert own" ON profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;

-- Create policies using Firebase UID from JWT converted to UUID v5
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (firebase_uid_to_uuid(auth.jwt() ->> 'sub') = id);

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (firebase_uid_to_uuid(auth.jwt() ->> 'sub') = id);

CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (firebase_uid_to_uuid(auth.jwt() ->> 'sub') = id);

-- Test
SELECT firebase_uid_to_uuid('IVYjpUoL9BUblZzSWyOmSXYGsx92') as test_uuid;
