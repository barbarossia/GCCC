-- ================================================================
-- GCCC 数据库初始化脚本
-- 创建数据库、用户、基础配置和扩展
-- ================================================================

-- 创建数据库（如果不存在）
-- 注意：此部分需要以超级用户身份执行
CREATE DATABASE gccc_db
    WITH 
    OWNER = gccc_user
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    TEMPLATE = template0;

-- 创建数据库用户（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gccc_user') THEN
        CREATE ROLE gccc_user LOGIN PASSWORD 'gccc_password_2024!';
    END IF;
END
$$;

-- 连接到GCCC数据库
\c gccc_db;

-- 创建必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 设置时区
SET timezone = 'UTC';

-- 创建自定义类型和枚举
-- ================================================================

-- 用户状态枚举
CREATE TYPE user_status_enum AS ENUM (
    'active',           -- 活跃用户
    'inactive',         -- 非活跃用户
    'suspended',        -- 暂停用户
    'banned',           -- 封禁用户
    'pending'           -- 待验证用户
);

-- 用户角色枚举
CREATE TYPE user_role_enum AS ENUM (
    'user',             -- 普通用户
    'moderator',        -- 版主
    'admin',            -- 管理员
    'super_admin'       -- 超级管理员
);

-- 认证方式枚举
CREATE TYPE auth_method_enum AS ENUM (
    'wallet',           -- 钱包认证
    'email',            -- 邮箱认证
    'social'            -- 社交媒体认证
);

-- 交易状态枚举
CREATE TYPE transaction_status_enum AS ENUM (
    'pending',          -- 待处理
    'processing',       -- 处理中
    'completed',        -- 已完成
    'failed',           -- 失败
    'cancelled'         -- 已取消
);

-- 交易类型枚举
CREATE TYPE transaction_type_enum AS ENUM (
    'deposit',          -- 存款
    'withdrawal',       -- 提款
    'transfer',         -- 转账
    'reward',           -- 奖励
    'fee',              -- 手续费
    'staking',          -- 质押
    'unstaking',        -- 解质押
    'lottery',          -- 抽奖
    'nft_mint',         -- NFT铸造
    'nft_trade'         -- NFT交易
);

-- 提案状态枚举
CREATE TYPE proposal_status_enum AS ENUM (
    'draft',            -- 草稿
    'active',           -- 活跃投票中
    'passed',           -- 通过
    'rejected',         -- 拒绝
    'cancelled',        -- 取消
    'executed'          -- 已执行
);

-- 投票选项枚举
CREATE TYPE vote_option_enum AS ENUM (
    'yes',              -- 赞成
    'no',               -- 反对
    'abstain'           -- 弃权
);

-- 质押状态枚举
CREATE TYPE staking_status_enum AS ENUM (
    'active',           -- 活跃质押
    'pending',          -- 待激活
    'unlocking',        -- 解锁中
    'completed',        -- 已完成
    'slashed'           -- 已罚没
);

-- 抽奖状态枚举
CREATE TYPE lottery_status_enum AS ENUM (
    'upcoming',         -- 即将开始
    'active',           -- 进行中
    'drawing',          -- 开奖中
    'completed',        -- 已完成
    'cancelled'         -- 已取消
);

-- NFT状态枚举
CREATE TYPE nft_status_enum AS ENUM (
    'draft',            -- 草稿
    'minting',          -- 铸造中
    'active',           -- 活跃
    'burned',           -- 已销毁
    'frozen'            -- 已冻结
);

-- 审计操作类型枚举
CREATE TYPE audit_action_enum AS ENUM (
    'create',           -- 创建
    'update',           -- 更新
    'delete',           -- 删除
    'login',            -- 登录
    'logout',           -- 登出
    'approve',          -- 批准
    'reject',           -- 拒绝
    'suspend',          -- 暂停
    'restore'           -- 恢复
);

-- 通知类型枚举
CREATE TYPE notification_type_enum AS ENUM (
    'system',           -- 系统通知
    'proposal',         -- 提案通知
    'staking',          -- 质押通知
    'lottery',          -- 抽奖通知
    'nft',              -- NFT通知
    'reward',           -- 奖励通知
    'security'          -- 安全通知
);

-- 通知状态枚举
CREATE TYPE notification_status_enum AS ENUM (
    'unread',           -- 未读
    'read',             -- 已读
    'archived'          -- 已归档
);

-- 创建序列
-- ================================================================

-- 用户ID序列
CREATE SEQUENCE user_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- 提案ID序列
CREATE SEQUENCE proposal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- 抽奖期数序列
CREATE SEQUENCE lottery_round_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- 通用函数
-- ================================================================

-- 更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 生成随机字符串函数
CREATE OR REPLACE FUNCTION generate_random_string(length INTEGER DEFAULT 32)
RETURNS TEXT AS $$
BEGIN
    RETURN array_to_string(
        ARRAY(
            SELECT substring(
                'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
                (random() * 36)::int + 1,
                1
            )
            FROM generate_series(1, length)
        ),
        ''
    );
END;
$$ LANGUAGE plpgsql;

-- 验证钱包地址格式函数
CREATE OR REPLACE FUNCTION is_valid_solana_address(address TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Solana地址应该是44个字符的Base58编码
    RETURN address ~ '^[1-9A-HJ-NP-Za-km-z]{44}$';
END;
$$ LANGUAGE plpgsql;

-- 检查地址约束
CREATE OR REPLACE FUNCTION check_wallet_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT is_valid_solana_address(NEW.wallet_address) THEN
        RAISE EXCEPTION 'Invalid Solana wallet address format: %', NEW.wallet_address;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 权限检查函数
CREATE OR REPLACE FUNCTION has_permission(user_role user_role_enum, required_role user_role_enum)
RETURNS BOOLEAN AS $$
BEGIN
    CASE user_role
        WHEN 'super_admin' THEN RETURN TRUE;
        WHEN 'admin' THEN RETURN required_role IN ('admin', 'moderator', 'user');
        WHEN 'moderator' THEN RETURN required_role IN ('moderator', 'user');
        WHEN 'user' THEN RETURN required_role = 'user';
        ELSE RETURN FALSE;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 计算质押奖励函数
CREATE OR REPLACE FUNCTION calculate_staking_reward(
    staked_amount DECIMAL,
    apy_rate DECIMAL,
    days_staked INTEGER
)
RETURNS DECIMAL AS $$
BEGIN
    -- 计算日奖励 = 本金 * 年化收益率 * 天数 / 365
    RETURN ROUND(staked_amount * apy_rate / 100 * days_staked / 365, 8);
END;
$$ LANGUAGE plpgsql;

-- 验证邮箱格式函数
CREATE OR REPLACE FUNCTION is_valid_email(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql;

-- 生成推荐码函数
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    exists_count INTEGER;
BEGIN
    LOOP
        -- 生成6位大写字母和数字的推荐码
        code := upper(generate_random_string(6));
        
        -- 检查是否已存在
        SELECT COUNT(*) INTO exists_count 
        FROM users 
        WHERE referral_code = code;
        
        -- 如果不存在，返回该码
        IF exists_count = 0 THEN
            RETURN code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 设置权限
-- ================================================================

-- 授予gccc_user用户所有权限
GRANT ALL PRIVILEGES ON DATABASE gccc_db TO gccc_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gccc_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gccc_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO gccc_user;

-- 设置默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO gccc_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO gccc_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO gccc_user;

-- 创建数据库注释
-- ================================================================

COMMENT ON DATABASE gccc_db IS 'GCCC DApp 主数据库';

-- 脚本完成日志
INSERT INTO pg_stat_statements_info (dealloc) VALUES (0)
ON CONFLICT DO NOTHING;

-- 输出完成信息
DO $$
BEGIN
    RAISE NOTICE '数据库初始化脚本执行完成';
    RAISE NOTICE '数据库名称: gccc_db';
    RAISE NOTICE '用户名称: gccc_user';
    RAISE NOTICE '扩展已安装: uuid-ossp, pgcrypto, btree_gin, pg_trgm';
    RAISE NOTICE '自定义类型和函数已创建';
END
$$;
