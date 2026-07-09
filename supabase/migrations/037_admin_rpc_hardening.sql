-- MIGRATION 037: Centralize sensitive admin mutations behind checked RPCs.

CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS boolean
LANGUAGE sql
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

CREATE OR REPLACE FUNCTION public.admin_set_user_admin(target_user_id uuid, make_admin boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  IF target_user_id = auth.uid() AND make_admin = false THEN
    RAISE EXCEPTION 'Cannot remove own admin status';
  END IF;

  UPDATE public.profiles
  SET is_admin = make_admin, updated_at = now()
  WHERE id = target_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_set_user_vibes(target_user_id uuid, can_use_vibes_value boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  UPDATE public.profiles
  SET can_use_vibes = can_use_vibes_value, updated_at = now()
  WHERE id = target_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_update_report_status(target_report_id uuid, new_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  IF new_status NOT IN ('pending', 'reviewed', 'resolved', 'dismissed') THEN
    RAISE EXCEPTION 'Invalid report status';
  END IF;

  UPDATE public.reports
  SET status = new_status
  WHERE id = target_report_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_post(target_post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF NOT public.current_user_is_admin() THEN
    RAISE EXCEPTION 'Access denied: admin only';
  END IF;

  DELETE FROM public.posts
  WHERE id = target_post_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.current_user_is_admin() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_set_user_admin(uuid, boolean) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_set_user_vibes(uuid, boolean) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_update_report_status(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_delete_post(uuid) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.current_user_is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_user_admin(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_user_vibes(uuid, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_report_status(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_post(uuid) TO authenticated;
