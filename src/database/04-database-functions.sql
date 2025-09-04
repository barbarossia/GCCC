-- ================================================================
-- GCCC 数据库函数和存储过程
-- 包含用户管理、积分系统、质押管理等业务逻辑函数
-- ================================================================

-- 用户注册函数
-- ================================================================
CREATE OR REPLACE FUNCTION register_user(
    p_wallet_address VARCHAR(44),
    p_signature VARCHAR(128),
    p_message TEXT,
    p_nonce VARCHAR(64),
    p_username VARCHAR(50) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_referral_code VARCHAR(10) DEFAULT NULL,
    p_device_info JSONB DEFAULT NULL
)
RETURNS TABLE(
    user_id BIGINT,
    user_uuid UUID,
    username VARCHAR(50),
    wallet_address VARCHAR(44),
    referral_code VARCHAR(10),
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_user_id BIGINT;
    v_user_uuid UUID;
    v_generated_username VARCHAR(50);
    v_referrer_id BIGINT;
    v_referral_bonus DECIMAL(20,8);
BEGIN
    -- 检查钱包地址是否已存在
    IF EXISTS (SELECT 1 FROM users WHERE users.wallet_address = p_wallet_address) THEN
        RETURN QUERY SELECT 
            NULL::BIGINT, NULL::UUID, NULL::VARCHAR(50), NULL::VARCHAR(44), 
            NULL::VARCHAR(10), FALSE, 'Wallet address already registered';
        RETURN;
    END IF;
    
    -- 检查用户名是否已存在（如果提供）
    IF p_username IS NOT NULL AND EXISTS (SELECT 1 FROM users WHERE users.username = p_username) THEN
        RETURN QUERY SELECT 
            NULL::BIGINT, NULL::UUID, NULL::VARCHAR(50), NULL::VARCHAR(44), 
            NULL::VARCHAR(10), FALSE, 'Username already taken';
        RETURN;
    END IF;
    
    -- 检查邮箱是否已存在（如果提供）
    IF p_email IS NOT NULL AND EXISTS (SELECT 1 FROM users WHERE users.email = p_email) THEN
        RETURN QUERY SELECT 
            NULL::BIGINT, NULL::UUID, NULL::VARCHAR(50), NULL::VARCHAR(44), 
            NULL::VARCHAR(10), FALSE, 'Email already registered';
        RETURN;
    END IF;
    
    -- 生成用户名（如果未提供）
    IF p_username IS NULL THEN
        v_generated_username := 'user_' || substring(p_wallet_address from 1 for 8);
        -- 确保用户名唯一
        WHILE EXISTS (SELECT 1 FROM users WHERE username = v_generated_username) LOOP
            v_generated_username := 'user_' || generate_random_string(8);
        END LOOP;
    ELSE
        v_generated_username := p_username;
    END IF;
    
    -- 验证推荐码（如果提供）
    IF p_referral_code IS NOT NULL THEN
        SELECT id INTO v_referrer_id 
        FROM users 
        WHERE users.referral_code = p_referral_code AND status = 'active';
        
        IF v_referrer_id IS NULL THEN
            RETURN QUERY SELECT 
                NULL::BIGINT, NULL::UUID, NULL::VARCHAR(50), NULL::VARCHAR(44), 
                NULL::VARCHAR(10), FALSE, 'Invalid referral code';
            RETURN;
        END IF;
    END IF;
    
    -- 创建用户
    INSERT INTO users (
        username, email, wallet_address, 
        status, wallet_verified, referred_by_user_id
    ) VALUES (
        v_generated_username, p_email, p_wallet_address,
        'active', TRUE, v_referrer_id
    ) RETURNING id, uuid INTO v_user_id, v_user_uuid;
    
    -- 创建钱包记录
    INSERT INTO user_wallets (
        user_id, wallet_address, signature_message,
        signature_hash, nonce, verified_at, is_primary
    ) VALUES (
        v_user_id, p_wallet_address, p_message,
        p_signature, p_nonce, CURRENT_TIMESTAMP, TRUE
    );
    
    -- 初始化用户积分
    INSERT INTO user_points (user_id) VALUES (v_user_id);
    
    -- 处理推荐奖励
    IF v_referrer_id IS NOT NULL THEN
        -- 获取推荐奖励配置
        SELECT COALESCE(config_value::DECIMAL, 100) INTO v_referral_bonus
        FROM system_configs 
        WHERE config_key = 'referral_bonus_points';
        
        -- 给推荐人奖励
        PERFORM add_points(v_referrer_id, v_referral_bonus, 'referral', 'Referral bonus');
        
        -- 给被推荐人奖励
        PERFORM add_points(v_user_id, v_referral_bonus * 0.5, 'referred', 'Welcome bonus');
        
        -- 更新推荐人的推荐计数
        UPDATE users SET referral_count = referral_count + 1 WHERE id = v_referrer_id;
        
        -- 记录推荐关系
        INSERT INTO referral_records (
            referrer_user_id, referee_user_id, referral_code,
            referrer_reward, referee_reward, status, activated_at
        ) VALUES (
            v_referrer_id, v_user_id, p_referral_code,
            v_referral_bonus, v_referral_bonus * 0.5, 'active', CURRENT_TIMESTAMP
        );
    END IF;
    
    -- 返回结果
    RETURN QUERY SELECT 
        v_user_id, v_user_uuid, v_generated_username, p_wallet_address,
        (SELECT users.referral_code FROM users WHERE id = v_user_id),
        TRUE, 'User registered successfully';
        
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT 
            NULL::BIGINT, NULL::UUID, NULL::VARCHAR(50), NULL::VARCHAR(44), 
            NULL::VARCHAR(10), FALSE, 'Registration failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 用户登录函数
-- ================================================================
CREATE OR REPLACE FUNCTION authenticate_user(
    p_wallet_address VARCHAR(44),
    p_signature VARCHAR(128),
    p_message TEXT,
    p_nonce VARCHAR(64),
    p_ip_address INET,
    p_user_agent TEXT DEFAULT NULL,
    p_device_info JSONB DEFAULT NULL
)
RETURNS TABLE(
    user_id BIGINT,
    user_uuid UUID,
    username VARCHAR(50),
    role user_role_enum,
    status user_status_enum,
    session_token UUID,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_user_id BIGINT;
    v_user_uuid UUID;
    v_username VARCHAR(50);
    v_role user_role_enum;
    v_status user_status_enum;
    v_session_id UUID;
    v_failed_attempts INTEGER;
    v_locked_until TIMESTAMP WITH TIME ZONE;
BEGIN
    -- 检查用户是否存在
    SELECT id, uuid, username, role, status, failed_login_attempts, locked_until
    INTO v_user_id, v_user_uuid, v_username, v_role, v_status, v_failed_attempts, v_locked_until
    FROM users WHERE wallet_address = p_wallet_address;
    
    IF v_user_id IS NULL THEN
        RETURN QUERY SELECT 
            NULL::BIGINT, NULL::UUID, NULL::VARCHAR(50), NULL::user_role_enum, 
            NULL::user_status_enum, NULL::UUID, FALSE, 'User not found';
        RETURN;
    END IF;
    
    -- 检查账户状态
    IF v_status IN ('suspended', 'banned') THEN
        RETURN QUERY SELECT 
            v_user_id, v_user_uuid, v_username, v_role, v_status, NULL::UUID,
            FALSE, 'Account is ' || v_status::TEXT;
        RETURN;
    END IF;
    
    -- 检查账户锁定状态
    IF v_locked_until IS NOT NULL AND v_locked_until > CURRENT_TIMESTAMP THEN
        RETURN QUERY SELECT 
            v_user_id, v_user_uuid, v_username, v_role, v_status, NULL::UUID,
            FALSE, 'Account is temporarily locked';
        RETURN;
    END IF;
    
    -- 这里应该验证签名，简化处理假设验证通过
    -- 实际实现中需要使用 Solana 签名验证
    
    -- 创建会话
    INSERT INTO user_sessions (
        user_id, token_hash, device_info, ip_address, user_agent,
        expires_at
    ) VALUES (
        v_user_id, 
        encode(digest(generate_random_string(64), 'sha256'), 'hex'),
        p_device_info, p_ip_address, p_user_agent,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING id INTO v_session_id;
    
    -- 更新用户登录信息
    UPDATE users SET 
        login_count = login_count + 1,
        last_login_at = CURRENT_TIMESTAMP,
        last_login_ip = p_ip_address,
        failed_login_attempts = 0,
        locked_until = NULL
    WHERE id = v_user_id;
    
    -- 清理过期会话
    DELETE FROM user_sessions 
    WHERE user_id = v_user_id AND expires_at < CURRENT_TIMESTAMP;
    
    -- 返回成功结果
    RETURN QUERY SELECT 
        v_user_id, v_user_uuid, v_username, v_role, v_status, v_session_id,
        TRUE, 'Login successful';
        
EXCEPTION
    WHEN OTHERS THEN
        -- 记录失败尝试
        UPDATE users SET 
            failed_login_attempts = failed_login_attempts + 1,
            locked_until = CASE 
                WHEN failed_login_attempts >= 4 THEN CURRENT_TIMESTAMP + INTERVAL '15 minutes'
                ELSE NULL 
            END
        WHERE wallet_address = p_wallet_address;
        
        RETURN QUERY SELECT 
            NULL::BIGINT, NULL::UUID, NULL::VARCHAR(50), NULL::user_role_enum, 
            NULL::user_status_enum, NULL::UUID, FALSE, 'Authentication failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 积分管理函数
-- ================================================================
CREATE OR REPLACE FUNCTION add_points(
    p_user_id BIGINT,
    p_amount DECIMAL(20,8),
    p_transaction_type VARCHAR(50),
    p_description TEXT DEFAULT NULL,
    p_reference_type VARCHAR(50) DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_balance DECIMAL(20,8);
    v_new_balance DECIMAL(20,8);
BEGIN
    -- 获取当前余额
    SELECT points_balance INTO v_current_balance
    FROM user_points WHERE user_id = p_user_id;
    
    IF v_current_balance IS NULL THEN
        -- 如果用户积分记录不存在，创建一个
        INSERT INTO user_points (user_id, points_balance) VALUES (p_user_id, 0);
        v_current_balance := 0;
    END IF;
    
    v_new_balance := v_current_balance + p_amount;
    
    -- 更新积分余额
    UPDATE user_points SET 
        points_balance = v_new_balance,
        lifetime_earned = lifetime_earned + GREATEST(p_amount, 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;
    
    -- 记录积分交易
    INSERT INTO points_transactions (
        user_id, transaction_type, amount, balance_before, balance_after,
        description, reference_type, reference_id
    ) VALUES (
        p_user_id, p_transaction_type, p_amount, v_current_balance, v_new_balance,
        p_description, p_reference_type, p_reference_id
    );
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 扣除积分函数
-- ================================================================
CREATE OR REPLACE FUNCTION deduct_points(
    p_user_id BIGINT,
    p_amount DECIMAL(20,8),
    p_transaction_type VARCHAR(50),
    p_description TEXT DEFAULT NULL,
    p_reference_type VARCHAR(50) DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_balance DECIMAL(20,8);
    v_new_balance DECIMAL(20,8);
BEGIN
    -- 获取当前余额
    SELECT points_balance INTO v_current_balance
    FROM user_points WHERE user_id = p_user_id;
    
    IF v_current_balance IS NULL OR v_current_balance < p_amount THEN
        RETURN FALSE; -- 余额不足
    END IF;
    
    v_new_balance := v_current_balance - p_amount;
    
    -- 更新积分余额
    UPDATE user_points SET 
        points_balance = v_new_balance,
        lifetime_spent = lifetime_spent + p_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;
    
    -- 记录积分交易
    INSERT INTO points_transactions (
        user_id, transaction_type, amount, balance_before, balance_after,
        description, reference_type, reference_id
    ) VALUES (
        p_user_id, p_transaction_type, -p_amount, v_current_balance, v_new_balance,
        p_description, p_reference_type, p_reference_id
    );
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 每日签到函数
-- ================================================================
CREATE OR REPLACE FUNCTION daily_checkin(
    p_user_id BIGINT,
    p_checkin_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    success BOOLEAN,
    points_earned DECIMAL(20,8),
    consecutive_days INTEGER,
    message TEXT
) AS $$
DECLARE
    v_last_checkin_date DATE;
    v_consecutive_days INTEGER := 1;
    v_base_points DECIMAL(20,8);
    v_bonus_multiplier DECIMAL(3,2) := 1.0;
    v_points_earned DECIMAL(20,8);
    v_special_reward JSONB;
BEGIN
    -- 检查今天是否已签到
    IF EXISTS (SELECT 1 FROM daily_checkins WHERE user_id = p_user_id AND checkin_date = p_checkin_date) THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL(20,8), 0, 'Already checked in today';
        RETURN;
    END IF;
    
    -- 获取基础签到积分
    SELECT COALESCE(config_value::DECIMAL, 10) INTO v_base_points
    FROM system_configs WHERE config_key = 'daily_checkin_points';
    
    -- 获取最后签到日期和连续天数
    SELECT checkin_date, consecutive_days 
    INTO v_last_checkin_date, v_consecutive_days
    FROM daily_checkins 
    WHERE user_id = p_user_id 
    ORDER BY checkin_date DESC 
    LIMIT 1;
    
    -- 计算连续签到天数
    IF v_last_checkin_date IS NOT NULL THEN
        IF p_checkin_date = v_last_checkin_date + INTERVAL '1 day' THEN
            v_consecutive_days := v_consecutive_days + 1;
        ELSE
            v_consecutive_days := 1; -- 重新开始计算
        END IF;
    END IF;
    
    -- 计算奖励倍数（连续签到奖励）
    CASE 
        WHEN v_consecutive_days >= 30 THEN v_bonus_multiplier := 3.0;
        WHEN v_consecutive_days >= 14 THEN v_bonus_multiplier := 2.5;
        WHEN v_consecutive_days >= 7 THEN v_bonus_multiplier := 2.0;
        WHEN v_consecutive_days >= 3 THEN v_bonus_multiplier := 1.5;
        ELSE v_bonus_multiplier := 1.0;
    END CASE;
    
    v_points_earned := v_base_points * v_bonus_multiplier;
    
    -- 特殊奖励（每7天、30天等）
    IF v_consecutive_days % 30 = 0 THEN
        v_special_reward := jsonb_build_object('type', 'monthly_bonus', 'value', 'Special NFT');
    ELSIF v_consecutive_days % 7 = 0 THEN
        v_special_reward := jsonb_build_object('type', 'weekly_bonus', 'value', 'Extra points');
        v_points_earned := v_points_earned + 50;
    END IF;
    
    -- 记录签到
    INSERT INTO daily_checkins (
        user_id, checkin_date, points_earned, consecutive_days,
        bonus_multiplier, special_reward
    ) VALUES (
        p_user_id, p_checkin_date, v_points_earned, v_consecutive_days,
        v_bonus_multiplier, v_special_reward
    );
    
    -- 添加积分
    PERFORM add_points(p_user_id, v_points_earned, 'daily_checkin', 
                      'Daily check-in reward (Day ' || v_consecutive_days || ')');
    
    RETURN QUERY SELECT TRUE, v_points_earned, v_consecutive_days, 'Check-in successful';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, 0::DECIMAL(20,8), 0, 'Check-in failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 创建提案函数
-- ================================================================
CREATE OR REPLACE FUNCTION create_proposal(
    p_proposer_user_id BIGINT,
    p_title VARCHAR(200),
    p_description TEXT,
    p_content TEXT DEFAULT NULL,
    p_category VARCHAR(50) DEFAULT 'general',
    p_voting_start_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_voting_end_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_min_voting_power DECIMAL(20,8) DEFAULT 0,
    p_quorum_threshold DECIMAL(5,2) DEFAULT 10.0,
    p_pass_threshold DECIMAL(5,2) DEFAULT 50.0,
    p_metadata JSONB DEFAULT NULL
)
RETURNS TABLE(
    proposal_id BIGINT,
    proposal_uuid UUID,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_proposal_id BIGINT;
    v_proposal_uuid UUID;
    v_proposer_wallet VARCHAR(44);
    v_user_role user_role_enum;
    v_voting_start TIMESTAMP WITH TIME ZONE;
    v_voting_end TIMESTAMP WITH TIME ZONE;
    v_creation_fee DECIMAL(20,8);
BEGIN
    -- 检查用户权限
    SELECT wallet_address, role INTO v_proposer_wallet, v_user_role
    FROM users WHERE id = p_proposer_user_id AND status = 'active';
    
    IF v_proposer_wallet IS NULL THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::UUID, FALSE, 'User not found or inactive';
        RETURN;
    END IF;
    
    -- 设置默认投票时间
    v_voting_start := COALESCE(p_voting_start_at, CURRENT_TIMESTAMP + INTERVAL '1 hour');
    v_voting_end := COALESCE(p_voting_end_at, v_voting_start + INTERVAL '7 days');
    
    -- 检查投票时间
    IF v_voting_end <= v_voting_start THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::UUID, FALSE, 'Invalid voting time range';
        RETURN;
    END IF;
    
    -- 获取提案创建费用
    SELECT COALESCE(config_value::DECIMAL, 50) INTO v_creation_fee
    FROM system_configs WHERE config_key = 'proposal_creation_fee';
    
    -- 检查并扣除创建费用
    IF NOT deduct_points(p_proposer_user_id, v_creation_fee, 'proposal_creation', 
                        'Proposal creation fee') THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::UUID, FALSE, 'Insufficient points for proposal creation';
        RETURN;
    END IF;
    
    -- 创建提案
    INSERT INTO proposals (
        title, description, content, category,
        proposer_user_id, proposer_wallet,
        voting_start_at, voting_end_at,
        min_voting_power, quorum_threshold, pass_threshold,
        status, metadata
    ) VALUES (
        p_title, p_description, p_content, p_category,
        p_proposer_user_id, v_proposer_wallet,
        v_voting_start, v_voting_end,
        p_min_voting_power, p_quorum_threshold, p_pass_threshold,
        'draft', p_metadata
    ) RETURNING id, uuid INTO v_proposal_id, v_proposal_uuid;
    
    -- 给提案者奖励积分
    PERFORM add_points(p_proposer_user_id, 
                      (SELECT COALESCE(config_value::DECIMAL, 50) 
                       FROM system_configs WHERE config_key = 'proposal_create_reward'),
                      'proposal_reward', 'Proposal creation reward',
                      'proposal', v_proposal_uuid);
    
    RETURN QUERY SELECT v_proposal_id, v_proposal_uuid, TRUE, 'Proposal created successfully';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::UUID, FALSE, 'Proposal creation failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 投票函数
-- ================================================================
CREATE OR REPLACE FUNCTION cast_vote(
    p_user_id BIGINT,
    p_proposal_id BIGINT,
    p_vote_option vote_option_enum,
    p_voting_power DECIMAL(20,8) DEFAULT NULL,
    p_signature VARCHAR(128) DEFAULT NULL,
    p_message TEXT DEFAULT NULL,
    p_comment TEXT DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_proposal_status proposal_status_enum;
    v_voting_start TIMESTAMP WITH TIME ZONE;
    v_voting_end TIMESTAMP WITH TIME ZONE;
    v_user_wallet VARCHAR(44);
    v_calculated_power DECIMAL(20,8);
    v_points_reward DECIMAL(20,8);
BEGIN
    -- 检查提案状态和投票时间
    SELECT status, voting_start_at, voting_end_at
    INTO v_proposal_status, v_voting_start, v_voting_end
    FROM proposals WHERE id = p_proposal_id;
    
    IF v_proposal_status IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Proposal not found';
        RETURN;
    END IF;
    
    IF v_proposal_status != 'active' THEN
        RETURN QUERY SELECT FALSE, 'Proposal is not active for voting';
        RETURN;
    END IF;
    
    IF CURRENT_TIMESTAMP < v_voting_start OR CURRENT_TIMESTAMP > v_voting_end THEN
        RETURN QUERY SELECT FALSE, 'Voting period has not started or has ended';
        RETURN;
    END IF;
    
    -- 检查是否已投票
    IF EXISTS (SELECT 1 FROM votes WHERE proposal_id = p_proposal_id AND user_id = p_user_id) THEN
        RETURN QUERY SELECT FALSE, 'Already voted on this proposal';
        RETURN;
    END IF;
    
    -- 获取用户钱包地址
    SELECT wallet_address INTO v_user_wallet
    FROM users WHERE id = p_user_id AND status = 'active';
    
    IF v_user_wallet IS NULL THEN
        RETURN QUERY SELECT FALSE, 'User not found or inactive';
        RETURN;
    END IF;
    
    -- 计算投票权重（基于质押金额等）
    v_calculated_power := COALESCE(p_voting_power, 1.0);
    
    -- 记录投票
    INSERT INTO votes (
        proposal_id, user_id, vote_option, voting_power,
        wallet_address, signature, message, comment
    ) VALUES (
        p_proposal_id, p_user_id, p_vote_option, v_calculated_power,
        v_user_wallet, p_signature, p_message, p_comment
    );
    
    -- 更新提案投票统计
    UPDATE proposals SET 
        total_votes_count = total_votes_count + 1,
        yes_votes_count = CASE WHEN p_vote_option = 'yes' THEN yes_votes_count + 1 ELSE yes_votes_count END,
        no_votes_count = CASE WHEN p_vote_option = 'no' THEN no_votes_count + 1 ELSE no_votes_count END,
        abstain_votes_count = CASE WHEN p_vote_option = 'abstain' THEN abstain_votes_count + 1 ELSE abstain_votes_count END,
        total_voting_power = total_voting_power + v_calculated_power,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_proposal_id;
    
    -- 给投票者奖励积分
    SELECT COALESCE(config_value::DECIMAL, 5) INTO v_points_reward
    FROM system_configs WHERE config_key = 'vote_reward_points';
    
    PERFORM add_points(p_user_id, v_points_reward, 'vote_reward', 
                      'Voting participation reward', 'proposal', p_proposal_id::UUID);
    
    RETURN QUERY SELECT TRUE, 'Vote cast successfully';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, 'Vote casting failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 动态创建管理员函数
-- ================================================================
CREATE OR REPLACE FUNCTION create_admin_user(
    p_wallet_address VARCHAR(44),
    p_username VARCHAR(50),
    p_email VARCHAR(255),
    p_role user_role_enum DEFAULT 'admin',
    p_created_by_user_id BIGINT DEFAULT NULL
)
RETURNS TABLE(
    user_id BIGINT,
    username VARCHAR(50),
    role user_role_enum,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_user_id BIGINT;
    v_creator_role user_role_enum;
BEGIN
    -- 检查创建者权限（如果提供）
    IF p_created_by_user_id IS NOT NULL THEN
        SELECT role INTO v_creator_role
        FROM users WHERE id = p_created_by_user_id AND status = 'active';
        
        IF v_creator_role IS NULL THEN
            RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR(50), NULL::user_role_enum, 
                        FALSE, 'Creator user not found';
            RETURN;
        END IF;
        
        -- 检查权限层级
        IF NOT has_permission(v_creator_role, p_role) THEN
            RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR(50), NULL::user_role_enum, 
                        FALSE, 'Insufficient permissions to create this role';
            RETURN;
        END IF;
    END IF;
    
    -- 检查钱包地址是否已存在
    IF EXISTS (SELECT 1 FROM users WHERE wallet_address = p_wallet_address) THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR(50), NULL::user_role_enum, 
                    FALSE, 'Wallet address already registered';
        RETURN;
    END IF;
    
    -- 检查用户名是否已存在
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR(50), NULL::user_role_enum, 
                    FALSE, 'Username already taken';
        RETURN;
    END IF;
    
    -- 创建管理员用户
    INSERT INTO users (
        username, email, wallet_address, role, status,
        wallet_verified, email_verified
    ) VALUES (
        p_username, p_email, p_wallet_address, p_role, 'active',
        TRUE, TRUE
    ) RETURNING id INTO v_user_id;
    
    -- 创建钱包记录
    INSERT INTO user_wallets (
        user_id, wallet_address, verified_at, is_primary
    ) VALUES (
        v_user_id, p_wallet_address, CURRENT_TIMESTAMP, TRUE
    );
    
    -- 初始化积分
    INSERT INTO user_points (user_id) VALUES (v_user_id);
    
    -- 记录审计日志
    INSERT INTO audit_logs (
        action, table_name, record_id, user_id,
        new_values, description
    ) VALUES (
        'create', 'users', v_user_id::TEXT, p_created_by_user_id,
        jsonb_build_object('role', p_role, 'username', p_username),
        'Admin user created: ' || p_username || ' (' || p_role || ')'
    );
    
    RETURN QUERY SELECT v_user_id, p_username, p_role, TRUE, 'Admin user created successfully';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR(50), NULL::user_role_enum, 
                    FALSE, 'Admin creation failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 初始化第一个管理员函数
-- ================================================================
CREATE OR REPLACE FUNCTION initialize_first_admin(
    p_wallet_address VARCHAR(44),
    p_username VARCHAR(50) DEFAULT 'admin',
    p_email VARCHAR(255) DEFAULT 'admin@gccc.com'
)
RETURNS TABLE(
    user_id BIGINT,
    username VARCHAR(50),
    role user_role_enum,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_admin_count INTEGER;
BEGIN
    -- 检查是否已有管理员
    SELECT COUNT(*) INTO v_admin_count
    FROM users WHERE role IN ('admin', 'super_admin') AND status = 'active';
    
    IF v_admin_count > 0 THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR(50), NULL::user_role_enum, 
                    FALSE, 'Admin users already exist';
        RETURN;
    END IF;
    
    -- 创建第一个超级管理员
    RETURN QUERY SELECT * FROM create_admin_user(
        p_wallet_address, p_username, p_email, 'super_admin'::user_role_enum, NULL
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR(50), NULL::user_role_enum, 
                    FALSE, 'First admin initialization failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 获取用户统计函数
-- ================================================================
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id BIGINT)
RETURNS TABLE(
    points_balance DECIMAL(20,8),
    lifetime_earned DECIMAL(20,8),
    lifetime_spent DECIMAL(20,8),
    referral_count INTEGER,
    proposals_created INTEGER,
    votes_cast INTEGER,
    stakes_active INTEGER,
    nfts_owned INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(up.points_balance, 0),
        COALESCE(up.lifetime_earned, 0),
        COALESCE(up.lifetime_spent, 0),
        COALESCE(u.referral_count, 0),
        COALESCE(proposal_count.count, 0)::INTEGER,
        COALESCE(vote_count.count, 0)::INTEGER,
        COALESCE(stake_count.count, 0)::INTEGER,
        COALESCE(nft_count.count, 0)::INTEGER
    FROM users u
    LEFT JOIN user_points up ON u.id = up.user_id
    LEFT JOIN (
        SELECT proposer_user_id, COUNT(*) as count 
        FROM proposals 
        WHERE proposer_user_id = p_user_id 
        GROUP BY proposer_user_id
    ) proposal_count ON u.id = proposal_count.proposer_user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) as count 
        FROM votes 
        WHERE user_id = p_user_id 
        GROUP BY user_id
    ) vote_count ON u.id = vote_count.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) as count 
        FROM user_stakes 
        WHERE user_id = p_user_id AND status = 'active'
        GROUP BY user_id
    ) stake_count ON u.id = stake_count.user_id
    LEFT JOIN (
        SELECT owner_user_id, COUNT(*) as count 
        FROM nfts 
        WHERE owner_user_id = p_user_id AND status = 'active'
        GROUP BY owner_user_id
    ) nft_count ON u.id = nft_count.owner_user_id
    WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- 系统统计函数
-- ================================================================
CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE(
    total_users INTEGER,
    active_users INTEGER,
    total_proposals INTEGER,
    active_proposals INTEGER,
    total_votes INTEGER,
    total_stakes DECIMAL(20,8),
    total_nfts INTEGER,
    total_lottery_tickets INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM users),
        (SELECT COUNT(*)::INTEGER FROM users WHERE status = 'active'),
        (SELECT COUNT(*)::INTEGER FROM proposals),
        (SELECT COUNT(*)::INTEGER FROM proposals WHERE status = 'active'),
        (SELECT COUNT(*)::INTEGER FROM votes),
        (SELECT COALESCE(SUM(stake_amount), 0) FROM user_stakes WHERE status = 'active'),
        (SELECT COUNT(*)::INTEGER FROM nfts WHERE status = 'active'),
        (SELECT COUNT(*)::INTEGER FROM lottery_tickets);
END;
$$ LANGUAGE plpgsql;

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '数据库函数和存储过程创建完成';
    RAISE NOTICE '已创建函数: register_user, authenticate_user';
    RAISE NOTICE '已创建函数: add_points, deduct_points, daily_checkin';
    RAISE NOTICE '已创建函数: create_proposal, cast_vote';
    RAISE NOTICE '已创建函数: create_admin_user, initialize_first_admin';
    RAISE NOTICE '已创建函数: get_user_stats, get_system_stats';
END
$$;
