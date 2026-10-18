# Cuanly Database Settings, CI/CD API, & Flow Specification

Spesifikasi arsitektur konfigurasi, API branching Neon, security controls, dan alur integrasi database untuk repositori `cuanly-database`.

---

## 1. Settings & Configuration

### 1.1 Variabel Lingkungan & Repositori
| Nama Variabel / Secret | Tipe Penyimpanan | Deskripsi & Tujuan | Default / Contoh Nilai |
|---|---|---|---|
| `NEON_PROJECT_ID` | GitHub Action Variable (`vars.NEON_PROJECT_ID`) | ID proyek Neon PostgreSQL yang digunakan untuk membuat database branch preview. | `floral-feather-12345678` |
| `NEON_API_KEY` | GitHub Action Secret (`secrets.NEON_API_KEY`) | API Key Neon dengan hak akses branch creation/deletion. | `neon_api_key_xxxxxxxx` |
| `DATABASE_URL` | Local `.env` / Workflow Environment | URL koneksi PostgreSQL standar / direct connection. | `postgresql://user:pass@ep-xyz.neon.tech/cuanly_db?sslmode=require` |
| `DATABASE_URL_UNPOOLED` | Local `.env` / Workflow Environment | URL koneksi langsung tanpa PgBouncer (untuk migrasi schema DDL). | `postgresql://user:pass@ep-xyz.neon.tech/cuanly_db?sslmode=require` |
| `EXPIRES_AT` | Dynamic Workflow Env | Timestamp ISO8601 masa berlaku branch ephemeral (TTL 14 hari). | `YYYY-MM-DDTHH:MM:SSZ` |

### 1.2 Permissions & Access Control
- **GitHub Actions Permissions**:
  - `contents: read`: Membaca referensi branch dan commit repo.
  - `pull-requests: write` *(opsional jika diff comments diaktifkan)*: Mengunggah komentar preview database url / migration diff ke Pull Request.
- **Neon Role Privileges**:
  - API Key harus memiliki role yang diizinkan untuk mengelola branches di project terkait (`Admin` atau `Developer` dengan token permission).

---

## 2. API & External Service Interaction

### 2.1 Neon Branch Management API (via GitHub Actions)

#### A. Create Ephemeral Database Branch
- **Action**: `neondatabase/create-branch-action@v6`
- **Trigger**: Pull Request (`opened`, `reopened`, `synchronize`)
- **Input Parameters**:
  - `project_id`: `${{ vars.NEON_PROJECT_ID }}`
  - `branch_name`: `preview/pr-${{ github.event.number }}-${{ branch }}`
  - `api_key`: `${{ secrets.NEON_API_KEY }}`
  - `expires_at`: `+14 days`
- **Output Parameters**:
  - `db_url`: Direct database connection string
  - `db_url_with_pooler` / `db_url_pooled`: Connection string melalui pooling proxy PgBouncer
  - `branch_id`: ID unik branch yang dibuat di Neon

#### B. Delete Ephemeral Database Branch
- **Action**: `neondatabase/delete-branch-action@v3`
- **Trigger**: Pull Request (`closed`)
- **Input Parameters**:
  - `project_id`: `${{ vars.NEON_PROJECT_ID }}`
  - `branch`: `preview/pr-${{ github.event.number }}-${{ branch }}`
  - `api_key`: `${{ secrets.NEON_API_KEY }}`
- **Behavior**: Menghapus branch database beserta compute endpoint terkait untuk mencegah kebocoran resource.

---

## 3. Flow Architecture

```
Developer (Git Push / Open PR)
       │
       ▼
GitHub Actions (neon_workflow.yml)
       │
       ├──► Job 1: setup (tj-actions/branch-names@v8)
       │       │ Outputs: branch name
       │       ▼
       ├──► Job 2: create_neon_branch (neondatabase/create-branch-action@v6)
       │       │ Input: NEON_PROJECT_ID, NEON_API_KEY, branch_name, expires_at (14d)
       │       ▼
       │    Neon Cloud API
       │       │ Creates isolated child branch from parent (main)
       │       ▼
       │    Returns: db_url / db_url_with_pooler
       │       │
       │       ├──► (Optional) Run Prisma / SQL Migrations on isolated branch
       │       └──► (Optional) Run Integration / E2E Tests with realistic data
       │
       ▼
Developer Merges / Closes PR
       │
       ▼
GitHub Actions (neon_workflow.yml)
       │
       └──► Job 3: delete_neon_branch (neondatabase/delete-branch-action@v3)
               │ Input: NEON_PROJECT_ID, NEON_API_KEY, branch_name
               ▼
            Neon Cloud API
               └── Deletes ephemeral branch & terminates compute instance
```

---

## 4. Data & Schema Pipeline

1. **Source of Truth**:
   - Skrip DDL PostgreSQL: `migrations/01_init.sql`
   - Prisma Schema: `prisma/schema.prisma`
   - Seeder Data: `seeds/seed.sql`
2. **Branching Isolation**:
   - Setiap branch ephemeral merupakan Copy-on-Write (CoW) dari branch `main` Neon.
   - Tidak ada duplikasi data fisik secara penuh, sehingga pembuatan branch instan (< 3 detik) tanpa membebani storage induk.
   - Perubahan data selama pengujian PR terisolasi penuh dan tidak merusak database utama.

---

## 5. Security Controls

- **Zero-Secret In Logs**: `DATABASE_URL` dan `NEON_API_KEY` tidak boleh di-print atau di-echo ke log workflow runner.
- **Least Privilege Secrets**: `NEON_API_KEY` disimpan sebagai GitHub Encrypted Secret, bukan plain-text repository variable.
- **TTL Expiration Defense-in-Depth**: Branch dibuat dengan batas kedaluwarsa (`expires_at` 14 hari) agar branch yang PR-nya terlantar tidak hidup selamanya.
- **Concurrency Isolation**: Workflow menggunakan `concurrency.group: ${{ github.workflow }}-${{ github.ref }}` untuk mencegah race conditions saat ada commit berturut-turut pada PR yang sama.

---

## 6. Operations & Monitoring

- **Monitoring**: Branch aktif dapat dipantau di Neon Console pada tab **Branches**.
- **Auditing**: Riwayat eksekusi workflow tersimpan di tab GitHub Actions repositori `cuanly-database`.
- **Cleanups**: Pembersihan otomatis saat event PR `closed` (baik setelah merge maupun cancel).
