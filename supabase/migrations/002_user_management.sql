-- ============================================================================
-- E-Ticketing Helpdesk — User Management (002)
-- Run this in the Supabase SQL Editor AFTER 001_initial_schema.sql.
--
-- Adds admin user-management capability (FR-007.7 + BR-002.9):
--   • `is_active` flag on profiles (deactivate / reactivate accounts)
--   • A trigger that lets ONLY admins change `role` / `is_active`,
--     closing a privilege-escalation hole in the original
--     `profiles_self_update` policy (which otherwise lets any user
--     update their own `role` to 'admin').
--   • RLS so admins can update ANY profile.
--   • A server-side backstop so deactivated accounts cannot insert
--     tickets even via direct API calls.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. is_active column
-- ----------------------------------------------------------------------------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- ----------------------------------------------------------------------------
-- 2. Privilege guard (SECURITY FIX)
--    RLS WITH CHECK can only see the NEW row, never the OLD one, so a
--    policy alone cannot say "the role column must not change". A
--    BEFORE UPDATE trigger can compare OLD vs NEW: if a non-admin tries
--    to change `role` or `is_active`, reject the update. This makes the
--    existing `profiles_self_update` policy safe — users may still edit
--    their own name / username / avatar, but never escalate privileges
--    or reactivate themselves.
--
--    SECURITY INVOKER (the default): the trigger only compares values
--    and calls current_user_role() (itself SECURITY DEFINER, returning
--    the caller's own role) — it needs no elevated rights of its own.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION guard_profile_privileged_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF (NEW.role IS DISTINCT FROM OLD.role
      OR NEW.is_active IS DISTINCT FROM OLD.is_active)
     AND current_user_role() <> 'admin' THEN
    RAISE EXCEPTION 'Hanya admin yang dapat mengubah peran atau status akun.'
      USING ERRCODE = '42501'; -- insufficient_privilege
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_guard_privileged ON profiles;
CREATE TRIGGER trg_profiles_guard_privileged
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION guard_profile_privileged_columns();

-- ----------------------------------------------------------------------------
-- 3. Admin can update any profile.
--    The existing `profiles_self_update` policy stays (users edit their
--    own row); this additive policy lets admins update OTHER users'
--    rows. Both USING and WITH CHECK are present (WITH CHECK is required
--    on UPDATE so the post-image is re-validated). The SELECT side is
--    already covered by `profiles_read` (FOR SELECT USING true) from
--    migration 001 — without a SELECT policy an UPDATE silently affects
--    0 rows.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_admin_update ON profiles;
CREATE POLICY profiles_admin_update ON profiles
  FOR UPDATE TO authenticated
  USING (current_user_role() = 'admin')
  WITH CHECK (current_user_role() = 'admin');

-- ----------------------------------------------------------------------------
-- 4. Backstop: a deactivated user cannot create tickets.
--    They may still hold a live session until their JWT expires (Supabase
--    does not revoke tokens on a profile change), and the app blocks them
--    at login — but this WITH CHECK stops ticket inserts via direct API
--    calls regardless.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS tickets_insert ON tickets;
CREATE POLICY tickets_insert ON tickets
  FOR INSERT TO authenticated
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM profiles p
       WHERE p.id = (SELECT auth.uid()) AND p.is_active = TRUE
    )
  );
