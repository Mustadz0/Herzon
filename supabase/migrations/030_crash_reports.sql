-- MIGRATION 030: Crash Reports table for monitoring
-- Stores crash/error reports when Firebase Crashlytics is unavailable

CREATE TABLE IF NOT EXISTS crash_reports (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  level text NOT NULL DEFAULT 'error' CHECK (level IN ('fatal', 'error', 'warning', 'info')),
  message text NOT NULL,
  stack_trace text,
  platform text,
  app_version text,
  device_info jsonb,
  created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE crash_reports IS 'Client-side crash and error reports for monitoring.';

ALTER TABLE crash_reports ENABLE ROW LEVEL SECURITY;

-- Only service_role can insert (from server-side) or authenticated users for own crashes
CREATE POLICY "Authenticated users can insert crash reports"
  ON crash_reports FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() IS NOT NULL);

-- Only admins can read crash reports
CREATE POLICY "Admins can read crash reports"
  ON crash_reports FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

CREATE INDEX IF NOT EXISTS crash_reports_user_idx ON crash_reports(user_id);
CREATE INDEX IF NOT EXISTS crash_reports_level_idx ON crash_reports(level);
CREATE INDEX IF NOT EXISTS crash_reports_created_idx ON crash_reports(created_at DESC);
