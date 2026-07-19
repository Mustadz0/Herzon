-- Step 1: Check all dependencies
SELECT viewname, definition FROM pg_views WHERE definition LIKE '%profiles.id%';

-- Step 2: List all policies on profiles
SELECT policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies WHERE tablename = 'profiles';

-- Step 3: List all FKs referencing profiles.id
SELECT conname, conrelid::regclass AS table_name, pg_get_constraintdef(oid)
FROM pg_constraint WHERE confrelid = 'profiles'::regclass;

-- Step 4: Check profiles.id type
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'id';
