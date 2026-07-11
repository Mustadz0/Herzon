-- MIGRATION 039a: Parts A-I, K-L of security hardening (without Part J)

-- ─────────────────────────────────────────────────────────────
-- PART A: REVOKE anon/authenticated from sensitive functions
-- ─────────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) FROM authenticated;
GRANT  EXECUTE ON FUNCTION public.award_xp(uuid, integer, text, uuid) TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_user()                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()                    FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_expired_stories()             FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_engagement_metrics()             FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_engagement_metrics()             FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_posts_last_7_days()              FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_posts_last_7_days()              FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_top_zones()                      FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_top_zones()                      FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_user_growth()                    FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_growth()                    FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.trigger_send_push_notification()     FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_reaction_counts()             FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_comment_notification()        FROM anon;
REVOKE EXECUTE ON FUNCTION public.award_badges_on_milestone()          FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_comment_xp()                  FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_post_xp()                     FROM anon;
REVOKE EXECUTE ON FUNCTION public.handle_reaction_xp()                 FROM anon;
REVOKE EXECUTE ON FUNCTION public.prevent_vote_own_post()              FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()                    FROM authenticated;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'book_ride'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.book_ride(uuid, integer) FROM anon';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'handle_follow_notification'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.handle_follow_notification() FROM anon';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'handle_reaction_notification'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.handle_reaction_notification() FROM anon';
  END IF;
END $$;

REVOKE EXECUTE ON FUNCTION public.admin_delete_post(uuid)               FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_set_user_admin(uuid, boolean)   FROM authenticated;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'admin_set_user_vibes'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.admin_set_user_vibes(uuid, boolean) FROM authenticated';
    EXECUTE 'GRANT  EXECUTE ON FUNCTION public.admin_set_user_vibes(uuid, boolean) TO service_role';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'admin_update_report_status'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.admin_update_report_status(uuid, text) FROM authenticated';
    EXECUTE 'GRANT  EXECUTE ON FUNCTION public.admin_update_report_status(uuid, text) TO service_role';
  END IF;
END $$;

GRANT EXECUTE ON FUNCTION public.book_ride(uuid, integer)              TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_expired_stories()              TO service_role;
GRANT EXECUTE ON FUNCTION public.award_badges_on_milestone()           TO service_role;
GRANT EXECUTE ON FUNCTION public.rls_auto_enable()                     TO service_role;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'st_estimatedextent'
  ) THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text) FROM anon';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.st_estimatedextent(text, text) FROM PUBLIC';
  END IF;
END $$;


-- ─────────────────────────────────────────────────────────────
-- PART B: Fix mutable search_path on vulnerable functions
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.prevent_vote_own_post()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.user_id = (SELECT user_id FROM public.posts WHERE id = NEW.post_id) THEN
    RAISE EXCEPTION 'Cannot vote on your own post';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_poll_vote_counts()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.poll_options SET vote_count = vote_count + 1      WHERE id = NEW.option_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.poll_options SET vote_count = GREATEST(vote_count - 1, 0) WHERE id = OLD.option_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user_interests(
  p_user_id uuid, p_interests text[]
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  DELETE FROM public.user_interests WHERE user_id = p_user_id;
  INSERT INTO public.user_interests (user_id, interest)
  SELECT p_user_id, unnest(p_interests);
END;
$$;

CREATE OR REPLACE FUNCTION public.award_badges_on_milestone()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_post_count integer;
BEGIN
  SELECT COUNT(*) INTO v_post_count FROM public.posts
  WHERE user_id = NEW.user_id AND deleted_at IS NULL;
  IF v_post_count >= 1 THEN
    INSERT INTO public.user_badges (user_id, badge_id)
    SELECT NEW.user_id, id FROM public.badges WHERE slug = 'first_post'
    ON CONFLICT DO NOTHING;
  END IF;
  IF v_post_count >= 10 THEN
    INSERT INTO public.user_badges (user_id, badge_id)
    SELECT NEW.user_id, id FROM public.badges WHERE slug = 'active_poster'
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_post_xp()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN PERFORM public.award_xp(NEW.user_id, 10, 'post_created', NEW.id); END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_reaction_xp()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN PERFORM public.award_xp(NEW.user_id, 2, 'reaction_given', NEW.id); END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_comment_xp()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN PERFORM public.award_xp(NEW.user_id, 5, 'comment_created', NEW.id); END IF;
  RETURN NEW;
END;
$$;


-- ─────────────────────────────────────────────────────────────
-- PART C: Re-create push trigger without hardcoded secrets
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.trigger_send_push_notification()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_edge_url        text;
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

  v_edge_url := 'https://xhjglurrmnmpqzbvctgn.supabase.co/functions/v1/send-push';

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

DROP TRIGGER IF EXISTS on_notification_insert ON public.notifications;
CREATE TRIGGER on_notification_insert
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.trigger_send_push_notification();

GRANT EXECUTE ON FUNCTION public.trigger_send_push_notification() TO supabase_admin, service_role;


-- ─────────────────────────────────────────────────────────────
-- PART D: Fix get_blocked_user_ids (HIGH-3)
-- ─────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.get_blocked_user_ids(uuid);

CREATE OR REPLACE FUNCTION public.get_blocked_user_ids()
RETURNS SETOF uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = 'public' AS $$
  SELECT blocked_id  FROM blocked_users WHERE blocker_id = auth.uid()
  UNION
  SELECT blocker_id  FROM blocked_users WHERE blocked_id  = auth.uid();
$$;

COMMENT ON FUNCTION public.get_blocked_user_ids() IS
  'Returns all user IDs blocked by/blocking the current user. Always uses auth.uid().';

REVOKE ALL   ON FUNCTION public.get_blocked_user_ids() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_blocked_user_ids() TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- PART E: Fix mark_messages_read (HIGH-4)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.mark_messages_read(p_conversation_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE v_uid UUID := auth.uid();
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM conversations
    WHERE id = p_conversation_id AND (user1_id = v_uid OR user2_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'Not authorized: you are not a participant in this conversation';
  END IF;
  UPDATE messages
  SET is_read = true, read_at = now()
  WHERE conversation_id = p_conversation_id
    AND sender_id != v_uid AND is_read = false;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_messages_read(UUID) TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- PART F: Fix conversations INSERT RLS (MED-8)
-- ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT WITH CHECK (
    (auth.uid() = user1_id OR auth.uid() = user2_id)
    AND user1_id != user2_id
  );


-- ─────────────────────────────────────────────────────────────
-- PART G: send_message rate limiting + SSRF fix (MED-9, MED-10)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.send_message(
  p_conversation_id UUID,
  p_content         TEXT,
  p_message_type    TEXT  DEFAULT 'text',
  p_media_url       TEXT  DEFAULT NULL,
  p_sticker_id      TEXT  DEFAULT NULL
)
RETURNS messages LANGUAGE plpgsql SECURITY INVOKER SET search_path = public AS $$
DECLARE
  v_new_message  messages;
  v_uid          UUID := auth.uid();
  v_recent_count INT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM conversations
    WHERE id = p_conversation_id AND (user1_id = v_uid OR user2_id = v_uid)
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT COUNT(*) INTO v_recent_count
  FROM messages WHERE sender_id = v_uid AND created_at > now() - INTERVAL '60 seconds';
  IF v_recent_count >= 30 THEN
    RAISE EXCEPTION 'Rate limit exceeded: max 30 messages per minute';
  END IF;

  IF p_media_url IS NOT NULL THEN
    IF NOT (p_media_url ~ '^https://[a-z0-9]+\.supabase\.co/storage/v1/object/(public|authenticated)/') THEN
      RAISE EXCEPTION 'Invalid media_url: only Supabase Storage URLs are allowed';
    END IF;
  END IF;

  INSERT INTO messages (conversation_id, sender_id, content, message_type, media_url, sticker_id)
  VALUES (p_conversation_id, v_uid, p_content, p_message_type, p_media_url, p_sticker_id)
  RETURNING * INTO v_new_message;

  UPDATE conversations SET last_message_at = now(), updated_at = now()
  WHERE id = p_conversation_id;

  RETURN v_new_message;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_message(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- PART H: Admin Audit Log + Soft Delete (HIGH-5, HIGH-6)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    uuid        NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
  action      text        NOT NULL,
  target_type text        NOT NULL,
  target_id   uuid        NOT NULL,
  metadata    jsonb       DEFAULT '{}',
  created_at  timestamptz DEFAULT now()
);

COMMENT ON TABLE public.admin_audit_log IS 'Immutable audit trail for all admin actions. INSERT-only.';
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read audit log"     ON public.admin_audit_log;
DROP POLICY IF EXISTS "Service role inserts audit log" ON public.admin_audit_log;
DROP POLICY IF EXISTS "No update on audit log"         ON public.admin_audit_log;
DROP POLICY IF EXISTS "No delete on audit log"         ON public.admin_audit_log;

CREATE POLICY "Admins can read audit log"      ON public.admin_audit_log FOR SELECT USING (public.current_user_is_admin());
CREATE POLICY "Service role inserts audit log" ON public.admin_audit_log FOR INSERT WITH CHECK (public.current_user_is_admin());
CREATE POLICY "No update on audit log"         ON public.admin_audit_log FOR UPDATE USING (false);
CREATE POLICY "No delete on audit log"         ON public.admin_audit_log FOR DELETE USING (false);

CREATE INDEX IF NOT EXISTS idx_admin_audit_admin_id   ON public.admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target      ON public.admin_audit_log(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created_at  ON public.admin_audit_log(created_at DESC);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns WHERE table_name = 'posts' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE posts ADD COLUMN deleted_at timestamptz DEFAULT NULL;
    ALTER TABLE posts ADD COLUMN deleted_by uuid REFERENCES profiles(id) ON DELETE SET NULL;
    COMMENT ON COLUMN posts.deleted_at IS 'Set by admin soft-delete. NULL = not deleted.';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_posts_deleted_at ON posts(deleted_at) WHERE deleted_at IS NOT NULL;

CREATE OR REPLACE FUNCTION public.admin_delete_post(target_post_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid UUID := auth.uid(); v_post_snap jsonb;
BEGIN
  IF NOT public.current_user_is_admin() THEN RAISE EXCEPTION 'Permission denied: admin only'; END IF;
  SELECT to_jsonb(p) INTO v_post_snap FROM posts p WHERE p.id = target_post_id;
  IF v_post_snap IS NULL THEN RAISE EXCEPTION 'Post not found: %', target_post_id; END IF;
  UPDATE posts SET deleted_at = now(), deleted_by = v_uid WHERE id = target_post_id;
  INSERT INTO public.admin_audit_log (admin_id, action, target_type, target_id, metadata)
  VALUES (v_uid, 'delete_post', 'post', target_post_id, v_post_snap);
END;
$$;

REVOKE ALL   ON FUNCTION public.admin_delete_post(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_post(UUID) TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- PART I: Unify is_admin check (HIGH-6)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = 'public' AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true);
$$;

REVOKE ALL   ON FUNCTION public.current_user_is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_user_is_admin() TO authenticated, service_role;


-- ─────────────────────────────────────────────────────────────
-- PART K: RLS on posts -- hide soft-deleted rows
-- ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view published posts" ON posts;
CREATE POLICY "Users can view published posts"
  ON posts FOR SELECT USING (
    deleted_at IS NULL AND (
      user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM follows f
        WHERE f.follower_id = auth.uid() AND f.following_id = posts.user_id
      )
    )
  );

DROP POLICY IF EXISTS "Admins can view all posts" ON posts;
CREATE POLICY "Admins can view all posts"
  ON posts FOR SELECT USING (public.current_user_is_admin());


-- PART L SKIPPED: spatial_ref_sys owned by superuser, cannot enable RLS
