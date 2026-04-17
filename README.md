# E-Ticketing Helpdesk

Aplikasi mobile **E-Ticketing Helpdesk** berbasis Flutter + Supabase. Tugas Aplikasi Mobile Praktikum, D4 Teknik Informatika, Universitas Airlangga (SRS v1.0.0).

| | |
|---|---|
| Framework | Flutter 3.41.1 (stable) |
| Language | Dart 3.11.0 |
| Target | Android (Windows host) |
| Backend | Supabase (Auth + Postgres + Storage + Realtime) |
| Arsitektur | Clean Architecture (data / domain / presentation) |

---

## 1. Prasyarat (Windows)

- Flutter SDK **3.41.1** — verifikasi: `flutter --version`
- Android Studio / SDK (API level 34)
- Akun Supabase gratis — <https://app.supabase.com>
- Git

---

## 2. Setup Supabase

1. **Buat proyek baru** di <https://app.supabase.com> (region terdekat, mis. Singapore).
2. Buka **SQL Editor** → New query → tempelkan isi `supabase/migrations/001_initial_schema.sql` → **Run**.
3. Buka **Authentication → Users → Add user → Create new user**, buat 5 akun demo (password sama untuk semua: `Password123!`):
   - `admin@etik.test`
   - `helpdesk1@etik.test`
   - `helpdesk2@etik.test`
   - `user1@etik.test`
   - `user2@etik.test`

   Centang "Auto Confirm User" agar langsung bisa login.
4. Kembali ke **SQL Editor** → tempelkan `supabase/seed.sql` → **Run** (mempromosikan role + mengisi tiket demo).
5. Buka **Database → Replication** → aktifkan Realtime untuk tabel: `tickets`, `ticket_comments`, `ticket_status_history`, `notifications`.
6. Buka **Storage → New bucket** → nama `ticket-attachments`, Public bucket ON. Policy default "Authenticated uploads, public read" sudah cukup.
7. Buka **Project Settings → API** → salin **Project URL** dan **anon public key**.

---

## 3. Konfigurasi lokal

```powershell
# Di folder proyek
Copy-Item .env.example .env
notepad .env
```

Isi `.env`:

```
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_ANON_KEY=YOUR-ANON-PUBLIC-KEY
```

---

## 4. Install & run

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

> Pertama kali menjalankan `build_runner` memang agak lama (code-gen freezed + riverpod).

---

## 5. Kredensial demo

Setelah seed dijalankan:

| Email | Password | Role |
|---|---|---|
| `admin@etik.test` | `Password123!` | admin |
| `helpdesk1@etik.test` | `Password123!` | helpdesk |
| `helpdesk2@etik.test` | `Password123!` | helpdesk |
| `user1@etik.test` | `Password123!` | user |
| `user2@etik.test` | `Password123!` | user |

---

## 6. Struktur folder

```
lib/
├── main.dart, app.dart
├── core/          # config, theme, router, errors, network, utils, widgets
├── shared/        # providers lintas-fitur (theme)
└── features/
    ├── auth/        (data · domain · presentation)
    ├── ticket/      (data · domain · presentation)
    ├── dashboard/
    ├── notification/
    └── profile/
supabase/
├── migrations/001_initial_schema.sql
└── seed.sql
```

Setiap fitur mengikuti pola **Clean Architecture 3-layer**:
- `data/` — models (freezed), datasources, repository impl
- `domain/` — entities, repository abstraction, use cases (1 class = 1 method)
- `presentation/` — Riverpod providers, screens, widgets

---

## 7. Fase pengembangan

| Fase | Output |
|---|---|
| 0 | Bootstrap (folder, deps, schema, seed) — **✅ current** |
| 1 | Core infrastructure (theme, router, reusable widgets) |
| 2 | Auth (FR-001..004) |
| 3 | Ticket CRUD + komentar + attachment (FR-005, FR-006) |
| 4 | Dashboard + chart (FR-008) |
| 5 | Notifikasi realtime + local notification (FR-007) |
| 6 | History + tracking timeline (FR-010, FR-011) |
| 7 | Profile + theme toggle |
| 8 | Polish (offline, skeleton, analyze bersih) |

---

## 8. Troubleshooting

- **`flutter pub get` gagal karena konflik versi** — lihat `C:/Users/.../.claude/plans/whimsical-discovering-umbrella.md` bagian "Risks / Watch Items". Jangan turunkan batas SDK Flutter/Dart; naikkan versi package yang konflik.
- **`build_runner` error stale** — jalankan ulang dengan `--delete-conflicting-outputs`.
- **Realtime tidak masuk** — pastikan tabel sudah diaktifkan di Database → Replication.
