-- ============================================================================
-- E-Ticketing Helpdesk — Status workflow revision (004)
-- Run in the Supabase SQL Editor AFTER 003_delete_ticket.sql.
--
-- Lecturer revision: the ticket lifecycle is now driven automatically by
-- workflow actions (no manual status editing), and the status set
-- changes from (open, in_progress, resolved, closed) to
-- (open, assigned, in_progress, closed):
--   open       → user creates the ticket
--   assigned   → admin accepts ("Terima") the ticket
--   in_progress→ admin assigns it to a helpdesk
--   closed     → helpdesk marks it done ("Selesai")
--
-- The legacy `resolved` status is removed. Any existing `resolved`
-- tickets were "done", so they migrate to `closed`.
-- ============================================================================

-- 1. Migrate existing rows off the removed status BEFORE swapping the
--    CHECK constraint (otherwise the new constraint would reject them).
UPDATE tickets SET status = 'closed' WHERE status = 'resolved';

-- Status-history rows may also reference 'resolved' in old/new columns.
UPDATE ticket_status_history SET old_status = 'closed' WHERE old_status = 'resolved';
UPDATE ticket_status_history SET new_status = 'closed' WHERE new_status = 'resolved';

-- 2. Swap the CHECK constraint to the new status set.
--    The inline constraint from 001 is auto-named `tickets_status_check`.
ALTER TABLE tickets DROP CONSTRAINT IF EXISTS tickets_status_check;
ALTER TABLE tickets
  ADD CONSTRAINT tickets_status_check
  CHECK (status IN ('open', 'assigned', 'in_progress', 'closed'));
