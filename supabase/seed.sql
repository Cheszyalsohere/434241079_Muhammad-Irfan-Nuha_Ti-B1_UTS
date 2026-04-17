-- ============================================================================
-- E-Ticketing Helpdesk — Seed data (demo only)
-- Run AFTER 001_initial_schema.sql AND after creating the auth users below
-- via the Supabase Dashboard → Authentication → Users → Add user (invite).
--
-- Demo users to create (password for all: "Password123!"):
--   admin@etik.test       → will be promoted to admin below
--   helpdesk1@etik.test   → promoted to helpdesk
--   helpdesk2@etik.test   → promoted to helpdesk
--   user1@etik.test       → remains user
--   user2@etik.test       → remains user
--
-- The `handle_new_auth_user` trigger auto-creates the profiles row with
-- role='user'. This script only patches the roles and inserts demo tickets.
-- ============================================================================

-- Promote roles (safe no-op if a user is missing)
UPDATE profiles SET role = 'admin',    full_name = 'Admin Helpdesk'
 WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@etik.test');

UPDATE profiles SET role = 'helpdesk', full_name = 'Helpdesk Satu'
 WHERE id = (SELECT id FROM auth.users WHERE email = 'helpdesk1@etik.test');

UPDATE profiles SET role = 'helpdesk', full_name = 'Helpdesk Dua'
 WHERE id = (SELECT id FROM auth.users WHERE email = 'helpdesk2@etik.test');

UPDATE profiles SET full_name = 'Pengguna Satu'
 WHERE id = (SELECT id FROM auth.users WHERE email = 'user1@etik.test');

UPDATE profiles SET full_name = 'Pengguna Dua'
 WHERE id = (SELECT id FROM auth.users WHERE email = 'user2@etik.test');

-- Demo tickets
INSERT INTO tickets (title, description, category, priority, status, created_by, assigned_to)
SELECT * FROM (VALUES
  ('Laptop tidak bisa menyala',              'Kemarin masih normal, pagi ini mati total.',            'hardware', 'high',   'open',
   (SELECT id FROM auth.users WHERE email = 'user1@etik.test'), NULL),
  ('Printer ruang admin macet',              'Kertas selalu nyangkut di printer ruang TU.',            'hardware', 'medium', 'in_progress',
   (SELECT id FROM auth.users WHERE email = 'user1@etik.test'),
   (SELECT id FROM auth.users WHERE email = 'helpdesk1@etik.test')),
  ('Tidak bisa akses Wi-Fi kampus',          'SSID muncul tapi selalu gagal autentikasi.',             'network',  'high',   'open',
   (SELECT id FROM auth.users WHERE email = 'user2@etik.test'), NULL),
  ('Reset password akun email',              'Lupa password email kampus.',                            'account',  'low',    'resolved',
   (SELECT id FROM auth.users WHERE email = 'user2@etik.test'),
   (SELECT id FROM auth.users WHERE email = 'helpdesk2@etik.test')),
  ('Aplikasi SIAM error saat login',         'Muncul 500 Internal Server Error setelah login.',        'software', 'urgent', 'open',
   (SELECT id FROM auth.users WHERE email = 'user1@etik.test'), NULL),
  ('Monitor flicker',                        'Layar berkedip setiap 10 detik.',                        'hardware', 'medium', 'in_progress',
   (SELECT id FROM auth.users WHERE email = 'user2@etik.test'),
   (SELECT id FROM auth.users WHERE email = 'helpdesk1@etik.test')),
  ('VPN tidak terhubung',                    'Client VPN stuck di "Connecting".',                      'network',  'high',   'open',
   (SELECT id FROM auth.users WHERE email = 'user1@etik.test'), NULL),
  ('Permintaan instalasi MS Office',         'Butuh MS Office untuk laptop baru.',                     'software', 'low',    'closed',
   (SELECT id FROM auth.users WHERE email = 'user2@etik.test'),
   (SELECT id FROM auth.users WHERE email = 'helpdesk2@etik.test')),
  ('Mouse tidak terdeteksi',                 'Mouse USB tidak dikenali di port manapun.',              'hardware', 'low',    'resolved',
   (SELECT id FROM auth.users WHERE email = 'user1@etik.test'),
   (SELECT id FROM auth.users WHERE email = 'helpdesk1@etik.test')),
  ('Akun SIAKAD terkunci',                   'Salah password 3x, akun terkunci.',                      'account',  'medium', 'closed',
   (SELECT id FROM auth.users WHERE email = 'user2@etik.test'),
   (SELECT id FROM auth.users WHERE email = 'helpdesk2@etik.test'))
) AS t(title, description, category, priority, status, created_by, assigned_to)
WHERE created_by IS NOT NULL;

-- Sample comments on the first two tickets
INSERT INTO ticket_comments (ticket_id, user_id, message)
SELECT tk.id,
       (SELECT id FROM auth.users WHERE email = 'helpdesk1@etik.test'),
       'Halo, sudah kami terima tiketnya. Mohon ditunggu, akan segera dicek.'
  FROM tickets tk
 WHERE tk.title = 'Printer ruang admin macet'
 LIMIT 1;

INSERT INTO ticket_comments (ticket_id, user_id, message)
SELECT tk.id,
       (SELECT id FROM auth.users WHERE email = 'user1@etik.test'),
       'Baik, terima kasih.'
  FROM tickets tk
 WHERE tk.title = 'Printer ruang admin macet'
 LIMIT 1;
