-- Enable pg_net for async HTTP calls (already installed: 0.20.3)
-- This trigger calls the send-push edge function when a new notification is inserted

CREATE OR REPLACE FUNCTION public.trigger_send_push_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  edge_url text;
  payload jsonb;
  fcm_tokens text[];
BEGIN
  IF NEW.title IS NULL OR NEW.body IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT array_agg(dt.fcm_token) INTO fcm_tokens
  FROM public.device_tokens dt
  WHERE dt.user_id = NEW.user_id;

  IF fcm_tokens IS NULL OR array_length(fcm_tokens, 1) IS NULL THEN
    RETURN NEW;
  END IF;

  edge_url := 'https://xhjglurrmnmpqzbvctgn.supabase.co/functions/v1/send-push';

  payload := jsonb_build_object(
    'user_id', NEW.user_id,
    'title', NEW.title,
    'body', NEW.body,
    'data', COALESCE(NEW.data, '{}'::jsonb) || jsonb_build_object('type', NEW.type, 'notification_id', NEW.id)
  );

  PERFORM
    net.http_post(
      url := edge_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoamdsdXJybW5tcHF6YnZjdGduIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MjcyMjc4NCwiZXhwIjoyMDk4Mjk4Nzg0fQ.OBz42N4iBcfJcwJS_M7BDUMepT5CfbMMQd8jMZnfBKU',
        'X-Internal-Function-Secret', 'wP7pmXl4ovH8zZ3kLFu9gYN2hTxiJq0Qft1SRbndUsDcOW5BGyMjaKC6AeVEIr'
      ),
      body := payload::text,
      timeout_milliseconds := 5000
    );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_notification_insert ON public.notifications;

CREATE TRIGGER on_notification_insert
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_send_push_notification();

GRANT USAGE ON SCHEMA public TO supabase_admin, service_role;
GRANT EXECUTE ON FUNCTION public.trigger_send_push_notification() TO supabase_admin, service_role;
