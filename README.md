# Pustaka YukKhusyuk — Portal Member + Khusyuk Learn

Satu package siap deploy ke **GitHub → Vercel**, dengan **Supabase** buat login & simpan progres.

```
yukkhusyuk-portal/
├── index.html                 ← Portal Pustaka Member (login Google / magic-link)
├── config.js                  ← ISI 2 baris kunci Supabase DI SINI (sekali aja)
├── apps/
│   ├── khusyuk-learn.html      ← Game belajar sholat (WAJIB login email+password, progres ke Supabase)
│   └── kalkulator-cemas.html   ← Tools, jalan apa adanya
├── files/
│   └── menyelami-makna-sholat.pdf
├── supabase/
│   └── schema.sql             ← Jalankan di Supabase SQL Editor
├── .gitignore
└── README.md
```

Portal tetap jalan tanpa Supabase (mode demo). **Khusyuk Learn sekarang WAJIB Supabase** —
appnya berbayar, jadi user harus daftar/masuk pakai email + password sebelum bisa main.
Progres (XP/streak/level) disimpan per-user dan ikut lintas device.

---

## Langkah 1 — Supabase (database + auth)

1. Buka [supabase.com](https://supabase.com) → **New project**. Catat password DB.
2. Tunggu project siap, lalu **SQL Editor → New query** → tempel isi `supabase/schema.sql` → **Run**.
   (bikin tabel `members` + `khusyuk_progress` lengkap dengan RLS)
3. **Project Settings → API**, salin:
   - **Project URL** → harus bare, contoh `https://abcd.supabase.co` (TANPA `/rest/v1`)
   - **anon public** key
4. (Buat login Google di portal) **Authentication → Providers → Google** → Enable, isi
   Client ID & Secret dari Google Cloud Console. Magic-link (email) sudah aktif default.
5. (Khusyuk Learn — email+password) **Authentication → Providers → Email** → pastikan Enable.
   Kalau mau user langsung bisa masuk begitu daftar (tanpa klik link verifikasi),
   **matikan "Confirm email"** di Authentication → Providers → Email. Kalau dibiarkan ON,
   user daftar dulu → verifikasi via email → baru bisa Masuk.

> **Catatan RLS:** Portal & Khusyuk Learn sama-sama pakai Supabase Auth. Tiap user cuma
> bisa baca/tulis barisnya sendiri — portal cek membership miliknya, Khusyuk Learn simpan
> progres per `user_id` (policy `khusyuk_progress_own`, `auth.uid() = user_id`).

---

## Langkah 2 — Isi `config.js`

Buka `config.js`, isi 2 baris ini sekali (dipakai portal + Khusyuk Learn):

```js
window.YK_SUPABASE_URL  = "https://abcd.supabase.co";
window.YK_SUPABASE_ANON = "eyJhbGciOi...anon-key...";
```

Anon key **aman di-commit** ke GitHub (memang publik by design, dilindungi RLS).

---

## Langkah 3 — Push ke GitHub

```bash
cd yukkhusyuk-portal
git init
git add .
git commit -m "Pustaka YukKhusyuk: portal + khusyuk learn"
git branch -M main
git remote add origin https://github.com/USERNAME/yukkhusyuk-portal.git
git push -u origin main
```

---

## Langkah 4 — Deploy ke Vercel

1. [vercel.com](https://vercel.com) → **Add New → Project** → import repo tadi.
2. Framework Preset: **Other** (ini situs statis, nggak perlu build).
   - Build Command: kosongin · Output Directory: kosongin · Root: `./`
3. **Deploy**. Jadi deh, contoh `https://yukkhusyuk-portal.vercel.app`.

> Jangan bikin `vercel.json` dengan `"public": false` — itu mematahkan deploy Vercel versi baru.
> Package ini sengaja nggak butuh `vercel.json` sama sekali.

---

## Langkah 5 — Aktifkan member (setelah pembayaran)

Tiap ada yang beli, tambahin email-nya di Supabase. **SQL Editor**:

```sql
insert into public.members (email, active, note)
values ('pembeli@gmail.com', true, 'beli 12 Jan')
on conflict (email) do update set active = excluded.active;
```

Atau lewat **Table Editor → members → Insert row**. Begitu aktif, member login di portal
pakai email yang sama → semua produk kebuka.

---

## Cek cepat

- Buka URL Vercel → muncul halaman login portal.
- Belum isi `config.js`? Portal jalan mode demo (ada tombol pratinjau Member/Non-member).
- Khusyuk Learn: buka → tab **Daftar** (nama+email+password) → main → logout / buka device
  lain → tab **Masuk** pakai email+password sama → XP/streak/level kebawa dari Supabase.

## Troubleshooting

| Gejala | Penyebab / fix |
|---|---|
| Error "URL doubling" / 404 ke `/rest/v1/rest/v1` | `YK_SUPABASE_URL` kebawa `/rest/v1`. Pakai URL bare. |
| Login portal jalan tapi member ditolak | Email belum ada di tabel `members` atau `active=false`. |
| Progres Khusyuk Learn nggak nyimpan ke cloud | `config.js` masih kosong, atau `schema.sql` belum di-run. Cek console browser. |
| Daftar di Khusyuk Learn tapi nggak bisa langsung Masuk | "Confirm email" masih ON. Matikan di Authentication → Providers → Email, atau verifikasi lewat email dulu. |
| "Koneksi akun belum siap" | `config.js` belum diisi / SDK Supabase gagal load. Khusyuk Learn butuh Supabase aktif. |
| Provider Google error | Belum Enable di Authentication → Providers, atau redirect URL belum didaftarin di Google Console. |
