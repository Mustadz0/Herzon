-- Fix privacy_settings validation trigger to match actual Dart keys
CREATE OR REPLACE FUNCTION public.validate_privacy_settings()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_key       text;
  v_allowed   text[] := ARRAY[
    'show_activity','allow_messages','show_profile_to','allow_add_proches',
    'show_zone','show_age','show_details','invisible_mode'
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
