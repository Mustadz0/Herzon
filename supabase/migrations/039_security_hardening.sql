-- =============================================================================
-- MIGRATION 039: SECURITY HARDENING — Fix All Critical & High Vulnerabilities
-- =============================================================================
-- Vulnerabilities fixed:
--   [CRITICAL-1] Hardcoded service_role JWT + internal secret in migration 036
--   [CRITICAL-2] Project URL exposed in migration 036
--   [HIGH-3]     get_blocked_user_ids accepts user-controlled UUID param
--   [HIGH-4]     mark_messages_read — no conversation membership check
--   [HIGH-5]     admin_delete_post — permanent delete, no audit trail
--   [HIGH-6]     is_admin check duplicated manually in some functions
--   [MED-7]      privacy_settings JSONB has no key/type constraints
--   [MED-8]      conversations INSERT RLS allows non-participant to create conv
--   [MED-9]      send_message — no rate limiting at DB level
--   [MED-10]     media_url accepts any arbitrary URL (SSRF risk)
-- =============================================================================

-- ============================================================
-- [CRITICAL-1 & CRITICAL-2] Re-create push trigger WITHOUT
-- hardcoded secrets. Secrets must be injected at runtime via
-- Supabase Vault / Edge Function env vars.
-- Steps required OUTSIDE this migration:
--   1. Dashboard → Settings → API → Regenerate service_role key
--   2. Dashboard → Edge Functions → send-push → Secrets:
--        INTERNAL_FUNCTION_SECRET = <new random 64-char string>
--   3. Set Vault secret "SERVICE_ROLE_KEY" in Supabase Dashboard
--      (Settings → Vault) with the new service_role key value
-- ============================================================

CREATE OR REPLACE FUNCTION public.trigger_send_push_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_edge_url       text;
  v_service_key    text;
  v_internal_secret text;
  v_payload        jsonb;
  v_fcm_tokens     text[];
BEGIN
  -- Guard: skip if no title/body
  IF NEW.title IS NULL OR NEW.body IS NULL THEN
    RETURN NEW;
  END IF;

  -- Collect FCM tokens for the target user
  SELECT array_agg(dt.fcm_token)
  INTO v_fcm_tokens
  FROM public.device_tokens dt
  WHERE dt.user_id = NEW.user_id;

  IF v_fcm_tokens IS NULL OR array_length(v_fcm_tokens, 1) IS NULL THEN
    RETURN NEW;
  END IF;

  -- [FIX CRITICAL-1] Read secrets from Supabase Vault — never hardcode!
  -- Vault keys must be created via Dashboard → Settings → Vault before deploy.
  BEGIN
    SELECT decrypted_secret
    INTO v_service_key
    FROM vault.decrypted_secrets
    WHERE name = 'SERVICE_ROLE_KEY'
    LIMIT 1;

    SELECT decrypted_secret
    INTO v_internal_secret
    FROM vault.decrypted_secrets
    WHERE name = 'INTERNAL_FUNCTION_SECRET'
    LIMIT 1;
  EXCEPTION WHEN others THEN
    -- Vault not configured: fail silently and skip push (do NOT crash insert)
    RAISE WARNING 'push_trigger: Vault secrets not found — skipping push. Configure SERVICE_ROLE_KEY and INTERNAL_FUNCTION_SECRET in Supabase Vault.';
    RETURN NEW;
  END;

  IF v_service_key IS NULL OR v_internal_secret IS NULL THEN
    RAISE WARNING 'push_trigger: Vault secrets are NULL — skipping push.';
    RETURN NEW;
  END IF;

  -- [FIX CRITICAL-2] Build URL dynamically from current project ref
  -- (avoids hardcoding project URL in SQL)
  SELECT 'https://' || current_setting('app.supabase_url', true) || '/functions/v1/send-push'
  INTO v_edge_url;

  -- Fallback: if app.supabase_url not set, use pg_catalog approach
  IF v_edge_url IS NULL OR v_edge_url = 'https:///functions/v1/send-push' THEN
    RAISE WARNING 'push_trigger: app.supabase_url not set. Set it via: ALTER DATABASE postgres SET app.supabase_url = ''<ref>.supabase.co'';';
    RETURN NEW;
  END IF;

  v_payload := jsonb_build_object(
    'user_id',  NEW.user_id,
    'title',    NEW.title,
    'body',     NEW.body,
    'data',     COALESCE(NEW.data, '{}'::jsonb)
                || jsonb_build_object(
                     'type',            NEW.type,
                     'notification_id', NEW.id
                   )
  );

  PERFORM net.http_post(
    url     := v_edge_url,
    headers := jsonb_build_object(
      'Content-Type',             'application/json',
      'Authorization',            'Bearer ' || v_service_key,
      'X-Internal-Function-Secret', v_internal_secret
    ),
    body    := v_payload::text,
    timeout_milliseconds := 5000
  );

  RETURN NEW;
END;
$$;

-- Re-attach trigger (idempotent)
DROP TRIGGER IF EXISTS on_notification_insert ON public.notifications;
CREATE TRIGGER on_notification_insert
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_send_push_notification();

GRANT EXECUTE ON FUNCTION public.trigger_send_push_notification() TO supabase_admin, service_role;


-- ============================================================
-- [HIGH-3] Fix get_blocked_user_ids
-- Remove the user-controlled UUID parameter entirely.
-- Always uses auth.uid() — callers cannot spy on other users.
-- ============================================================

-- Drop old overloaded version first
DROP FUNCTION IF EXISTS public.get_blocked_user_ids(uuid);

CREATE OR REPLACE FUNCTION public.get_blocked_user_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT blocked_id
  FROM blocked_users
  WHERE blocker_id = auth.uid()
  UNION
  SELECT blocker_id
  FROM blocked_users
  WHERE blocked_id = auth.uid();
$$;

COMMENT ON FUNCTION public.get_blocked_user_ids() IS
  'Returns all user IDs blocked by or blocking the current authenticated user. '
  'Always uses auth.uid() — no caller-controlled parameter to prevent privacy leaks.';

REVOKE ALL ON FUNCTION public.get_blocked_user_ids() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_blocked_user_ids() TO authenticated;


-- ============================================================
-- [HIGH-4] Fix mark_messages_read
-- Add membership check BEFORE updating — prevents marking
-- messages in conversations the caller doesn't belong to.
-- ============================================================

CREATE OR REPLACE FUNCTION public.mark_messages_read(p_conversation_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  -- [FIX HIGH-4] Verify caller is a participant in this conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversations
    WHERE id = p_conversation_id
      AND (user1_id = v_uid OR user2_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'Not authorized: you are not a participant in this conversation';
  END IF;

  UPDATE messages
  SET
    is_read  = true,
    read_at  = now()
  WHERE conversation_id = p_conversation_id
    AND sender_id != v_uid
    AND is_read = false;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_messages_read(UUID) TO authenticated;


-- ============================================================
-- [MED-8] Fix conversations INSERT RLS
-- Tighten policy: auth.uid() must be user1_id OR user2_id,
-- AND the canonical ordering (user1_id < user2_id) is enforced
-- by the existing CHECK constraint on the table.
-- The old policy allowed creating a conversation between two
-- OTHER users if auth.uid() matched either slot.
-- ============================================================

DROP POLICY IF EXISTS "Users can create conversations" ON conversations;

CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT
  WITH CHECK (
    -- auth.uid() must be one of the two participants
    (auth.uid() = user1_id OR auth.uid() = user2_id)
    -- and both participants must be distinct (can't start conv with yourself)
    AND user1_id != user2_id
  );


-- ============================================================
-- [MED-9] Rate limiting on send_message
-- Max 30 messages per user per minute at DB level.
-- ============================================================

CREATE OR REPLACE FUNCTION public.send_message(
  p_conversation_id UUID,
  p_content         TEXT,
  p_message_type    TEXT    DEFAULT 'text',
  p_media_url       TEXT    DEFAULT NULL,
  p_sticker_id      TEXT    DEFAULT NULL
)
RETURNS messages
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_new_message    messages;
  v_uid            UUID    := auth.uid();
  v_recent_count   INT;
  v_allowed_domain TEXT    := '.supabase.co';
BEGIN
  -- Authorization: caller must be a participant
  IF NOT EXISTS (
    SELECT 1 FROM conversations
    WHERE id = p_conversation_id
      AND (user1_id = v_uid OR user2_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  -- [FIX MED-9] Rate limit: max 30 messages per 60 seconds per user
  SELECT COUNT(*) INTO v_recent_count
  FROM messages
  WHERE sender_id = v_uid
    AND created_at > now() - INTERVAL '60 seconds';

  IF v_recent_count >= 30 THEN
    RAISE EXCEPTION 'Rate limit exceeded: max 30 messages per minute';
  END IF;

  -- [FIX MED-10] Validate media_url: must be NULL or a Supabase storage URL
  -- belonging to this project (prevents SSRF / hosting external content)
  IF p_media_url IS NOT NULL THEN
    IF NOT (
      p_media_url ~ '^https://[a-z0-9]+\.supabase\.co/storage/v1/object/(public|authenticated)/'
    ) THEN
      RAISE EXCEPTION 'Invalid media_url: only Supabase Storage URLs are allowed';
    END IF;
  END IF;

  INSERT INTO messages (
    conversation_id, sender_id, content,
    message_type, media_url, sticker_id
  )
  VALUES (
    p_conversation_id, v_uid, p_content,
    p_message_type, p_media_url, p_sticker_id
  )
  RETURNING * INTO v_new_message;

  UPDATE conversations
  SET last_message_at = now(), updated_at = now()
  WHERE id = p_conversation_id;

  RETURN v_new_message;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_message(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated;


-- ============================================================
-- [HIGH-5 & HIGH-6] Admin Audit Log + Soft Delete
-- All admin destructive actions are logged and reversible.
-- ============================================================

-- Audit log table
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id     uuid        NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
  action       text        NOT NULL,          -- e.g. 'delete_post', 'ban_user'
  target_type  text        NOT NULL,          -- e.g. 'post', 'user', 'comment'
  target_id    uuid        NOT NULL,
  metadata     jsonb       DEFAULT '{}',      -- snapshot or extra info
  created_at   timestamptz DEFAULT now()
);

COMMENT ON TABLE public.admin_audit_log IS
  'Immutable audit trail for all admin actions. Rows are INSERT-only.';

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Admins can read the log; nobody can update or delete rows
DROP POLICY IF EXISTS "Admins can read audit log" ON public.admin_audit_log;
CREATE POLICY "Admins can read audit log"
  ON public.admin_audit_log FOR SELECT
  USING (public.current_user_is_admin());

-- Only service_role / admin RPCs insert (no direct user insert)
DROP POLICY IF EXISTS "Service role inserts audit log" ON public.admin_audit_log;
CREATE POLICY "Service role inserts audit log"
  ON public.admin_audit_log FOR INSERT
  WITH CHECK (public.current_user_is_admin());

-- Explicitly deny UPDATE and DELETE for everyone
CREATE POLICY "No update on audit log"
  ON public.admin_audit_log FOR UPDATE
  USING (false);

CREATE POLICY "No delete on audit log"
  ON public.admin_audit_log FOR DELETE
  USING (false);

CREATE INDEX IF NOT EXISTS idx_admin_audit_admin_id  ON public.admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target     ON public.admin_audit_log(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created_at ON public.admin_audit_log(created_at DESC);

-- Add soft-delete column to posts if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'posts' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE posts ADD COLUMN deleted_at timestamptz DEFAULT NULL;
    ALTER TABLE posts ADD COLUMN deleted_by uuid REFERENCES profiles(id) ON DELETE SET NULL;
    COMMENT ON COLUMN posts.deleted_at IS 'Set by admin soft-delete. NULL = not deleted.';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_posts_deleted_at ON posts(deleted_at) WHERE deleted_at IS NOT NULL;

-- [FIX HIGH-5] Replace hard-delete with soft-delete + audit log
CREATE OR REPLACE FUNCTION public.admin_delete_post(target_post_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_post_snap jsonb;
BEGIN
  -- [FIX HIGH-6] Centralised admin check
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Permission denied: admin only';
  END IF;

  -- Snapshot the post before deletion for audit
  SELECT to_jsonb(p) INTO v_post_snap
  FROM posts p
  WHERE p.id = target_post_id;

  IF v_post_snap IS NULL THEN
    RAISE EXCEPTION 'Post not found: %', target_post_id;
  END IF;

  -- Soft-delete instead of hard DELETE
  UPDATE posts
  SET
    deleted_at = now(),
    deleted_by = v_uid
  WHERE id = target_post_id;

  -- Write immutable audit record
  INSERT INTO public.admin_audit_log
    (admin_id, action, target_type, target_id, metadata)
  VALUES
    (v_uid, 'delete_post', 'post', target_post_id, v_post_snap);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_post(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_post(UUID) TO authenticated;


-- ============================================================
-- [HIGH-6] Unify is_admin check — ensure current_user_is_admin()
-- exists and is the single source of truth.
-- (It was already created in migration 031/037 for most
--  functions; this confirms the canonical definition.)
-- ============================================================

CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND is_admin = true
  );
$$;

REVOKE ALL ON FUNCTION public.current_user_is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_user_is_admin() TO authenticated, service_role;


-- ============================================================
-- [MED-7] Constrain privacy_settings JSONB to known keys only
-- Prevents injection of arbitrary keys into the settings object.
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'chk_privacy_settings_keys'
      AND table_name = 'profiles'
  ) THEN
    ALTER TABLE public.profiles
    ADD CONSTRAINT chk_privacy_settings_keys CHECK (
      privacy_settings IS NULL
      OR (
        -- Only allow known boolean-valued keys
        (privacy_settings - ARRAY[
          'show_location',
          'show_online_status',
          'show_last_seen',
          'show_followers',
          'show_following',
          'allow_messages_from_strangers',
          'invisible_mode',
          'private_account'
        ]) = '{}'
        -- All present values must be booleans
        AND NOT EXISTS (
          SELECT 1
          FROM jsonb_each(privacy_settings) kv
          WHERE jsonb_typeof(kv.value) != 'boolean'
        )
      )
    );
  END IF;
END $$;


-- ============================================================
-- Housekeeping: update existing RLS on posts to hide soft-deleted rows
-- ============================================================

DROP POLICY IF EXISTS "Users can view published posts" ON posts;
CREATE POLICY "Users can view published posts"
  ON posts FOR SELECT
  USING (
    deleted_at IS NULL
    AND (
      user_id = auth.uid()
      OR is_public = true
      OR EXISTS (
        SELECT 1 FROM follows f
        WHERE f.follower_id = auth.uid()
          AND f.following_id = posts.user_id
      )
    )
  );

-- Admins can still see soft-deleted posts for review
DROP POLICY IF EXISTS "Admins can view all posts" ON posts;
CREATE POLICY "Admins can view all posts"
  ON posts FOR SELECT
  USING (public.current_user_is_admin());


-- ============================================================
-- IMPORTANT: Manual steps required after running this migration
-- ============================================================
-- 1. Supabase Dashboard → Settings → API
--    → Click "Regenerate" next to service_role key
--    → Update any server-side env vars that use the old key
--
-- 2. Supabase Dashboard → Settings → Vault (Secrets Manager)
--    → Add secret:  SERVICE_ROLE_KEY   = <new service_role JWT>
--    → Add secret:  INTERNAL_FUNCTION_SECRET = <new 64-char random string>
--
-- 3. Update Edge Function send-push secrets:
--    Dashboard → Edge Functions → send-push → Secrets
--    → INTERNAL_FUNCTION_SECRET = same value as Vault
--
-- 4. Set app.supabase_url in your database:
--    ALTER DATABASE postgres SET app.supabase_url = '<ref>.supabase.co';
--    (Replace <ref> with your actual project reference ID)
--
-- 5. Review git history for any leaked secrets:
--    git log --all -S 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9' --oneline
--    Consider using: https://docs.github.com/en/authentication/
--    keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
-- ============================================================
