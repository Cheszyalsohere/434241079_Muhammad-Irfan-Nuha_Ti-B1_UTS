-- ============================================================================
-- E-Ticketing Helpdesk — Delete Ticket (003)
-- Run in the Supabase SQL Editor AFTER 002_user_management.sql.
--
-- Adds ticket deletion (BR-002.8). A ticket may be deleted by its
-- creator (owner) or an admin — not by helpdesk staff, who close
-- tickets rather than remove them.
--
-- Child rows cascade automatically: ticket_comments,
-- ticket_status_history, and notifications all declare
-- `REFERENCES tickets(id) ON DELETE CASCADE` in 001, and cascade deletes
-- run with system privileges, so no extra child-table DELETE policies
-- are needed.
-- ============================================================================

DROP POLICY IF EXISTS tickets_delete ON tickets;
CREATE POLICY tickets_delete ON tickets
  FOR DELETE TO authenticated
  USING (
    created_by = (SELECT auth.uid())
    OR current_user_role() = 'admin'
  );
