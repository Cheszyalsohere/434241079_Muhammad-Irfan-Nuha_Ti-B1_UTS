-- ============================================================================
-- E-Ticketing Helpdesk — Initial schema (001)
-- Run this in the Supabase SQL Editor of a fresh project, then seed.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tables
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username   TEXT UNIQUE NOT NULL,
  full_name  TEXT NOT NULL,
  role       TEXT NOT NULL CHECK (role IN ('user', 'helpdesk', 'admin')) DEFAULT 'user',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tickets (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number  TEXT UNIQUE NOT NULL,
  title          TEXT NOT NULL,
  description    TEXT NOT NULL,
  category       TEXT NOT NULL CHECK (category IN ('hardware', 'software', 'network', 'account', 'other')),
  priority       TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
  status         TEXT NOT NULL CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')) DEFAULT 'open',
  attachment_url TEXT,
  created_by     UUID NOT NULL REFERENCES profiles(id),
  assigned_to    UUID REFERENCES profiles(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS tickets_created_by_idx   ON tickets(created_by);
CREATE INDEX IF NOT EXISTS tickets_assigned_to_idx  ON tickets(assigned_to);
CREATE INDEX IF NOT EXISTS tickets_status_idx       ON tickets(status);
CREATE INDEX IF NOT EXISTS tickets_updated_at_idx   ON tickets(updated_at DESC);

CREATE TABLE IF NOT EXISTS ticket_comments (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id      UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES profiles(id),
  message        TEXT NOT NULL,
  attachment_url TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ticket_comments_ticket_id_idx ON ticket_comments(ticket_id);

CREATE TABLE IF NOT EXISTS ticket_status_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id   UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  old_status  TEXT,
  new_status  TEXT NOT NULL,
  changed_by  UUID REFERENCES profiles(id),
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ticket_status_history_ticket_id_idx
  ON ticket_status_history(ticket_id, created_at);

CREATE TABLE IF NOT EXISTS notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  ticket_id  UUID REFERENCES tickets(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx
  ON notifications(user_id, is_read, created_at DESC);

-- ----------------------------------------------------------------------------
-- Helper: role lookup for current user
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION current_user_role()
RETURNS TEXT
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$;

-- ----------------------------------------------------------------------------
-- Triggers
-- ----------------------------------------------------------------------------

-- Auto-generate ticket_number: TKT-YYYYMMDD-XXXX (4-digit daily sequence)
CREATE OR REPLACE FUNCTION gen_ticket_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  today_prefix TEXT;
  next_seq     INT;
BEGIN
  IF NEW.ticket_number IS NOT NULL AND NEW.ticket_number <> '' THEN
    RETURN NEW;
  END IF;

  today_prefix := 'TKT-' || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYYMMDD') || '-';

  SELECT COALESCE(MAX(SUBSTRING(ticket_number FROM LENGTH(today_prefix) + 1)::INT), 0) + 1
    INTO next_seq
    FROM tickets
   WHERE ticket_number LIKE today_prefix || '%';

  NEW.ticket_number := today_prefix || LPAD(next_seq::TEXT, 4, '0');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tickets_gen_number ON tickets;
CREATE TRIGGER trg_tickets_gen_number
  BEFORE INSERT ON tickets
  FOR EACH ROW EXECUTE FUNCTION gen_ticket_number();

-- Keep updated_at fresh on any row change
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tickets_touch_updated_at ON tickets;
CREATE TRIGGER trg_tickets_touch_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Record status changes in ticket_status_history + notify the ticket owner
CREATE OR REPLACE FUNCTION log_ticket_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_by, notes)
    VALUES (NEW.id, NULL, NEW.status, NEW.created_by, 'Ticket created');
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_by, notes)
    VALUES (NEW.id, OLD.status, NEW.status, auth.uid(), NULL);

    -- Notify the ticket creator (and assignee if different)
    INSERT INTO notifications (user_id, ticket_id, title, body)
    VALUES (
      NEW.created_by,
      NEW.id,
      'Status tiket diperbarui',
      'Tiket ' || NEW.ticket_number || ' sekarang berstatus ' || NEW.status
    );

    IF NEW.assigned_to IS NOT NULL AND NEW.assigned_to <> NEW.created_by THEN
      INSERT INTO notifications (user_id, ticket_id, title, body)
      VALUES (
        NEW.assigned_to,
        NEW.id,
        'Status tiket diperbarui',
        'Tiket ' || NEW.ticket_number || ' sekarang berstatus ' || NEW.status
      );
    END IF;
  END IF;

  -- Notify on assignment
  IF TG_OP = 'UPDATE'
     AND NEW.assigned_to IS DISTINCT FROM OLD.assigned_to
     AND NEW.assigned_to IS NOT NULL THEN
    INSERT INTO notifications (user_id, ticket_id, title, body)
    VALUES (
      NEW.assigned_to,
      NEW.id,
      'Tiket baru ditugaskan kepada Anda',
      'Tiket ' || NEW.ticket_number || ': ' || NEW.title
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tickets_log_status_insert ON tickets;
CREATE TRIGGER trg_tickets_log_status_insert
  AFTER INSERT ON tickets
  FOR EACH ROW EXECUTE FUNCTION log_ticket_status_change();

DROP TRIGGER IF EXISTS trg_tickets_log_status_update ON tickets;
CREATE TRIGGER trg_tickets_log_status_update
  AFTER UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION log_ticket_status_change();

-- Notify ticket owner + assignee when a comment is added (skip self-notif)
CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  t_creator  UUID;
  t_assigned UUID;
  t_number   TEXT;
BEGIN
  SELECT created_by, assigned_to, ticket_number
    INTO t_creator, t_assigned, t_number
    FROM tickets WHERE id = NEW.ticket_id;

  IF t_creator IS NOT NULL AND t_creator <> NEW.user_id THEN
    INSERT INTO notifications (user_id, ticket_id, title, body)
    VALUES (t_creator, NEW.ticket_id, 'Balasan baru pada tiket',
            'Ada balasan baru pada tiket ' || t_number);
  END IF;

  IF t_assigned IS NOT NULL AND t_assigned <> NEW.user_id AND t_assigned <> t_creator THEN
    INSERT INTO notifications (user_id, ticket_id, title, body)
    VALUES (t_assigned, NEW.ticket_id, 'Balasan baru pada tiket',
            'Ada balasan baru pada tiket ' || t_number);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_comments_notify ON ticket_comments;
CREATE TRIGGER trg_comments_notify
  AFTER INSERT ON ticket_comments
  FOR EACH ROW EXECUTE FUNCTION notify_on_comment();

-- Auto-create a profile row when a new auth user signs up
CREATE OR REPLACE FUNCTION handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO profiles (id, username, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    'user'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auth_new_user ON auth.users;
CREATE TRIGGER trg_auth_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_auth_user();

-- ----------------------------------------------------------------------------
-- Row Level Security
-- ----------------------------------------------------------------------------

ALTER TABLE profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets               ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_comments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications         ENABLE ROW LEVEL SECURITY;

-- profiles: any authenticated user can read; users can update their own row
DROP POLICY IF EXISTS profiles_read ON profiles;
CREATE POLICY profiles_read ON profiles
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS profiles_self_update ON profiles;
CREATE POLICY profiles_self_update ON profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- tickets: owners see their own, helpdesk/admin see all
DROP POLICY IF EXISTS tickets_select ON tickets;
CREATE POLICY tickets_select ON tickets
  FOR SELECT TO authenticated
  USING (
    created_by = auth.uid()
    OR assigned_to = auth.uid()
    OR current_user_role() IN ('helpdesk', 'admin')
  );

DROP POLICY IF EXISTS tickets_insert ON tickets;
CREATE POLICY tickets_insert ON tickets
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS tickets_update ON tickets;
CREATE POLICY tickets_update ON tickets
  FOR UPDATE TO authenticated
  USING (
    created_by = auth.uid()
    OR current_user_role() IN ('helpdesk', 'admin')
  )
  WITH CHECK (
    created_by = auth.uid()
    OR current_user_role() IN ('helpdesk', 'admin')
  );

-- comments: visible to ticket participants + helpdesk/admin
DROP POLICY IF EXISTS comments_select ON ticket_comments;
CREATE POLICY comments_select ON ticket_comments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
       WHERE t.id = ticket_comments.ticket_id
         AND (t.created_by = auth.uid()
              OR t.assigned_to = auth.uid()
              OR current_user_role() IN ('helpdesk', 'admin'))
    )
  );

DROP POLICY IF EXISTS comments_insert ON ticket_comments;
CREATE POLICY comments_insert ON ticket_comments
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM tickets t
       WHERE t.id = ticket_comments.ticket_id
         AND (t.created_by = auth.uid()
              OR t.assigned_to = auth.uid()
              OR current_user_role() IN ('helpdesk', 'admin'))
    )
  );

-- status history: readable by ticket participants + helpdesk/admin; inserted only by trigger
DROP POLICY IF EXISTS status_history_select ON ticket_status_history;
CREATE POLICY status_history_select ON ticket_status_history
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
       WHERE t.id = ticket_status_history.ticket_id
         AND (t.created_by = auth.uid()
              OR t.assigned_to = auth.uid()
              OR current_user_role() IN ('helpdesk', 'admin'))
    )
  );

-- notifications: owner read + update (mark as read) only
DROP POLICY IF EXISTS notifications_select ON notifications;
CREATE POLICY notifications_select ON notifications
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS notifications_update ON notifications;
CREATE POLICY notifications_update ON notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Realtime + Storage bucket notes
-- ----------------------------------------------------------------------------
-- Enable Realtime for these tables in the Supabase Dashboard:
--   Database → Replication → turn ON for: tickets, ticket_comments,
--   ticket_status_history, notifications.
--
-- Create a Storage bucket named `ticket-attachments` (public read,
-- authenticated write) via Dashboard → Storage → New Bucket.
-- Default policy template "Authenticated users can upload; anyone can read" is fine.
-- ----------------------------------------------------------------------------
