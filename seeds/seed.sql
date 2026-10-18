-- ============================================================================
-- CUANLY DATABASE SEED DATA (POSTGRESQL)
-- ============================================================================

-- 1. SEED LIVE ADMIN ACCOUNT (Username: admin, Email: admin@cuanly.com, Password/PIN: admin123)
-- Bcrypt Hash for admin123: $2a$10$wK4m6O1JzMvV0pD2L7c1r.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa
INSERT INTO users (id, name, username, email, phone, role, password_hash, pin_hash, avatar_url, subscription_tier, is_active, created_at, updated_at)
VALUES (
    'usr_live_admin',
    'Administrator Cuanly',
    'admin',
    'admin@cuanly.com',
    '0811-9876-5432',
    'ADMIN',
    '$2a$10$wK4m6O1JzMvV0pD2L7c1r.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa',
    '$2a$10$wK4m6O1JzMvV0pD2L7c1r.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    'B2B',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET
    role = 'ADMIN',
    subscription_tier = 'B2B',
    is_active = true;

-- Seed Admin Settings
INSERT INTO user_settings (user_id, theme, locale, active_currency, monthly_allowance, spending_warning_threshold, ocr_speed, ocr_auto_cat, ocr_review, session_timeout_ms, custom_currencies, notifications_enabled, sound_enabled, updated_at)
VALUES (
    'usr_live_admin',
    'light',
    'en',
    'IDR',
    10000000,
    80,
    'standard',
    true,
    true,
    180000,
    '[]'::jsonb,
    true,
    true,
    CURRENT_TIMESTAMP
)
ON CONFLICT (user_id) DO NOTHING;

-- 2. SEED DEFAULT 9 SYSTEM CATEGORIES (Hick's Law: 6 Expense + 3 Income)
INSERT INTO categories (id, slug, name_key, fallback_name, icon, color, type, is_system, user_id, created_at)
VALUES
    ('cat_food', 'makanan', 'cat_food', 'Makanan & Minuman', 'Utensils', '#F97316', 'EXPENSE', true, NULL, CURRENT_TIMESTAMP),
    ('cat_transport', 'transportasi', 'cat_transport', 'Transportasi', 'Car', '#0EA5E9', 'EXPENSE', true, NULL, CURRENT_TIMESTAMP),
    ('cat_shopping', 'belanja', 'cat_shopping', 'Belanja', 'ShoppingBag', '#8B5CF6', 'EXPENSE', true, NULL, CURRENT_TIMESTAMP),
    ('cat_entertainment', 'hiburan', 'cat_entertainment', 'Hiburan', 'Film', '#EC4899', 'EXPENSE', true, NULL, CURRENT_TIMESTAMP),
    ('cat_health', 'kesehatan', 'cat_health', 'Kesehatan', 'HeartPulse', '#10B981', 'EXPENSE', true, NULL, CURRENT_TIMESTAMP),
    ('cat_other', 'lainnya', 'cat_other', 'Lainnya', 'MoreHorizontal', '#6B7072', 'EXPENSE', true, NULL, CURRENT_TIMESTAMP),
    ('cat_salary', 'gaji', 'cat_salary', 'Gaji Bulanan', 'Wallet', '#059669', 'INCOME', true, NULL, CURRENT_TIMESTAMP),
    ('cat_freelance', 'freelance', 'cat_freelance', 'Freelance & Bisnis', 'Briefcase', '#2563EB', 'INCOME', true, NULL, CURRENT_TIMESTAMP),
    ('cat_investment', 'investasi', 'cat_investment', 'Investasi & Bunga', 'TrendingUp', '#D97706', 'INCOME', true, NULL, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    name_key = EXCLUDED.name_key,
    fallback_name = EXCLUDED.fallback_name,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    type = EXCLUDED.type;

-- 3. SEED INITIAL WALLETS FOR LIVE ADMIN
INSERT INTO wallets (id, user_id, name, type, account_number, balance, color, is_shared, created_at, updated_at)
VALUES
    ('wal_admin_cash', 'usr_live_admin', 'Dompet Tunai', 'CASH', NULL, 1500000, '#10B981', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('wal_admin_bank', 'usr_live_admin', 'BCA Prioritas', 'BANK', '8820192831', 8500000, '#0284C7', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- 4. SEED INITIAL BUDGET LIMITS FOR LIVE ADMIN
INSERT INTO budget_limits (id, user_id, category_id, category_slug, limit_amount, period, created_at, updated_at)
VALUES
    ('bud_admin_food', 'usr_live_admin', 'cat_food', 'makanan', 2500000, TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM'), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('bud_admin_transport', 'usr_live_admin', 'cat_transport', 'transportasi', 1000000, TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM'), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (user_id, category_id, period) DO NOTHING;

-- 5. SEED RECENT TRANSACTIONS FOR LIVE ADMIN
INSERT INTO transactions (id, user_id, wallet_id, category_id, category_name, category_slug, type, amount, currency, currency_symbol, date, notes, created_at, updated_at)
VALUES
    ('tx_admin_01', 'usr_live_admin', 'wal_admin_cash', 'cat_food', 'Makanan & Minuman', 'makanan', 'EXPENSE', 45000, 'IDR', 'Rp', CURRENT_TIMESTAMP - INTERVAL '3 hours', 'Makan siang resto', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('tx_admin_02', 'usr_live_admin', 'wal_admin_bank', 'cat_salary', 'Gaji Bulanan', 'gaji', 'INCOME', 10000000, 'IDR', 'Rp', CURRENT_TIMESTAMP - INTERVAL '1 day', 'Gaji bulanan Cuanly', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- 6. SEED MITRA PARTNER APPLICATIONS (FOR ADMIN VERIFICATION)
INSERT INTO mitra (id, business_name, owner_name, email, phone, category, verification_status, submission_date, document_type, document_number, notes, created_at, updated_at)
VALUES
    ('mitra_01', 'Warung Kopi Kenangan Jaya', 'Hendro Wijaya', 'hendro@kopikenangan.id', '0813-2233-4455', 'Kuliner / F&B', 'PENDING', CURRENT_TIMESTAMP - INTERVAL '2 days', 'NIB & SIUP', '9120001234567', 'Menunggu review izin edar & rekening perusahaan', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('mitra_02', 'Apotek Sehat Sentosa', 'Dr. Maria Ulfa', 'maria@apoteksehat.com', '0812-9988-7766', 'Kesehatan & Farmasi', 'VERIFIED', CURRENT_TIMESTAMP - INTERVAL '5 days', 'SIA & SIPA', '440/123/DISKES/2026', 'Dokumen lengkap dan validasi Kemenkes berhasil', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('mitra_03', 'Bengkel Cepat Makmur', 'Agus Subagyo', 'agus@bengkelmakmur.co.id', '0815-4433-2211', 'Jasa Otomotif', 'REJECTED', CURRENT_TIMESTAMP - INTERVAL '7 days', 'KTP & NPWP', '3201123456780001', 'Foto SIUP buram dan alamat KTP tidak sinkron', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('mitra_04', 'Laundry Bersih Kilat', 'Dewi Lestari', 'dewi@bersihkilat.id', '0819-7766-5544', 'Jasa Rumah Tangga', 'PENDING', CURRENT_TIMESTAMP - INTERVAL '1 days', 'NIB Usaha Mikro', '1205009876543', 'Permohonan baru masuk kemarin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- 7. SEED COMPLAINTS & TICKETS (FOR ADMIN RESOLUTION)
INSERT INTO complaints (id, ticket_id, user_id, user_name, user_email, title, description, priority, status, resolution_note, created_at, updated_at)
VALUES
    ('cmp_01', 'TCK-2026-089', 'usr_02', 'Rian Pratama', 'rian@gmail.com', 'Gagal scan struk nota Indomaret', 'Foto nota saya tidak terbaca nominal totalnya, sistem OCR menampilkan angka 0.', 'MEDIUM', 'IN_PROGRESS', 'Tim teknis sedang meningkatkan toleransi kontras pada OCR scan struk termal.', CURRENT_TIMESTAMP - INTERVAL '1 days', CURRENT_TIMESTAMP),
    ('cmp_02', 'TCK-2026-088', 'usr_03', 'Anisa Kusuma', 'anisa.k@outlook.com', 'Notifikasi budget lewat batas tidak berdering', 'Pengeluaran makanan saya sudah 90% tapi belum ada notifikasi pop-up di layar.', 'HIGH', 'OPEN', NULL, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP),
    ('cmp_03', 'TCK-2026-085', 'usr_04', 'Farhan Dwi', 'farhan.dwi@yahoo.co.id', 'Permintaan ekspor data format CSV bulanan', 'Apakah bisa ditambahkan kolom kategori slug pada file CSV yang diekspor?', 'LOW', 'RESOLVED', 'Fitur ekspor CSV sudah diperbarui menyertakan kolom Kategori dan ID Transaksi.', CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;
