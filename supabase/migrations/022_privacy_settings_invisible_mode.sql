-- Add privacy_settings columns to profiles (update default to include all new keys)
ALTER TABLE public.profiles
  ALTER COLUMN privacy_settings SET DEFAULT '{
    "show_activity": true,
    "allow_messages": true,
    "show_profile_to": "all",
    "allow_add_proches": true,
    "show_zone": true,
    "show_age": true,
    "show_details": true,
    "invisible_mode": false
  }'::jsonb;

-- Update existing rows that have null or incomplete privacy_settings
UPDATE public.profiles
SET privacy_settings = COALESCE(privacy_settings, '{}'::jsonb) || '{
  "show_profile_to": "all",
  "allow_add_proches": true,
  "show_zone": true,
  "show_age": true,
  "show_details": true,
  "invisible_mode": false
}'::jsonb
WHERE privacy_settings IS NULL
   OR NOT (privacy_settings ? 'show_profile_to')
   OR NOT (privacy_settings ? 'invisible_mode');
