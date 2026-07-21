-- MIGRATION 048: Fix admin_toggle_feature_flag column mismatch
-- The RPC was writing to flag_key/is_enabled columns that don't exist in feature_config
-- feature_config has: key (text), value (jsonb), description, updated_at

CREATE OR REPLACE FUNCTION public.admin_toggle_feature_flag(flag_key text, is_enabled boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  INSERT INTO feature_config (key, value, updated_at)
  VALUES (flag_key, jsonb_build_object('enabled', is_enabled), now())
  ON CONFLICT (key) DO UPDATE SET
    value = COALESCE(feature_config.value, '{}'::jsonb) || jsonb_build_object('enabled', is_enabled),
    updated_at = now();
END;
$$;
