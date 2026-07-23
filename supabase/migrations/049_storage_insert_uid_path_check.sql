-- MIGRATION 049: Storage INSERT policies must enforce path prefix == auth.uid()
-- This closes the gap where any authenticated user could write to any path
-- under the post-media/avatars buckets (overwriting other users' files).
-- The current `auth.role() = 'authenticated'` check is insufficient.
-- We require that the first path segment of the file name equals the
-- caller's auth.uid()::text.

-- ============================================
-- #1: Tighten post-media bucket INSERT
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can upload media" ON storage.objects;
CREATE POLICY "Users can upload only to their own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'post-media'
    AND auth.role() = 'authenticated'
    -- First path segment of `name` (which is the full path) must equal auth.uid()
    AND (storage.filename(name))[1] = auth.uid()::text
  );

-- ============================================
-- #2: Tighten avatars bucket INSERT
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
CREATE POLICY "Users can upload only to their own avatar folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.filename(name))[1] = auth.uid()::text
  );
