-- Migration 044: Hardcode edge function URL since app.supabase_url cannot be set

CREATE OR REPLACE FUNCTION public.trigger_send_push_notification()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_edge_url        text := 'https://xhjglurrmnmpqzbvctgn.supabase.co/functions/v1/send-push';
  v_service_key     text;
  v_internal_secret text;
  v_payload         jsonb;
  v_fcm_tokens      text[];
BEGIN
  IF NEW.title IS NULL OR NEW.body IS NULL THEN RETURN NEW; END IF;

  SELECT array_agg(dt.fcm_token) INTO v_fcm_tokens
  FROM public.device_tokens dt WHERE dt.user_id = NEW.user_id;

  IF v_fcm_tokens IS NULL OR array_length(v_fcm_tokens, 1) IS NULL THEN RETURN NEW; END IF;

  BEGIN
    SELECT decrypted_secret INTO v_service_key
    FROM vault.decrypted_secrets WHERE name = 'SERVICE_ROLE_KEY' LIMIT 1;
    SELECT decrypted_secret INTO v_internal_secret
    FROM vault.decrypted_secrets WHERE name = 'INTERNAL_FUNCTION_SECRET' LIMIT 1;
  EXCEPTION WHEN others THEN
    RAISE WARNING 'push_trigger: Vault secrets not found -- skipping push.';
    RETURN NEW;
  END;

  IF v_service_key IS NULL OR v_internal_secret IS NULL THEN
    RAISE WARNING 'push_trigger: Vault secrets are NULL -- skipping push.';
    RETURN NEW;
  END IF;

  v_payload := jsonb_build_object(
    'user_id', NEW.user_id, 'title', NEW.title, 'body', NEW.body,
    'data', COALESCE(NEW.data, '{}') || jsonb_build_object('type', NEW.type, 'notification_id', NEW.id)
  );

  PERFORM net.http_post(
    url     := v_edge_url,
    headers := jsonb_build_object(
      'Content-Type',               'application/json',
      'Authorization',              'Bearer ' || v_service_key,
      'X-Internal-Function-Secret', v_internal_secret
    ),
    body    := v_payload::text,
    timeout_milliseconds := 5000
  );
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.trigger_send_push_notification() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.trigger_send_push_notification() TO supabase_admin, service_role;
