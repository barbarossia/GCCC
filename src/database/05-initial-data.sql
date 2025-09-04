-- ================================================================
-- GCCC 初始数据插入脚本
-- 包含系统配置、默认角色权限、测试数据等
-- ================================================================

-- 系统配置数据
-- ================================================================
INSERT INTO system_configs (config_key, config_value, config_type, description, category, is_public) VALUES
-- 用户系统配置
('user_registration_enabled', 'true', 'boolean', '是否允许用户注册', 'user', true),
('email_verification_required', 'false', 'boolean', '是否需要邮箱验证', 'user', true),
('max_devices_per_user', '5', 'number', '每个用户最大设备数量', 'user', false),
('user_inactive_days', '90', 'number', '用户非活跃天数', 'user', false),
('max_login_attempts', '5', 'number', '最大登录尝试次数', 'security', false),
('account_lockout_duration', '900', 'number', '账户锁定时长（秒）', 'security', false),

-- 积分系统配置
('daily_checkin_points', '10', 'number', '每日签到基础积分', 'points', true),
('referral_bonus_points', '100', 'number', '推荐奖励积分', 'points', true),
('proposal_creation_fee', '50', 'number', '创建提案费用', 'points', true),
('proposal_create_reward', '50', 'number', '创建提案奖励', 'points', true),
('vote_reward_points', '5', 'number', '投票奖励积分', 'points', true),
('points_to_level_ratio', '1000', 'number', '升级所需积分比例', 'points', true),

-- 质押系统配置
('staking_min_amount', '100', 'number', '最小质押金额', 'staking', true),
('staking_max_amount', '1000000', 'number', '最大质押金额', 'staking', true),
('staking_lock_periods', '7,30,90,365', 'array', '质押锁定期（天）', 'staking', true),
('staking_apy_rates', '5,8,12,20', 'array', '质押年化收益率（%）', 'staking', true),
('early_unstake_penalty', '10', 'number', '提前解质押罚金（%）', 'staking', true),

-- 提案系统配置
('proposal_voting_duration', '7', 'number', '提案投票持续时间（天）', 'proposal', true),
('proposal_min_quorum', '10', 'number', '提案最小参与率（%）', 'proposal', true),
('proposal_pass_threshold', '50', 'number', '提案通过阈值（%）', 'proposal', true),
('proposal_execution_delay', '24', 'number', '提案执行延迟（小时）', 'proposal', true),

-- 抽奖系统配置
('lottery_ticket_price', '10', 'number', '抽奖票价格', 'lottery', true),
('lottery_max_tickets_per_user', '100', 'number', '每用户最大购票数', 'lottery', true),
('lottery_draw_interval', '7', 'number', '抽奖间隔（天）', 'lottery', true),
('lottery_prize_distribution', '{"first": 50, "second": 30, "third": 20}', 'json', '奖金分配比例', 'lottery', true),

-- NFT系统配置
('nft_mint_price', '0.1', 'number', 'NFT铸造价格（SOL）', 'nft', true),
('nft_max_supply', '10000', 'number', 'NFT最大供应量', 'nft', true),
('nft_royalty_percentage', '2.5', 'number', 'NFT版税比例（%）', 'nft', true),
('nft_marketplace_fee', '2.5', 'number', '市场交易费（%）', 'nft', true),

-- 区块链配置
('solana_network', 'devnet', 'string', 'Solana网络环境', 'blockchain', true),
('solana_rpc_url', 'https://api.devnet.solana.com', 'string', 'Solana RPC地址', 'blockchain', false),
('gccc_token_mint', 'YourTokenMintAddressHere44Characters', 'string', 'GCCC代币地址', 'blockchain', true),
('treasury_wallet', 'YourTreasuryWalletAddressHere44Characters', 'string', '国库钱包地址', 'blockchain', false),

-- API配置
('api_rate_limit_requests', '100', 'number', 'API频率限制（每15分钟）', 'api', false),
('api_rate_limit_window', '900', 'number', 'API限制时间窗口（秒）', 'api', false),
('max_request_size', '10485760', 'number', '最大请求大小（字节）', 'api', false),
('max_file_upload_size', '5242880', 'number', '最大文件上传大小（字节）', 'api', false),

-- 安全配置
('jwt_expire_hours', '168', 'number', 'JWT过期时间（小时）', 'security', false),
('refresh_token_expire_days', '30', 'number', '刷新令牌过期天数', 'security', false),
('password_hash_rounds', '12', 'number', '密码哈希轮数', 'security', false),
('session_max_duration', '86400', 'number', '会话最长时间（秒）', 'security', false),

-- 通知配置
('notification_enabled', 'true', 'boolean', '是否启用通知', 'notification', true),
('email_notification_enabled', 'false', 'boolean', '是否启用邮件通知', 'notification', true),
('discord_notification_enabled', 'false', 'boolean', '是否启用Discord通知', 'notification', true),

-- 维护配置
('maintenance_mode', 'false', 'boolean', '维护模式', 'system', true),
('maintenance_message', 'System is under maintenance', 'string', '维护提示消息', 'system', true),
('backup_enabled', 'true', 'boolean', '是否启用备份', 'system', false),
('log_retention_days', '30', 'number', '日志保留天数', 'system', false);

-- 默认质押池数据
-- ================================================================
INSERT INTO staking_pools (
    name, description, token_mint, min_stake_amount, max_stake_amount,
    lock_period_days, apy_rate, max_total_stake, reward_token_mint,
    is_active, is_public, metadata
) VALUES
-- 短期质押池（7天）
(
    'GCCC Short-Term Staking',
    '7天短期质押，低风险稳定收益',
    'YourTokenMintAddressHere44Characters',
    100, 50000, 7, 5.0, 1000000,
    'YourTokenMintAddressHere44Characters',
    true, true,
    '{"risk_level": "low", "features": ["flexible", "quick_access"]}'
),

-- 中期质押池（30天）
(
    'GCCC Medium-Term Staking',
    '30天中期质押，平衡收益与风险',
    'YourTokenMintAddressHere44Characters',
    500, 100000, 30, 8.0, 2000000,
    'YourTokenMintAddressHere44Characters',
    true, true,
    '{"risk_level": "medium", "features": ["balanced", "moderate_rewards"]}'
),

-- 长期质押池（90天）
(
    'GCCC Long-Term Staking',
    '90天长期质押，高收益回报',
    'YourTokenMintAddressHere44Characters',
    1000, 200000, 90, 12.0, 5000000,
    'YourTokenMintAddressHere44Characters',
    true, true,
    '{"risk_level": "medium", "features": ["high_yield", "long_commitment"]}'
),

-- 超长期质押池（365天）
(
    'GCCC Ultra Long-Term Staking',
    '365天超长期质押，最高收益回报',
    'YourTokenMintAddressHere44Characters',
    5000, 500000, 365, 20.0, 10000000,
    'YourTokenMintAddressHere44Characters',
    true, true,
    '{"risk_level": "high", "features": ["maximum_yield", "annual_commitment", "exclusive_benefits"]}'
);

-- 默认NFT集合数据
-- ================================================================
INSERT INTO nft_collections (
    name, symbol, description, creator_wallet, max_supply,
    mint_price, royalty_percentage, base_uri, is_public,
    launch_date, mint_start_date, mint_end_date, status, metadata
) VALUES
-- GCCC创世NFT集合
(
    'GCCC Genesis Collection',
    'GCCCGEN',
    'GCCC平台限量创世纪念NFT，拥有特殊治理权益和空投权利',
    'YourCreatorWalletAddressHere44Characters',
    1000, 0.5, 5.0,
    'https://api.gccc.com/metadata/genesis/',
    true,
    '2024-01-01 00:00:00+00',
    '2024-01-15 00:00:00+00',
    '2024-02-15 00:00:00+00',
    'active',
    '{"type": "genesis", "benefits": ["governance_boost", "airdrop_priority", "exclusive_access"], "rarity_tiers": ["common", "rare", "epic", "legendary"]}'
),

-- GCCC治理NFT集合
(
    'GCCC Governance Council',
    'GCCCGOV',
    '治理委员会NFT，持有者享有提案优先权和投票权重加成',
    'YourCreatorWalletAddressHere44Characters',
    500, 1.0, 7.5,
    'https://api.gccc.com/metadata/governance/',
    true,
    '2024-02-01 00:00:00+00',
    '2024-02-15 00:00:00+00',
    '2024-03-15 00:00:00+00',
    'active',
    '{"type": "governance", "benefits": ["proposal_priority", "voting_boost", "council_access"], "voting_multiplier": 2.0}'
),

-- GCCC节庆NFT集合
(
    'GCCC Festival Collection',
    'GCCCFEST',
    '节庆主题NFT集合，不定期发布的限量纪念版本',
    'YourCreatorWalletAddressHere44Characters',
    2500, 0.2, 2.5,
    'https://api.gccc.com/metadata/festival/',
    true,
    '2024-03-01 00:00:00+00',
    '2024-03-15 00:00:00+00',
    '2024-04-15 00:00:00+00',
    'active',
    '{"type": "festival", "themes": ["spring", "summer", "autumn", "winter"], "limited_edition": true}'
);

-- 示例抽奖数据
-- ================================================================
INSERT INTO lotteries (
    title, description, lottery_type, ticket_price, max_tickets_per_user,
    max_total_tickets, prize_pool, start_time, end_time, draw_time,
    status, prize_distribution, metadata
) VALUES
-- 每周常规抽奖
(
    'GCCC Weekly Lottery #1',
    '每周定期举行的常规抽奖活动，奖池丰厚，人人有机会',
    'weekly_regular',
    10, 50, 10000, 50000,
    '2024-01-15 00:00:00+00',
    '2024-01-21 23:59:59+00',
    '2024-01-22 12:00:00+00',
    'upcoming',
    '{"first_prize": {"percentage": 50, "amount": 25000}, "second_prize": {"percentage": 30, "amount": 15000}, "third_prize": {"percentage": 20, "amount": 10000}}',
    '{"type": "regular", "frequency": "weekly", "auto_distribute": true}'
),

-- 月度大奖抽奖
(
    'GCCC Monthly Mega Lottery',
    '月度超级大奖抽奖，包含代币奖励、NFT和独家权益',
    'monthly_mega',
    25, 100, 20000, 200000,
    '2024-01-01 00:00:00+00',
    '2024-01-31 23:59:59+00',
    '2024-02-01 20:00:00+00',
    'upcoming',
    '{"grand_prize": {"percentage": 40, "amount": 80000}, "major_prize": {"percentage": 25, "amount": 50000}, "minor_prizes": {"percentage": 35, "amount": 70000}}',
    '{"type": "mega", "frequency": "monthly", "special_rewards": ["exclusive_nft", "governance_tokens", "platform_benefits"]}'
);

-- 示例提案数据
-- ================================================================

-- 首先需要有一个提案创建者，这里先插入一个示例用户
INSERT INTO users (
    username, email, wallet_address, role, status,
    wallet_verified, email_verified, referral_code
) VALUES (
    'demo_user',
    'demo@gccc.com',
    'DemoUserWalletAddress12345678901234567890',
    'user',
    'active',
    true,
    true,
    'DEMO01'
);

-- 获取刚插入的用户ID
-- 注意：在实际应用中，应该使用具体的用户ID

-- 插入示例提案
INSERT INTO proposals (
    title, description, content, category, proposer_user_id, proposer_wallet,
    voting_start_at, voting_end_at, min_voting_power, quorum_threshold,
    pass_threshold, status, metadata, tags
) VALUES
-- 治理提案
(
    'GCCC治理代币经济模型优化提案',
    '提议优化GCCC代币的经济模型，包括通胀率调整、质押奖励机制改进和代币分配优化',
    '## 提案背景\n\n当前GCCC代币经济模型在运行中发现了一些可以优化的地方...\n\n## 具体提案内容\n\n1. 调整年通胀率从5%降至3%\n2. 提高质押奖励基础APY\n3. 优化代币分配机制\n\n## 预期影响\n\n此提案将有助于...',
    'governance',
    (SELECT id FROM users WHERE username = 'demo_user'),
    'DemoUserWalletAddress12345678901234567890',
    CURRENT_TIMESTAMP + INTERVAL '1 hour',
    CURRENT_TIMESTAMP + INTERVAL '8 days',
    100, 15.0, 60.0, 'draft',
    '{"proposal_type": "economic_model", "impact_level": "high", "implementation_complexity": "medium"}',
    ARRAY['governance', 'tokenomics', 'staking', 'economics']
),

-- 技术提案
(
    'GCCC平台Layer 2集成提案',
    '提议将GCCC平台集成Layer 2解决方案，以降低交易费用并提高处理速度',
    '## 提案概述\n\n随着平台用户增长，当前Solana主网的性能已接近瓶颈...\n\n## 技术方案\n\n1. 集成Solana Layer 2方案\n2. 优化智能合约架构\n3. 改进用户交互体验\n\n## 实施计划\n\n第一阶段：技术评估...',
    'technical',
    (SELECT id FROM users WHERE username = 'demo_user'),
    'DemoUserWalletAddress12345678901234567890',
    CURRENT_TIMESTAMP + INTERVAL '2 hours',
    CURRENT_TIMESTAMP + INTERVAL '10 days',
    500, 20.0, 55.0, 'draft',
    '{"proposal_type": "technical_upgrade", "impact_level": "high", "implementation_complexity": "high", "estimated_duration": "3_months"}',
    ARRAY['technical', 'layer2', 'scalability', 'performance']
),

-- 社区提案
(
    'GCCC社区激励计划升级提案',
    '提议升级现有的社区激励计划，增加更多参与方式和奖励机制',
    '## 当前状况\n\n现有激励计划运行良好，但参与方式相对单一...\n\n## 升级内容\n\n1. 新增内容创作奖励\n2. 增设社区贡献者等级\n3. 引入推荐人长期奖励\n4. 建立社区治理基金\n\n## 预算需求\n\n总预算：100,000 GCCC代币...',
    'community',
    (SELECT id FROM users WHERE username = 'demo_user'),
    'DemoUserWalletAddress12345678901234567890',
    CURRENT_TIMESTAMP + INTERVAL '3 hours',
    CURRENT_TIMESTAMP + INTERVAL '7 days',
    50, 10.0, 50.0, 'draft',
    '{"proposal_type": "community_program", "impact_level": "medium", "budget_required": "100000", "target_participants": "1000"}',
    ARRAY['community', 'incentives', 'rewards', 'engagement']
);

-- 初始化用户积分
INSERT INTO user_points (user_id, points_balance, lifetime_earned) 
SELECT id, 1000, 1000 FROM users WHERE username = 'demo_user';

-- 用户权限配置数据
-- ================================================================

-- 为演示用户添加一些基本权限
INSERT INTO user_permissions (user_id, permission_name, permission_value, resource_type, granted_reason) 
SELECT 
    u.id, 
    perm.permission_name,
    true,
    perm.resource_type,
    'Default user permissions'
FROM users u
CROSS JOIN (
    VALUES 
        ('view_proposals', 'proposal'),
        ('create_proposal', 'proposal'),
        ('cast_vote', 'proposal'),
        ('daily_checkin', 'points'),
        ('view_staking_pools', 'staking'),
        ('create_stake', 'staking'),
        ('view_lottery', 'lottery'),
        ('buy_lottery_ticket', 'lottery'),
        ('view_nft_collections', 'nft'),
        ('mint_nft', 'nft')
) AS perm(permission_name, resource_type)
WHERE u.username = 'demo_user';

-- 创建一些初始的每日签到数据
INSERT INTO daily_checkins (user_id, checkin_date, points_earned, consecutive_days, bonus_multiplier)
SELECT 
    u.id,
    CURRENT_DATE - INTERVAL '1 day' * generate_series(1, 5),
    10 + (generate_series(1, 5) - 1) * 2,
    generate_series(1, 5),
    1.0 + (generate_series(1, 5) - 1) * 0.1
FROM users u 
WHERE u.username = 'demo_user';

-- 示例积分交易记录
INSERT INTO points_transactions (
    user_id, transaction_type, amount, balance_before, balance_after,
    description, reference_type
)
SELECT 
    u.id,
    txn.transaction_type,
    txn.amount,
    txn.balance_before,
    txn.balance_after,
    txn.description,
    txn.reference_type
FROM users u
CROSS JOIN (
    VALUES 
        ('initial_bonus', 1000, 0, 1000, '新用户注册奖励', 'system'),
        ('daily_checkin', 10, 1000, 1010, '每日签到奖励', 'checkin'),
        ('daily_checkin', 12, 1010, 1022, '每日签到奖励 (连续2天)', 'checkin'),
        ('daily_checkin', 14, 1022, 1036, '每日签到奖励 (连续3天)', 'checkin'),
        ('referral_bonus', 50, 1036, 1086, '推荐好友奖励', 'referral'),
        ('proposal_creation', -50, 1086, 1036, '创建提案费用', 'proposal')
) AS txn(transaction_type, amount, balance_before, balance_after, description, reference_type)
WHERE u.username = 'demo_user';

-- 插入系统日志示例
INSERT INTO system_logs (
    log_level, log_message, log_category, user_id, metadata
) VALUES
('info', 'System initialization completed', 'system', NULL, '{"component": "database", "action": "init"}'),
('info', 'Default configuration loaded', 'system', NULL, '{"config_count": 45, "categories": ["user", "points", "staking", "proposal", "lottery", "nft"]}'),
('info', 'Sample data inserted successfully', 'system', NULL, '{"tables": ["users", "proposals", "staking_pools", "nft_collections", "lotteries"], "timestamp": "' || CURRENT_TIMESTAMP || '"}');

-- 完成通知
DO $$
DECLARE
    user_count INTEGER;
    config_count INTEGER;
    proposal_count INTEGER;
    pool_count INTEGER;
    collection_count INTEGER;
    lottery_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO config_count FROM system_configs;
    SELECT COUNT(*) INTO proposal_count FROM proposals;
    SELECT COUNT(*) INTO pool_count FROM staking_pools;
    SELECT COUNT(*) INTO collection_count FROM nft_collections;
    SELECT COUNT(*) INTO lottery_count FROM lotteries;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'GCCC 数据库初始数据插入完成';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '系统配置: % 条', config_count;
    RAISE NOTICE '用户数据: % 个', user_count;
    RAISE NOTICE '提案数据: % 个', proposal_count;
    RAISE NOTICE '质押池: % 个', pool_count;
    RAISE NOTICE 'NFT集合: % 个', collection_count;
    RAISE NOTICE '抽奖活动: % 个', lottery_count;
    RAISE NOTICE '==============================================';
    RAISE NOTICE '数据库已准备就绪，可以开始使用！';
    RAISE NOTICE '==============================================';
END
$$;
