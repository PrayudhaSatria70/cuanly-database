-- ============================================================================
-- CUANLY DATABASE INITIAL SCHEMA (POSTGRESQL)
-- ============================================================================

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    role VARCHAR(20) NOT NULL DEFAULT 'USER', -- 'USER', 'ADMIN'
    password_hash VARCHAR(255) NOT NULL,
    pin_hash VARCHAR(255),
    avatar_url TEXT,
    subscription_tier VARCHAR(20) NOT NULL DEFAULT 'FREE', -- 'FREE', 'SILVER', 'GOLD', 'B2B'
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 2. USER SETTINGS TABLE
CREATE TABLE IF NOT EXISTS user_settings (
    user_id VARCHAR(64) PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(20) NOT NULL DEFAULT 'light',
    locale VARCHAR(10) NOT NULL DEFAULT 'en',
    active_currency VARCHAR(10) NOT NULL DEFAULT 'IDR',
    monthly_allowance BIGINT NOT NULL DEFAULT 6700000,
    spending_warning_threshold INT NOT NULL DEFAULT 80,
    ocr_speed VARCHAR(20) NOT NULL DEFAULT 'standard',
    ocr_auto_cat BOOLEAN NOT NULL DEFAULT true,
    ocr_review BOOLEAN NOT NULL DEFAULT true,
    session_timeout_ms INT NOT NULL DEFAULT 180000,
    custom_currencies JSONB NOT NULL DEFAULT '[]'::jsonb,
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    sound_enabled BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    name_key VARCHAR(100) NOT NULL,
    fallback_name VARCHAR(255) NOT NULL,
    icon VARCHAR(50) NOT NULL,
    color VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'EXPENSE', 'INCOME'
    is_system BOOLEAN NOT NULL DEFAULT true,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);

-- 4. WALLETS TABLE
CREATE TABLE IF NOT EXISTS wallets (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'CASH', 'BANK', 'E_WALLET', 'SAVINGS'
    account_number VARCHAR(100),
    balance BIGINT NOT NULL DEFAULT 0,
    color VARCHAR(50) DEFAULT '#4D8DBA',
    is_shared BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_wallets_user ON wallets(user_id);

-- 5. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    wallet_id VARCHAR(64) REFERENCES wallets(id) ON DELETE SET NULL,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    category_name VARCHAR(255) NOT NULL,
    category_slug VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'EXPENSE', 'INCOME'
    amount BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    currency_symbol VARCHAR(10) DEFAULT 'Rp',
    date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    receipt JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);

-- 6. BUDGET LIMITS TABLE
CREATE TABLE IF NOT EXISTS budget_limits (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    category_slug VARCHAR(100) NOT NULL,
    limit_amount BIGINT NOT NULL,
    period VARCHAR(10) NOT NULL, -- 'YYYY-MM'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_budget_user_cat_period UNIQUE (user_id, category_id, period)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_period ON budget_limits(user_id, period);

-- 7. DEBTS & RECEIVABLES TABLE
CREATE TABLE IF NOT EXISTS debts (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL, -- 'DEBT', 'RECEIVABLE'
    person_name VARCHAR(255) NOT NULL,
    amount BIGINT NOT NULL,
    due_date VARCHAR(20) NOT NULL,
    notes TEXT,
    is_settled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_debts_user ON debts(user_id);

-- 8. WORKSPACE MEMBERS TABLE (B2B TIER)
CREATE TABLE IF NOT EXISTS workspace_members (
    id VARCHAR(64) PRIMARY KEY,
    owner_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER', -- 'OWNER', 'ADMIN', 'MEMBER'
    avatar_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'INVITED'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workspace_owner ON workspace_members(owner_id);

-- 9. MITRA BUSINESS VERIFICATION TABLE (ADMIN BACKOFFICE)
CREATE TABLE IF NOT EXISTS mitra (
    id VARCHAR(64) PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    category VARCHAR(100) NOT NULL,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'VERIFIED', 'REJECTED'
    submission_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    document_type VARCHAR(100) NOT NULL,
    document_number VARCHAR(100) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mitra_status ON mitra(verification_status);

-- 10. COMPLAINTS & TICKETS TABLE (ADMIN BACKOFFICE)
CREATE TABLE IF NOT EXISTS complaints (
    id VARCHAR(64) PRIMARY KEY,
    ticket_id VARCHAR(50) UNIQUE NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM', -- 'LOW', 'MEDIUM', 'HIGH'
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN', -- 'OPEN', 'IN_PROGRESS', 'RESOLVED'
    resolution_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_complaints_ticket ON complaints(ticket_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);

-- 11. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    title_en VARCHAR(255),
    message_en TEXT,
    type VARCHAR(20) NOT NULL DEFAULT 'INFO', -- 'WARNING', 'ALERT', 'INFO', 'SUCCESS'
    is_read BOOLEAN NOT NULL DEFAULT false,
    link VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- 12. INVESTMENT ASSETS TABLE (GOLD & B2B FEATURE)
CREATE TABLE IF NOT EXISTS investment_assets (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'REKSADANA', 'SAHAM', 'EMAS', 'CRYPTO', 'PROPERTI'
    quantity DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    buy_price BIGINT NOT NULL,
    current_price BIGINT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_investments_user ON investment_assets(user_id);
CREATE INDEX IF NOT EXISTS idx_investments_category ON investment_assets(category);

-- 13. BANK CONNECTIONS TABLE (AUTOMATIC BANK SYNC - GOLD & B2B FEATURE)
CREATE TABLE IF NOT EXISTS bank_connections (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    institution VARCHAR(50) NOT NULL, -- 'BCA', 'MANDIRI', 'BRI', 'BNI', 'GOPAY', 'OVO', 'DANA'
    account_number VARCHAR(100) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    sync_status VARCHAR(50) NOT NULL DEFAULT 'CONNECTED', -- 'CONNECTED', 'SYNCING', 'ERROR', 'DISCONNECTED'
    last_sync_at TIMESTAMPTZ,
    auto_sync BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_conn_user ON bank_connections(user_id);

-- 14. BUSINESS PROFILES TABLE (BUSINESS CASHFLOW & PPH FINAL TAX - B2B FEATURE)
CREATE TABLE IF NOT EXISTS business_profiles (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    npwp VARCHAR(50),
    period VARCHAR(20) NOT NULL DEFAULT '2026',
    annual_revenue BIGINT NOT NULL DEFAULT 0,
    operating_expense BIGINT NOT NULL DEFAULT 0,
    cash_runway_months DOUBLE PRECISION NOT NULL DEFAULT 12.0,
    tax_rate DOUBLE PRECISION NOT NULL DEFAULT 0.005, -- 0.5% PPh Final UMKM
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_biz_profile_user ON business_profiles(user_id);

-- ENHANCE DEBTS & WALLETS TABLES IF COLUMNS DO NOT EXIST
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='debts' AND column_name='tenor_months') THEN
        ALTER TABLE debts ADD COLUMN tenor_months INT DEFAULT 1;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='debts' AND column_name='interest_rate') THEN
        ALTER TABLE debts ADD COLUMN interest_rate DOUBLE PRECISION DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='debts' AND column_name='installment_amount') THEN
        ALTER TABLE debts ADD COLUMN installment_amount BIGINT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='debts' AND column_name='paid_amount') THEN
        ALTER TABLE debts ADD COLUMN paid_amount BIGINT DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='wallets' AND column_name='shared_role') THEN
        ALTER TABLE wallets ADD COLUMN shared_role VARCHAR(20) DEFAULT 'ADMIN';
    END IF;
END $$;
