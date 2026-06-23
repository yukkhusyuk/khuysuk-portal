-- =====================================================================
--  YUK KHUSYUK — Skema Supabase
--  Cara pakai: buka Supabase > SQL Editor > New query > tempel semua ini
--  > klik RUN. Aman dijalankan ulang (pakai IF NOT EXISTS / OR REPLACE).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) TABEL MEMBER (gerbang akses Portal Pustaka)
--    Login portal pakai Google / magic-link Supabase Auth.
--    Member dianggap aktif kalau email-nya ada di sini & active = true.
-- ---------------------------------------------------------------------
create table if not exists public.members (
  email      text primary key,
  active     boolean not null default true,
  note       text,
  created_at timestamptz not null default now()
);

alter table public.members enable row level security;

-- User yang sudah login HANYA boleh melihat baris membership miliknya sendiri.
-- (admin tetap bisa lihat semua lewat dashboard / service key)
drop policy if exists members_select_own on public.members;
create policy members_select_own on public.members
  for select to authenticated
  using ( lower(email) = lower(auth.jwt() ->> 'email') );


-- ---------------------------------------------------------------------
-- 2) TABEL PROGRES KHUSYUK LEARN
--    Khusyuk Learn sekarang WAJIB login (email + password Supabase Auth).
--    Progres disimpan per-user (user_id) dengan RLS ketat: tiap user
--    hanya bisa baca/tulis barisnya sendiri.
--
--    CATATAN UPGRADE: kalau sebelumnya kamu sudah pakai versi lama yang
--    key-nya "email", jalankan dulu baris DROP di bawah ini (akan
--    menghapus progres soft-login lama, karena tidak punya user_id):
--      drop table if exists public.khusyuk_progress;
-- ---------------------------------------------------------------------
create table if not exists public.khusyuk_progress (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  email       text,
  name        text,
  category    text,
  cat_name    text,
  xp          int     not null default 0,
  streak      int     not null default 1,
  gem         int     not null default 5,
  hearts      int     not null default 5,
  done_units  jsonb   not null default '[]'::jsonb,
  updated_at  timestamptz not null default now()
);

alter table public.khusyuk_progress enable row level security;

-- Tiap user hanya boleh akses baris miliknya sendiri.
drop policy if exists khusyuk_progress_rw on public.khusyuk_progress;
drop policy if exists khusyuk_progress_own on public.khusyuk_progress;
create policy khusyuk_progress_own on public.khusyuk_progress
  for all to authenticated
  using ( auth.uid() = user_id )
  with check ( auth.uid() = user_id );


-- ---------------------------------------------------------------------
-- 3) (OPSIONAL) Aktifkan member manual setelah pembayaran:
--    ganti email lalu jalankan.
-- ---------------------------------------------------------------------
-- insert into public.members (email, active, note)
-- values ('pembeli@gmail.com', true, 'beli upsell 12 Jan')
-- on conflict (email) do update set active = excluded.active, note = excluded.note;
