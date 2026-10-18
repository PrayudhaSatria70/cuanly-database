# Cuanly PostgreSQL Database

Repositori ini mengelola skema relasional, inisialisasi DDL, migrasi Prisma, dan data seeder untuk platform **Cuanly**.

## 1. Struktur Folder
`
cuanly-database/
├── docker-compose.yml          # Konfigurasi container PostgreSQL 16 & Adminer
├── migrations/
│   └── 01_init.sql             # Skrip DDL tabel-tabel PostgreSQL
├── seeds/
│   └── seed.sql                # Seeder Live Admin (admin/admin123), Kategori, Mitra, Keluhan
├── prisma/
│   └── schema.prisma           # Skema Prisma ORM relasional
├── .env.example                # Panduan variabel lingkungan & connection string
└── README.md                   # Dokumentasi teknis
`

## 2. Akun Live Default
- **Akun Live Admin**:
  - Username: dmin
  - Email: dmin@cuanly.com
  - Password / PIN: dmin123
  - Role: ADMIN (Tier: B2B Full Access)
  - Hash: Bcrypt ($)

## 3. Menjalankan Database

### Opsi A: Docker Compose (Lokal)
`ash
docker compose up -d
`
- PostgreSQL: localhost:5432 (User: postgres, Password: postgres, Database: cuanly_db)
- Web Adminer: http://localhost:8080

### Opsi B: Cloud PostgreSQL (Vercel Postgres, Neon, Supabase)
Cukup set DATABASE_URL di file .env repositori backend cuanly-backend:
`env
DATABASE_URL=postgresql://user:password@ep-xxx.pooler.region.neon.tech/cuanly_db?sslmode=require
`
Lalu jalankan migrasi Prisma dari backend:
`ash
npx prisma db push
npx prisma db seed
`
