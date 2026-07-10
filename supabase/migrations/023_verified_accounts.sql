-- ============================================================
-- MIGRATION 023: Verified Accounts
-- Date: 2026-07-10
-- This migration was missing from the sequence (gap between 022 and 024).
-- Added as a placeholder to maintain contiguous migration numbering.
-- If you had a 023 migration that was deleted, restore its contents here.
-- ============================================================

-- Add verified badge support to profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'is_verified'
  ) THEN
    ALTER TABLE public.profiles
      ADD COLUMN is_verified boolean NOT NULL DEFAULT false,
      ADD COLUMN verified_at  timestamptz DEFAULT NULL;

    COMMENT ON COLUMN public.profiles.is_verified IS
      'True if the account has been manually verified by an admin.';
    COMMENT ON COLUMN public.profiles.verified_at IS
      'Timestamp when the account was verified.';
  END IF;
END $$;

-- Only admins and service_role can set is_verified = true
-- (enforced via RLS + the admin_set_user_admin function)
CREATE INDEX IF NOT EXISTS idx_profiles_verified ON public.profiles(is_verified)
  WHERE is_verified = true;
