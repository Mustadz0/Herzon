-- Enable pg_net for async HTTP calls (already installed: 0.20.3)
-- This trigger calls the send-push edge function when a new notification is inserted

-- Get the Supabase project URL from the environment (set during supabase start)
-- In production, this resolves automatically from the internal Supabase URL

CREATE OR REPLACE FUNCTION public.trigger_send_push_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  edge_url text;
  internal_secret text;
  payload jsonb;
  fcm_tokens text[];
BEGIN
  -- Only send push for notifications with a title and body
  IF NEW.title IS NULL OR NEW.body IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get FCM tokens for the target user
  SELECT array_agg(dt.fcm_token) INTO fcm_tokens
  FROM public.device_tokens dt
  WHERE dt.user_id = NEW.user_id;

  IF fcm_tokens IS NULL OR array_length(fcm_tokens, 1) IS NULL THEN
    RETURN NEW;
  END IF;

  -- Build the edge function URL (uses internal Supabase URL for zero-cost calls)
  edge_url := current_setting('supabase_url', true);
  IF edge_url IS NULL OR edge_url = '' THEN
    edge_url := 'https://xhjglurrmnmpqzbvctgn.supabase.co';
  END IF;
  edge_url := edge_url || '/functions/v1/send-push';
  internal_secret := current_setting('app.internal_function_secret', true);

  -- Build the request payload
  payload := jsonb_build_object(
    'user_id', NEW.user_id,
    'title', NEW.title,
    'body', NEW.body,
    'data', COALESCE(NEW.data, '{}'::jsonb) || jsonb_build_object('type', NEW.type, 'notification_id', NEW.id)
  );

  -- Call the edge function asynchronously via pg_net
  PERFORM
    net.http_post(
      url := edge_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('supabase_anon_key', true),
        'X-Internal-Function-Secret', COALESCE(internal_secret, '')
      ),
      body := payload::text,
      timeout_milliseconds := 5000
    );

  RETURN NEW;
END;
$$;

-- Drop existing webhook config if re-running
DROP TRIGGER IF EXISTS on_notification_insert ON public.notifications;

CREATE TRIGGER on_notification_insert
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_send_push_notification();

-- Grant usage
GRANT USAGE ON SCHEMA public TO supabase_admin, service_role;
GRANT EXECUTE ON FUNCTION public.trigger_send_push_notification() TO supabase_admin, service_role;

-- Note: For this to work, the Supabase project settings must be available as:
--   current_setting('supabase_url')
--   current_setting('supabase_anon_key')
-- These are set by Supabase internally. If missing, the fallback URL is used.
