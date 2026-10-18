# Cuanly PostgreSQL Database

Repositori ini mengelola skema relasional, inisialisasi DDL, migrasi Prisma, dan data seeder untuk platform **Cuanly**.

## 1. Struktur Folder
```text
cuanly-database/
├── .github/
│   └── workflows/
│       └── neon_workflow.yml   # CI/CD otomatisasi branch Neon PostgreSQL per Pull Request
├── docker-compose.yml          # Konfigurasi container PostgreSQL 16 & Adminer
├── migrations/
│   └── 01_init.sql             # Skrip DDL tabel-tabel PostgreSQL
├── seeds/
│   └── seed.sql                # Seeder Live Admin (admin/admin123), Kategori, Mitra, Keluhan
├── prisma/
│   └── schema.prisma           # Skema Prisma ORM relasional
├── .env.example                # Panduan variabel lingkungan & connection string
├── settings_api_and_flow.md    # Spesifikasi teknis konfigurasi, flow data, dan CI/CD
└── README.md                   # Dokumentasi teknis
```

## 2. Akun Live Default
- **Akun Live Admin**:
  - Username: `admin`
  - Email: `admin@cuanly.com`
  - Password / PIN: `admin123`
  - Role: `ADMIN` (Tier: B2B Full Access)
  - Hash: Bcrypt (`$2b$10$...`)

## 3. Menjalankan Database

### Opsi A: Docker Compose (Lokal)
```bash
docker compose up -d
```
- PostgreSQL: `localhost:5432` (User: `postgres`, Password: `postgres`, Database: `cuanly_db`)
- Web Adminer: `http://localhost:8080`

### Opsi B: Cloud PostgreSQL (Vercel Postgres, Neon, Supabase)
Cukup set `DATABASE_URL` di file `.env` repositori backend `cuanly-backend`:
```env
DATABASE_URL=postgresql://user:password@ep-xxx.pooler.region.neon.tech/cuanly_db?sslmode=require
```
Lalu jalankan migrasi Prisma dari backend:
```bash
npx prisma db push
npx prisma db seed
```

## 4. Neon Database Branching CI/CD (GitHub Actions)
Repositori ini dilengkapi workflow GitHub Actions ([neon_workflow.yml](.github/workflows/neon_workflow.yml)) yang secara otomatis membuat database branch terisolasi untuk setiap Pull Request (PR) dan menghapusnya saat PR ditutup:

1. **Variables & Secrets yang Dibutuhkan**:
   - `vars.NEON_PROJECT_ID`: ID project Neon Anda (tersedia di Neon Console Settings).
   - `secrets.NEON_API_KEY`: API Key akun Neon Anda (dibuat di Neon Account Settings > API Keys).
2. **Lifecycle Branch**:
   - **PR Opened / Synchronize / Reopened**: Membuat branch baru dengan nama format `preview/pr-<PR_NUMBER>-<BRANCH_NAME>` dan masa berlaku (TTL) otomatis 14 hari.
   - **PR Closed**: Menghapus branch secara otomatis untuk menghemat resource database.
