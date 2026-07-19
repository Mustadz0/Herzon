SELECT conname, conrelid::regclass AS tbl, confrelid::regclass AS reftbl, pg_get_constraintdef(oid)
FROM pg_constraint WHERE confrelid = 'profiles'::regclass OR conrelid = 'profiles'::regclass;
