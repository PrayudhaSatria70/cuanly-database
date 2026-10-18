# Rencana Implementasi Teknis Cuanly
Backend NestJS, Database PostgreSQL, dan Integrasi Frontend Cuanly

## 1. Analisis Kebutuhan & Triad Akun Autentikasi

Berdasarkan instruksi dan rancangan UX/UI Cuanly, terdapat **3 persona akun** dengan perilaku sistem yang terisolasi dengan jelas:

| Akun | Kredensial | Tipe Penyimpanan | Integrasi Backend & Database | Deskripsi & Hak Akses |
|---|---|---|---|---|
| **Demo User** | Username: `user` atau `user@cuanly.com`<br>PIN/Pass: `123456` atau `user123` | **In-Memory / LocalStorage Mock** | **TIDAK TERINTEGRASI** *(Tetap hardcoded di FE)* | Pengguna demo personal untuk showcase cepat (1-Click Login). Akses role `USER`, tier `FREE` (kuota 2 dompet, Canva gold crown badge aktif). |
| **Demo Admin** | Username: `admin` atau `admin@cuanly.com`<br>PIN/Pass: `999999` atau `admin123` *(via tombol 1-Click Demo)* | **In-Memory / LocalStorage Mock** | **TIDAK TERINTEGRASI** *(Tetap hardcoded di FE)* | Admin demo untuk showcase backoffice cepat (1-Click Login). Akses role `ADMIN`, tier `B2B` (Full feature, bypass kuota). |
| **Live Admin** *(Fungsional)* | Username: `admin`<br>Email: `admin@cuanly.com`<br>Password / PIN: `admin123` (bisa login via username/email dan password/pin) | **PostgreSQL Database** *(Hashed Bcrypt)* | **LIVE & TERINTEGRASI PENUH** *(NestJS + PostgreSQL)* | Akun backoffice sungguhan. Login melalui form manual menggunakan username `admin` atau email `admin@cuanly.com`, serta password/pin `admin123`. Memiliki JWT token asli, hak akses `@Roles('ADMIN')`, mengelola data mitra, keluhan (complaints), settings, dan seluruh pengguna live. |
| **Registered User** *(Fungsional)* | Dibuat melalui form registrasi frontend (`/register`) | **PostgreSQL Database** *(Hashed Bcrypt)* | **LIVE & TERINTEGRASI PENUH** *(NestJS + PostgreSQL)* | Pengguna publik yang mendaftar melalui form registrasi frontend. Bisa login via username ATAU email, serta password ATAU pin 6 digit. Data tersimpan di database Postgres, menerima JWT token valid, dan seluruh data transaksi, dompet, budget, profil, dan settings tersinkronisasi ke server. |

---

## 2. Fleksibilitas Login & Keamanan Kredensial

Sesuai instruksi:
- **Identifier**: Pengguna (Admin maupun Registered User) dapat login menggunakan **Username** ATAU **Email**.
- **Kredensial Pengaman**: Pengguna dapat login menggunakan **Password** ATAU **PIN** 6 digit.
- **Penyimpanan di Database**:
  - Kolom `password_hash`: Hash Bcrypt dari password/pin pengguna.
  - Kolom `pin_hash`: Hash Bcrypt opsional jika pengguna mengatur PIN transaksi terpisah dari password login.
  - Logika verifikasi: Saat login, sistem memverifikasi kredensial terhadap `password_hash` atau `pin_hash`. Jika salah satu cocok, login berhasil!

---

## 3. Fitur Update & Sinkronisasi Settings (`/settings`)

Semua akun live (Admin maupun Pengguna Terdaftar) dapat melihat, mengedit, dan menyimpan pengaturan di halaman `/settings`:
- **Appearance**: Tema (`light` / `dark`).
- **Localization**: Bahasa (`en` / `id`), Mata Uang Utama (`IDR`, `USD`, `EUR`, dll.), serta daftar mata uang kustom.
- **Budget & Allowance**: Anggaran belanja bulanan (*monthly allowance*), ambang batas peringatan pengeluaran (*spending warning threshold* 70%-90%), dan custom threshold alert.
- **Smart OCR Scanner**: Kecepatan scan (`fast`, `standard`, `thorough`), klasifikasi otomatis (*auto-categorization*), dan konfirmasi sebelum simpan (*review before saving*).
- **Security & Timeout**: Durasi timeout inaktivitas sesi (1, 3, 5, 10 menit), pergantian password akun dan PIN.
- **Notifications**: Pengaturan peringatan pengeluaran, peringatan overbudget, suara notifikasi.
- **Account & Profile**: Pengubahan Nama Lengkap, Username, Email, Nomor Telepon, dan Foto Avatar.

Endpoint API yang disediakan:
- `GET /api/v1/users/settings`: Mengambil konfigurasi preferensi pengguna aktif.
- `PUT /api/v1/users/settings`: Memperbarui seluruh konfigurasi preferensi pengguna aktif secara atomik.

---

## 4. Arsitektur Komponen & Keselarasan Antar Repositori

### 4.1 Repositori Database: `cuanly-database`
Lokasi: `C:\Users\muhas\Desktop\WORK Projects\cuanly-database`
- **Prisma Schema (`prisma/schema.prisma`)**: Skema model relasional terpadu yang telah tervalidasi dengan Prisma CLI.
- **SQL Migration Script (`migrations/01_init.sql`)**: Skrip DDL standar PostgreSQL (kompatibel dengan Neon, Vercel Postgres, Supabase, Cloud SQL, atau Docker).
- **SQL & TypeScript Seed Scripts (`seeds/seed.sql` & `prisma/seed.ts`)**: Data awal akun live admin (`admin` / `admin123`), dompet awal, batas anggaran awal, mutasi demo, 9 kategori default Hick's Law, data mitra UMKM, dan komplain tiket.
- **`docker-compose.yml`**: Konfigurasi container PostgreSQL 16 & Web Adminer dengan mount script init otomatis.
- **Neon Ephemeral Branching (`.github/workflows/neon_workflow.yml`)**: Otomatisasi branch database preview terisolasi per Pull Request.
- **Proteksi `.env`**: `.gitignore` mengecualikan seluruh varian `.env` agar kredensial tidak pernah terekspos ke Git.

### 4.2 Repositori Backend Service: `cuanly-backend`
Lokasi: `C:\Users\muhas\Desktop\WORK Projects\cuanly-backend`
- Framework: **NestJS** (Modular Architecture)
- ORM: **Prisma ORM**
- Modul-modul Terintegrasi:
  - `auth`: Login, Register, Me, Profile Update, Avatar, Password, Subscription.
  - `beranda`: Agregasi dashboard kas, mutasi, dompet, dan kategori.
  - `transaksi`: Transaksi list, detail `[id]`, scanner OCR `scan`, dan penambahan transaksi `tambah`.
  - `budget`: Budget monitoring dan detail `[slug]`.
  - `pricing`: Pricing tiers publik, my-plan, dan upgrade paket langganan.
  - `profil`: Profil GET, PUT, avatar POST.
  - `settings`: Preferensi pengguna multi-tab.
  - `wallets`, `debts`, `workspace`, `ocr`, `admin` (dashboard, categories, transactions, users, verification, complaints).

### 4.3 Repositori Frontend: `cuanly-frontend`
Lokasi: `C:\Users\muhas\Desktop\WORK Projects\cuanly-frontend`
- Framework: **Next.js 14 App Router**
- Rute-rute yang Selaras:
  - `(auth)/login`, `(auth)/register`
  - `(user)/beranda`, `(user)/transaksi`, `(user)/transaksi/[id]`, `(user)/transaksi/scan`, `(user)/transaksi/tambah`
  - `(user)/budget`, `(user)/budget/[slug]`
  - `(user)/profil`, `(user)/settings`
  - `pricing`
  - `admin/dashboard`, `admin/categories`, `admin/transactions`, `admin/users`, `admin/users/[id]`, `admin/verification`, `admin/verification/[id]`, `admin/complaints`, `admin/complaints/[id]`

---

## 5. Status Eksekusi & Checklist Paritas

- [x] **Tahap 1**: Membangun skema DDL, Prisma schema, seeder data (Live Admin `admin`/`admin123`), dompet awal, batas anggaran awal, dan docker-compose di `cuanly-database`.
- [x] **Tahap 2**: Validasi skema Prisma (`prisma validate`, `prisma format`) dengan dual connection string (`DATABASE_URL` pooled & `DIRECT_URL` unpooled).
- [x] **Tahap 3**: Mengonfigurasi `package.json` di `cuanly-database` dengan script manajemen Prisma (`generate`, `push`, `seed`, `validate`, `format`) dan script Docker (`up`, `down`, `logs`).
- [x] **Tahap 4**: Pemutakhiran seeder ganda (`seeds/seed.sql` dan `prisma/seed.ts`) agar mendukung testing langsung via Prisma CLI maupun Docker init container.
- [x] **Tahap 5**: Proteksi ketat keamanan environment (`.env`) via `.gitignore`, memastikan `.env` tidak masuk git tracking (`git rm --cached .env`), dan pemutakhiran `.env.example`.
- [x] **Tahap 6**: Penyelarasan matriks 1:1 rute frontend, modul backend, dan skema tabel database di `settings_api_and_flow.md` dan `README.md`.
- [x] **Tahap 7**: Verifikasi final seluruh artefak dan pengujian tanpa merusak user worktree.
