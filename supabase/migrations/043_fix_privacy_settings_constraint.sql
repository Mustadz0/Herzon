-- Migration 043: Fix privacy_settings check constraint (replaces failed Part J)
-- PG cannot use subqueries in CHECK constraints, so use a trigger instead.

DROP POLICY IF EXISTS "chk_privacy_settings_keys" ON public.profiles;

CREATE OR REPLACE FUNCTION public.validate_privacy_settings()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_key       text;
  v_valid     boolean;
  v_allowed   text[] := ARRAY[
    'show_last_seen','show_online_status','show_location','allow_friend_requests',
    'show_bio','show_photos','show_posts','show_friends','allow_tagging',
    'allow_message','allow_comment','show_age','show_gender'
  ];
BEGIN
  IF NEW.privacy_settings IS NULL THEN RETURN NEW; END IF;
  IF jsonb_typeof(NEW.privacy_settings) <> 'object' THEN
    RAISE EXCEPTION 'privacy_settings must be a JSON object';
  END IF;
  FOR v_key IN SELECT jsonb_object_keys(NEW.privacy_settings) LOOP
    IF NOT (v_key = ANY(v_allowed)) THEN
      RAISE EXCEPTION 'Invalid privacy setting key: %', v_key;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_privacy_settings ON public.profiles;
CREATE TRIGGER trg_validate_privacy_settings
  BEFORE INSERT OR UPDATE OF privacy_settings ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.validate_privacy_settings();
