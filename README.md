# Cuanly PostgreSQL Database

Repositori ini mengelola skema relasional, inisialisasi DDL, migrasi Prisma ORM, seeder data, dan CI/CD branching Neon untuk platform **Cuanly**. Struktur repositori ini diselaraskan 1:1 dengan struktur modul backend [cuanly-backend](file:///c:/Users/muhas/Desktop/WORK%20Projects/cuanly-backend) dan frontend [cuanly-frontend](file:///c:/Users/muhas/Desktop/WORK%20Projects/cuanly-frontend).

---

## 1. Struktur Folder
```text
cuanly-database/
├── .github/
│   └── workflows/
│       └── neon_workflow.yml   # CI/CD otomatisasi branch Neon PostgreSQL per Pull Request
├── docker-compose.yml          # Konfigurasi container PostgreSQL 16 & Web Adminer
├── migrations/
│   └── 01_init.sql             # Skrip DDL tabel-tabel PostgreSQL (11 tabel relasional)
├── seeds/
│   └── seed.sql                # Seeder SQL data awal (Live Admin, Kategori, Mitra, Komplain)
├── prisma/
│   ├── schema.prisma           # Skema Prisma ORM relasional
│   └── seed.ts                 # Seeder TypeScript untuk Prisma CLI
├── .env.example                # Template variabel lingkungan aman (tanpa rahasia)
├── .gitignore                  # Proteksi ketat pencegahan commit file .env dan node_modules
├── package.json                # Skrip manajemen Prisma dan Docker
├── settings_api_and_flow.md    # Spesifikasi teknis konfigurasi, alignment, flow data, dan CI/CD
├── IMPLEMENTATION_PLAN.md      # Rencana implementasi teknis dan paritas arsitektur
└── README.md                   # Dokumentasi teknis repositori
```

---

## 2. Keselarasan Folder & Modul (Frontend & Backend Alignment)

Tabel skema database memfasilitasi seluruh fungsionalitas rute frontend dan modul backend:
- `(auth)/login` & `(auth)/register` ──► `users`, `user_settings`
- `(user)/beranda` ──► `transactions`, `wallets`, `categories`, `budget_limits`
- `(user)/transaksi`, `(user)/transaksi/[id]`, `(user)/transaksi/tambah` ──► `transactions`, `wallets`, `categories`
- `(user)/transaksi/scan` ──► `transactions` (kolom `receipt` format JSONB)
- `(user)/budget`, `(user)/budget/[slug]` ──► `budget_limits`, `categories`
- `(user)/profil` ──► `users` (`avatar_url`, `name`, `username`, `phone`, `email`)
- `(user)/settings` ──► `user_settings` (preferensi tema, bahasa, allowance, threshold, dll.)
- `pricing` ──► `users.subscription_tier` (`FREE`, `SILVER`, `GOLD`, `B2B`) & validasi kuota dompet
- `admin/dashboard`, `admin/categories`, `admin/transactions`, `admin/users` ──► `users`, `transactions`, `categories`, `mitra`, `complaints`
- `admin/verification` ──► `mitra`
- `admin/complaints` ──► `complaints`

Spesifikasi lengkap dan diagram alur dapat dilihat pada dokumen [settings_api_and_flow.md](settings_api_and_flow.md).

---

## 3. Keamanan Lingkungan (Zero-Secret Policy)
> [!IMPORTANT]
> **Pencegahan Kebocoran File `.env`**:
> - File `.env` berisi string koneksi database dengan password dan **TIDAK BOLEH** dikomit ke repositori.
> - File `.gitignore` telah dikonfigurasi untuk mengecualikan `.env`, `.env.*`, dan seluruh varian lokal.
> - Gunakan hanya [`.env.example`](.env.example) sebagai acuan konfigurasi variabel lingkungan.

---

## 4. Akun Live Default (Tersedia di Seeder)
- **Akun Live Admin**:
  - Username: `admin`
  - Email: `admin@cuanly.com`
  - Password / PIN: `admin123`
  - Role: `ADMIN` (Tier: B2B Full Access)
  - Hash: Bcrypt Salted Hash (`$2a$10$...`)

---

## 5. Menjalankan Database

### Opsi A: Docker Compose (Lokal)
```bash
# Menyalakan container PostgreSQL 16 & Adminer
npm run docker:up

# Memeriksa log database
npm run docker:logs

# Menghentikan container
npm run docker:down
```
- PostgreSQL: `localhost:5432` (User: `postgres`, Password: `postgres`, Database: `cuanly_db`)
- Web Adminer: `http://localhost:8080`

### Opsi B: Cloud PostgreSQL (Neon / Serverless)
1. Salin `.env.example` menjadi `.env`.
2. Isi `DATABASE_URL` (pooled connection) dan `DIRECT_URL` (direct connection unpooled):
```env
DATABASE_URL="postgresql://neondb_owner:YOUR_PASSWORD@ep-xxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"
DIRECT_URL="postgresql://neondb_owner:YOUR_PASSWORD@ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require"
```
3. Jalankan migrasi dan seeder:
```bash
npm run prisma:validate
npm run prisma:push
npm run prisma:seed
```

---

## 6. Neon Database Branching CI/CD (GitHub Actions)
Repositori ini dilengkapi workflow GitHub Actions ([neon_workflow.yml](.github/workflows/neon_workflow.yml)) yang secara otomatis membuat database branch terisolasi untuk setiap Pull Request (PR) dan menghapusnya saat PR ditutup:

1. **Variables & Secrets yang Dibutuhkan**:
   - `vars.NEON_PROJECT_ID`: ID project Neon Anda (tersedia di Neon Console Settings).
   - `secrets.NEON_API_KEY`: API Key akun Neon Anda (dibuat di Neon Account Settings > API Keys).
2. **Lifecycle Branch**:
   - **PR Opened / Synchronize / Reopened**: Membuat branch baru dengan format `preview/pr-<PR_NUMBER>-<BRANCH_NAME>` dan masa berlaku (TTL) otomatis 14 hari.
   - **PR Closed**: Menghapus branch secara otomatis untuk menghemat resource database.
