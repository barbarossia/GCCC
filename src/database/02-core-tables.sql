-- ================================================================
-- GCCC 核心数据表结构
-- 包含用户、认证、权限等核心功能表
-- ================================================================

-- 用户表
-- ================================================================
CREATE TABLE users (
    id BIGINT PRIMARY KEY DEFAULT nextval('user_id_seq'),
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    
    -- 基本信息
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    wallet_address VARCHAR(44) UNIQUE NOT NULL,
    
    -- 个人信息
    display_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    
    -- 系统信息
    status user_status_enum NOT NULL DEFAULT 'pending',
    role user_role_enum NOT NULL DEFAULT 'user',
    auth_method auth_method_enum NOT NULL DEFAULT 'wallet',
    
    -- 推荐系统
    referral_code VARCHAR(10) UNIQUE NOT NULL DEFAULT generate_referral_code(),
    referred_by_user_id BIGINT REFERENCES users(id),
    referral_count INTEGER DEFAULT 0,
    
    -- 安全信息
    email_verified BOOLEAN DEFAULT FALSE,
    wallet_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(32),
    
    -- 统计信息
    login_count INTEGER DEFAULT 0,
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- 约束
    CONSTRAINT users_username_length CHECK (length(username) >= 3),
    CONSTRAINT users_email_format CHECK (email IS NULL OR is_valid_email(email)),
    CONSTRAINT users_wallet_format CHECK (is_valid_solana_address(wallet_address))
);

-- 用户会话表
-- ================================================================
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 会话信息
    token_hash VARCHAR(128) NOT NULL UNIQUE,
    refresh_token_hash VARCHAR(128) UNIQUE,
    device_id VARCHAR(255),
    device_info JSONB,
    
    -- 网络信息
    ip_address INET NOT NULL,
    user_agent TEXT,
    location JSONB,
    
    -- 状态和时间
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 用户钱包表
-- ================================================================
CREATE TABLE user_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 钱包信息
    wallet_address VARCHAR(44) NOT NULL,
    wallet_type VARCHAR(20) NOT NULL DEFAULT 'solana',
    wallet_name VARCHAR(100),
    
    -- 验证信息
    signature_message TEXT,
    signature_hash VARCHAR(128),
    nonce VARCHAR(64),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- 状态
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(user_id, wallet_address),
    CONSTRAINT user_wallets_address_format CHECK (is_valid_solana_address(wallet_address))
);

-- 用户权限表
-- ================================================================
CREATE TABLE user_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 权限信息
    permission_name VARCHAR(100) NOT NULL,
    permission_value BOOLEAN DEFAULT TRUE,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    
    -- 权限来源
    granted_by_user_id BIGINT REFERENCES users(id),
    granted_reason TEXT,
    
    -- 时间信息
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    
    -- 约束
    UNIQUE(user_id, permission_name, resource_type, resource_id)
);

-- 用户积分表
-- ================================================================
CREATE TABLE user_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 积分信息
    points_balance DECIMAL(20,8) DEFAULT 0,
    lifetime_earned DECIMAL(20,8) DEFAULT 0,
    lifetime_spent DECIMAL(20,8) DEFAULT 0,
    
    -- 等级信息
    user_level INTEGER DEFAULT 1,
    level_progress DECIMAL(5,2) DEFAULT 0,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    CONSTRAINT user_points_balance_positive CHECK (points_balance >= 0),
    CONSTRAINT user_points_level_positive CHECK (user_level >= 1)
);

-- 积分交易记录表
-- ================================================================
CREATE TABLE points_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 交易信息
    transaction_type VARCHAR(50) NOT NULL,
    amount DECIMAL(20,8) NOT NULL,
    balance_before DECIMAL(20,8) NOT NULL,
    balance_after DECIMAL(20,8) NOT NULL,
    
    -- 描述信息
    description TEXT,
    metadata JSONB,
    
    -- 关联信息
    reference_type VARCHAR(50),
    reference_id UUID,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    CONSTRAINT points_transactions_amount_not_zero CHECK (amount != 0)
);

-- 每日签到记录表
-- ================================================================
CREATE TABLE daily_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 签到信息
    checkin_date DATE NOT NULL,
    points_earned DECIMAL(20,8) DEFAULT 0,
    consecutive_days INTEGER DEFAULT 1,
    
    -- 奖励信息
    bonus_multiplier DECIMAL(3,2) DEFAULT 1.0,
    special_reward JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(user_id, checkin_date),
    CONSTRAINT daily_checkins_consecutive_positive CHECK (consecutive_days >= 1)
);

-- 邀请记录表
-- ================================================================
CREATE TABLE referral_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referee_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 邀请信息
    referral_code VARCHAR(10) NOT NULL,
    invitation_method VARCHAR(50) DEFAULT 'direct',
    
    -- 奖励信息
    referrer_reward DECIMAL(20,8) DEFAULT 0,
    referee_reward DECIMAL(20,8) DEFAULT 0,
    reward_distributed BOOLEAN DEFAULT FALSE,
    
    -- 状态信息
    status VARCHAR(20) DEFAULT 'pending',
    activated_at TIMESTAMP WITH TIME ZONE,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(referee_user_id),
    CONSTRAINT referral_different_users CHECK (referrer_user_id != referee_user_id)
);

-- 系统配置表
-- ================================================================
CREATE TABLE system_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 配置信息
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    config_type VARCHAR(20) DEFAULT 'string',
    
    -- 描述信息
    description TEXT,
    category VARCHAR(50) DEFAULT 'general',
    is_public BOOLEAN DEFAULT FALSE,
    is_editable BOOLEAN DEFAULT TRUE,
    
    -- 验证信息
    validation_rule JSONB,
    default_value TEXT,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 系统日志表
-- ================================================================
CREATE TABLE system_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 日志信息
    log_level VARCHAR(10) NOT NULL,
    log_message TEXT NOT NULL,
    log_category VARCHAR(50) DEFAULT 'general',
    
    -- 上下文信息
    user_id BIGINT REFERENCES users(id),
    session_id UUID REFERENCES user_sessions(id),
    request_id UUID,
    
    -- 技术信息
    ip_address INET,
    user_agent TEXT,
    endpoint VARCHAR(255),
    method VARCHAR(10),
    status_code INTEGER,
    
    -- 详细信息
    metadata JSONB,
    stack_trace TEXT,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 审计日志表
-- ================================================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 操作信息
    action audit_action_enum NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100),
    
    -- 用户信息
    user_id BIGINT REFERENCES users(id),
    ip_address INET,
    user_agent TEXT,
    
    -- 数据变更
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    
    -- 描述信息
    description TEXT,
    metadata JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
-- ================================================================

-- 用户表索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_wallet_address ON users(wallet_address);
CREATE INDEX idx_users_referral_code ON users(referral_code);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_referred_by ON users(referred_by_user_id);

-- 会话表索引
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token_hash ON user_sessions(token_hash);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);
CREATE INDEX idx_user_sessions_is_active ON user_sessions(is_active);

-- 钱包表索引
CREATE INDEX idx_user_wallets_user_id ON user_wallets(user_id);
CREATE INDEX idx_user_wallets_address ON user_wallets(wallet_address);
CREATE INDEX idx_user_wallets_is_primary ON user_wallets(is_primary);

-- 权限表索引
CREATE INDEX idx_user_permissions_user_id ON user_permissions(user_id);
CREATE INDEX idx_user_permissions_name ON user_permissions(permission_name);
CREATE INDEX idx_user_permissions_resource ON user_permissions(resource_type, resource_id);

-- 积分表索引
CREATE INDEX idx_user_points_user_id ON user_points(user_id);
CREATE INDEX idx_points_transactions_user_id ON points_transactions(user_id);
CREATE INDEX idx_points_transactions_type ON points_transactions(transaction_type);
CREATE INDEX idx_points_transactions_created_at ON points_transactions(created_at);

-- 签到表索引
CREATE INDEX idx_daily_checkins_user_id ON daily_checkins(user_id);
CREATE INDEX idx_daily_checkins_date ON daily_checkins(checkin_date);

-- 邀请表索引
CREATE INDEX idx_referral_records_referrer ON referral_records(referrer_user_id);
CREATE INDEX idx_referral_records_referee ON referral_records(referee_user_id);
CREATE INDEX idx_referral_records_code ON referral_records(referral_code);

-- 配置表索引
CREATE INDEX idx_system_configs_key ON system_configs(config_key);
CREATE INDEX idx_system_configs_category ON system_configs(category);

-- 日志表索引
CREATE INDEX idx_system_logs_level ON system_logs(log_level);
CREATE INDEX idx_system_logs_category ON system_logs(log_category);
CREATE INDEX idx_system_logs_user_id ON system_logs(user_id);
CREATE INDEX idx_system_logs_created_at ON system_logs(created_at);

-- 审计表索引
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- 创建触发器
-- ================================================================

-- 用户表更新时间触发器
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 会话表更新时间触发器
CREATE TRIGGER trigger_user_sessions_updated_at
    BEFORE UPDATE ON user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 钱包表更新时间触发器
CREATE TRIGGER trigger_user_wallets_updated_at
    BEFORE UPDATE ON user_wallets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 积分表更新时间触发器
CREATE TRIGGER trigger_user_points_updated_at
    BEFORE UPDATE ON user_points
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 邀请表更新时间触发器
CREATE TRIGGER trigger_referral_records_updated_at
    BEFORE UPDATE ON referral_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 配置表更新时间触发器
CREATE TRIGGER trigger_system_configs_updated_at
    BEFORE UPDATE ON system_configs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 钱包地址验证触发器
CREATE TRIGGER trigger_check_wallet_address
    BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION check_wallet_address();

-- 表注释
-- ================================================================

COMMENT ON TABLE users IS '用户基础信息表';
COMMENT ON TABLE user_sessions IS '用户会话管理表';
COMMENT ON TABLE user_wallets IS '用户钱包地址表';
COMMENT ON TABLE user_permissions IS '用户权限配置表';
COMMENT ON TABLE user_points IS '用户积分余额表';
COMMENT ON TABLE points_transactions IS '积分交易记录表';
COMMENT ON TABLE daily_checkins IS '每日签到记录表';
COMMENT ON TABLE referral_records IS '用户邀请记录表';
COMMENT ON TABLE system_configs IS '系统配置参数表';
COMMENT ON TABLE system_logs IS '系统运行日志表';
COMMENT ON TABLE audit_logs IS '数据操作审计表';

-- 权限设置
-- ================================================================

-- 授予用户表权限
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_sessions TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_wallets TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_permissions TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_points TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON points_transactions TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_checkins TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON referral_records TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON system_configs TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON system_logs TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON audit_logs TO gccc_user;

-- 序列权限
GRANT USAGE, SELECT ON user_id_seq TO gccc_user;

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '核心数据表创建完成';
    RAISE NOTICE '已创建表: users, user_sessions, user_wallets, user_permissions';
    RAISE NOTICE '已创建表: user_points, points_transactions, daily_checkins';
    RAISE NOTICE '已创建表: referral_records, system_configs, system_logs, audit_logs';
    RAISE NOTICE '已创建相关索引和触发器';
END
$$;
