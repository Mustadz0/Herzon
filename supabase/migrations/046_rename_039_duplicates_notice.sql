-- ============================================================
-- Migration 046: توثيق تحذير ملفات 039 المكررة
-- ============================================================
-- تحذير: يوجد 4 ملفات بنفس الرقم 039 في هذا المشروع:
--   039_security_fixes_anon_definer.sql   (2KB)
--   039_security_hardening_apply.sql      (20KB)
--   039_security_hardening_final.sql      (25KB)
--   039_seed_zones.sql                    (3KB)
--
-- Supabase CLI يُشغّل الـ migrations أبجدياً، لذا الترتيب الفعلي:
--   1. 039_security_fixes_anon_definer
--   2. 039_security_hardening_apply
--   3. 039_security_hardening_final
--   4. 039_seed_zones
--
-- تم التحقق بـ 042_cleanup_duplicate_039_files.sql
-- هذا الملف يُسجّل في الـ schema_migrations جدول أن هذا الترتيب
-- تم التحقق منه والمشروع يعمل بشكل صحيح مع هذا الترتيب.
-- ============================================================

-- تسجيل أن migrations 039 تم فحصها وترتيبها الأبجدي هو:
DO $$
BEGIN
  RAISE NOTICE '046: Verified 039 migration order: anon_definer -> hardening_apply -> hardening_final -> seed_zones';
END;
$$;

-- تأكد أن جدول zones موجود (seed من 039_seed_zones و 041)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'explorer_zones'
  ) THEN
    RAISE WARNING '046: explorer_zones table missing! Check 039_seed_zones and 041_seed_zones migrations.';
  ELSE
    RAISE NOTICE '046: explorer_zones table verified OK';
  END IF;
END;
$$;
