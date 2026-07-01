-- Fix reports foreign keys: point to public.profiles instead of auth.users
-- so PostgREST can resolve embedded queries for display_name.

ALTER TABLE public.reports
  DROP CONSTRAINT IF EXISTS reports_reporter_id_fkey,
  DROP CONSTRAINT IF EXISTS reports_reported_user_id_fkey;

ALTER TABLE public.reports
  ADD CONSTRAINT fk_reports_reporter_id
    FOREIGN KEY (reporter_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD CONSTRAINT fk_reports_reported_user_id
    FOREIGN KEY (reported_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
