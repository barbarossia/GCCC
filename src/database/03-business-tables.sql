-- ================================================================
-- GCCC 业务模块数据表
-- 包含提案、投票、质押、抽奖、NFT等业务功能表
-- ================================================================

-- 提案表
-- ================================================================
CREATE TABLE proposals (
    id BIGINT PRIMARY KEY DEFAULT nextval('proposal_id_seq'),
    uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
    
    -- 基本信息
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    content TEXT,
    category VARCHAR(50) DEFAULT 'general',
    
    -- 提案者信息
    proposer_user_id BIGINT NOT NULL REFERENCES users(id),
    proposer_wallet VARCHAR(44) NOT NULL,
    
    -- 投票配置
    voting_type VARCHAR(20) DEFAULT 'simple',
    min_voting_power DECIMAL(20,8) DEFAULT 0,
    quorum_threshold DECIMAL(5,2) DEFAULT 10.0,
    pass_threshold DECIMAL(5,2) DEFAULT 50.0,
    
    -- 时间配置
    voting_start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    voting_end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    execution_delay INTEGER DEFAULT 0,
    
    -- 投票统计
    total_votes_count INTEGER DEFAULT 0,
    yes_votes_count INTEGER DEFAULT 0,
    no_votes_count INTEGER DEFAULT 0,
    abstain_votes_count INTEGER DEFAULT 0,
    total_voting_power DECIMAL(20,8) DEFAULT 0,
    
    -- 状态信息
    status proposal_status_enum DEFAULT 'draft',
    executed_at TIMESTAMP WITH TIME ZONE,
    execution_tx_hash VARCHAR(88),
    
    -- 附加信息
    metadata JSONB,
    tags TEXT[],
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    CONSTRAINT proposals_voting_dates CHECK (voting_end_at > voting_start_at),
    CONSTRAINT proposals_thresholds CHECK (
        quorum_threshold >= 0 AND quorum_threshold <= 100 AND
        pass_threshold >= 0 AND pass_threshold <= 100
    )
);

-- 投票记录表
-- ================================================================
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    proposal_id BIGINT NOT NULL REFERENCES proposals(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    
    -- 投票信息
    vote_option vote_option_enum NOT NULL,
    voting_power DECIMAL(20,8) NOT NULL DEFAULT 0,
    wallet_address VARCHAR(44) NOT NULL,
    
    -- 投票证明
    signature VARCHAR(128),
    message TEXT,
    nonce VARCHAR(64),
    
    -- 委托投票
    delegated_from_user_id BIGINT REFERENCES users(id),
    delegation_weight DECIMAL(5,2) DEFAULT 1.0,
    
    -- 备注信息
    comment TEXT,
    metadata JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(proposal_id, user_id),
    CONSTRAINT votes_voting_power_positive CHECK (voting_power >= 0),
    CONSTRAINT votes_delegation_weight CHECK (delegation_weight >= 0 AND delegation_weight <= 1)
);

-- 投票委托表
-- ================================================================
CREATE TABLE vote_delegations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delegator_user_id BIGINT NOT NULL REFERENCES users(id),
    delegate_user_id BIGINT NOT NULL REFERENCES users(id),
    
    -- 委托信息
    delegation_type VARCHAR(20) DEFAULT 'full',
    categories TEXT[],
    weight DECIMAL(5,2) DEFAULT 1.0,
    
    -- 时间限制
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- 状态
    is_active BOOLEAN DEFAULT TRUE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(delegator_user_id, delegate_user_id),
    CONSTRAINT vote_delegations_different_users CHECK (delegator_user_id != delegate_user_id),
    CONSTRAINT vote_delegations_weight CHECK (weight > 0 AND weight <= 1)
);

-- 质押池表
-- ================================================================
CREATE TABLE staking_pools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 基本信息
    name VARCHAR(100) NOT NULL,
    description TEXT,
    token_mint VARCHAR(44) NOT NULL,
    
    -- 质押配置
    min_stake_amount DECIMAL(20,8) DEFAULT 0,
    max_stake_amount DECIMAL(20,8),
    lock_period_days INTEGER NOT NULL,
    apy_rate DECIMAL(8,4) NOT NULL,
    
    -- 容量限制
    max_total_stake DECIMAL(20,8),
    current_total_stake DECIMAL(20,8) DEFAULT 0,
    staker_count INTEGER DEFAULT 0,
    
    -- 奖励配置
    reward_token_mint VARCHAR(44),
    reward_distribution_method VARCHAR(20) DEFAULT 'proportional',
    early_unstake_penalty DECIMAL(5,2) DEFAULT 0,
    
    -- 状态信息
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    requires_whitelist BOOLEAN DEFAULT FALSE,
    
    -- 时间信息
    start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    
    -- 附加信息
    metadata JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    CONSTRAINT staking_pools_amounts CHECK (
        min_stake_amount >= 0 AND 
        (max_stake_amount IS NULL OR max_stake_amount >= min_stake_amount)
    ),
    CONSTRAINT staking_pools_apy CHECK (apy_rate >= 0),
    CONSTRAINT staking_pools_penalty CHECK (early_unstake_penalty >= 0 AND early_unstake_penalty <= 100)
);

-- 用户质押记录表
-- ================================================================
CREATE TABLE user_stakes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id),
    pool_id UUID NOT NULL REFERENCES staking_pools(id),
    
    -- 质押信息
    stake_amount DECIMAL(20,8) NOT NULL,
    staked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    lock_until TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- 奖励信息
    accumulated_rewards DECIMAL(20,8) DEFAULT 0,
    last_reward_claimed_at TIMESTAMP WITH TIME ZONE,
    pending_rewards DECIMAL(20,8) DEFAULT 0,
    
    -- 解质押信息
    unstake_requested_at TIMESTAMP WITH TIME ZONE,
    unstake_amount DECIMAL(20,8),
    unstaked_at TIMESTAMP WITH TIME ZONE,
    penalty_amount DECIMAL(20,8) DEFAULT 0,
    
    -- 交易信息
    stake_tx_hash VARCHAR(88),
    unstake_tx_hash VARCHAR(88),
    
    -- 状态
    status staking_status_enum DEFAULT 'active',
    
    -- 附加信息
    metadata JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    CONSTRAINT user_stakes_amount_positive CHECK (stake_amount > 0),
    CONSTRAINT user_stakes_unstake_amount CHECK (
        unstake_amount IS NULL OR unstake_amount <= stake_amount
    )
);

-- 质押奖励分发记录表
-- ================================================================
CREATE TABLE staking_reward_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_id UUID NOT NULL REFERENCES staking_pools(id),
    
    -- 分发信息
    distribution_date DATE NOT NULL,
    total_rewards DECIMAL(20,8) NOT NULL,
    total_staked_amount DECIMAL(20,8) NOT NULL,
    reward_rate DECIMAL(12,8) NOT NULL,
    
    -- 参与信息
    eligible_stakers_count INTEGER NOT NULL,
    actual_recipients_count INTEGER DEFAULT 0,
    
    -- 状态信息
    status VARCHAR(20) DEFAULT 'pending',
    distributed_at TIMESTAMP WITH TIME ZONE,
    transaction_hash VARCHAR(88),
    
    -- 附加信息
    metadata JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(pool_id, distribution_date)
);

-- 个人奖励记录表
-- ================================================================
CREATE TABLE user_reward_claims (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id),
    stake_id UUID NOT NULL REFERENCES user_stakes(id),
    distribution_id UUID NOT NULL REFERENCES staking_reward_distributions(id),
    
    -- 奖励信息
    reward_amount DECIMAL(20,8) NOT NULL,
    stake_amount_at_time DECIMAL(20,8) NOT NULL,
    claim_percentage DECIMAL(8,6) NOT NULL,
    
    -- 领取信息
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transaction_hash VARCHAR(88),
    
    -- 状态
    status VARCHAR(20) DEFAULT 'pending',
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(stake_id, distribution_id),
    CONSTRAINT user_reward_claims_amounts_positive CHECK (
        reward_amount > 0 AND stake_amount_at_time > 0
    )
);

-- 抽奖表
-- ================================================================
CREATE TABLE lotteries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    round_number INTEGER UNIQUE NOT NULL DEFAULT nextval('lottery_round_seq'),
    
    -- 基本信息
    title VARCHAR(200) NOT NULL,
    description TEXT,
    lottery_type VARCHAR(50) DEFAULT 'standard',
    
    -- 奖池配置
    ticket_price DECIMAL(20,8) NOT NULL,
    max_tickets_per_user INTEGER DEFAULT 100,
    max_total_tickets INTEGER,
    
    -- 奖品配置
    prize_pool DECIMAL(20,8) DEFAULT 0,
    prize_distribution JSONB,
    nft_prizes JSONB,
    
    -- 时间配置
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    draw_time TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- 统计信息
    total_tickets_sold INTEGER DEFAULT 0,
    total_participants INTEGER DEFAULT 0,
    total_prize_value DECIMAL(20,8) DEFAULT 0,
    
    -- 开奖信息
    winning_numbers INTEGER[],
    drawn_at TIMESTAMP WITH TIME ZONE,
    draw_tx_hash VARCHAR(88),
    
    -- 状态
    status lottery_status_enum DEFAULT 'upcoming',
    
    -- 附加信息
    metadata JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    CONSTRAINT lotteries_times CHECK (
        end_time > start_time AND draw_time >= end_time
    ),
    CONSTRAINT lotteries_ticket_price_positive CHECK (ticket_price > 0)
);

-- 抽奖票表
-- ================================================================
CREATE TABLE lottery_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lottery_id UUID NOT NULL REFERENCES lotteries(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    
    -- 票据信息
    ticket_number INTEGER NOT NULL,
    ticket_hash VARCHAR(64) UNIQUE NOT NULL,
    numbers_selected INTEGER[],
    
    -- 购买信息
    purchase_price DECIMAL(20,8) NOT NULL,
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    purchase_tx_hash VARCHAR(88),
    
    -- 中奖信息
    is_winner BOOLEAN DEFAULT FALSE,
    prize_tier INTEGER,
    prize_amount DECIMAL(20,8) DEFAULT 0,
    prize_claimed BOOLEAN DEFAULT FALSE,
    claimed_at TIMESTAMP WITH TIME ZONE,
    claim_tx_hash VARCHAR(88),
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(lottery_id, ticket_number),
    CONSTRAINT lottery_tickets_prize_amount_positive CHECK (
        prize_amount >= 0
    )
);

-- NFT集合表
-- ================================================================
CREATE TABLE nft_collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 基本信息
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    description TEXT,
    collection_address VARCHAR(44) UNIQUE,
    
    -- 创建者信息
    creator_user_id BIGINT REFERENCES users(id),
    creator_wallet VARCHAR(44) NOT NULL,
    
    -- 供应信息
    max_supply INTEGER NOT NULL,
    current_supply INTEGER DEFAULT 0,
    minted_count INTEGER DEFAULT 0,
    burned_count INTEGER DEFAULT 0,
    
    -- 定价信息
    mint_price DECIMAL(20,8) DEFAULT 0,
    royalty_percentage DECIMAL(5,2) DEFAULT 0,
    royalty_address VARCHAR(44),
    
    -- 元数据信息
    base_uri TEXT,
    metadata_uri TEXT,
    image_uri TEXT,
    external_url TEXT,
    
    -- 配置信息
    is_mutable BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    requires_whitelist BOOLEAN DEFAULT FALSE,
    
    -- 时间信息
    launch_date TIMESTAMP WITH TIME ZONE,
    mint_start_date TIMESTAMP WITH TIME ZONE,
    mint_end_date TIMESTAMP WITH TIME ZONE,
    
    -- 状态
    status nft_status_enum DEFAULT 'draft',
    
    -- 附加信息
    attributes JSONB,
    metadata JSONB,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    CONSTRAINT nft_collections_supply_positive CHECK (max_supply > 0),
    CONSTRAINT nft_collections_royalty CHECK (
        royalty_percentage >= 0 AND royalty_percentage <= 50
    )
);

-- NFT表
-- ================================================================
CREATE TABLE nfts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID NOT NULL REFERENCES nft_collections(id),
    
    -- NFT信息
    token_id INTEGER NOT NULL,
    mint_address VARCHAR(44) UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- 所有者信息
    owner_user_id BIGINT REFERENCES users(id),
    owner_wallet VARCHAR(44) NOT NULL,
    
    -- 元数据
    image_uri TEXT,
    animation_uri TEXT,
    external_url TEXT,
    attributes JSONB,
    metadata JSONB,
    
    -- 交易信息
    mint_price DECIMAL(20,8) DEFAULT 0,
    last_sale_price DECIMAL(20,8),
    current_listing_price DECIMAL(20,8),
    
    -- 铸造信息
    minted_by_user_id BIGINT REFERENCES users(id),
    minted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    mint_tx_hash VARCHAR(88),
    
    -- 状态信息
    status nft_status_enum DEFAULT 'active',
    is_listed BOOLEAN DEFAULT FALSE,
    is_staked BOOLEAN DEFAULT FALSE,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- 约束
    UNIQUE(collection_id, token_id),
    CONSTRAINT nfts_prices_positive CHECK (
        mint_price >= 0 AND
        (last_sale_price IS NULL OR last_sale_price >= 0) AND
        (current_listing_price IS NULL OR current_listing_price >= 0)
    )
);

-- NFT交易记录表
-- ================================================================
CREATE TABLE nft_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nft_id UUID NOT NULL REFERENCES nfts(id),
    
    -- 交易信息
    transaction_type VARCHAR(20) NOT NULL,
    price DECIMAL(20,8) DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'SOL',
    
    -- 参与方信息
    from_user_id BIGINT REFERENCES users(id),
    from_wallet VARCHAR(44),
    to_user_id BIGINT REFERENCES users(id),
    to_wallet VARCHAR(44),
    
    -- 区块链信息
    transaction_hash VARCHAR(88) UNIQUE,
    block_number BIGINT,
    gas_used DECIMAL(20,8),
    gas_price DECIMAL(20,8),
    
    -- 市场信息
    marketplace VARCHAR(50),
    marketplace_fee DECIMAL(20,8) DEFAULT 0,
    royalty_fee DECIMAL(20,8) DEFAULT 0,
    
    -- 状态
    status transaction_status_enum DEFAULT 'pending',
    confirmed_at TIMESTAMP WITH TIME ZONE,
    
    -- 时间戳
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
-- ================================================================

-- 提案表索引
CREATE INDEX idx_proposals_proposer ON proposals(proposer_user_id);
CREATE INDEX idx_proposals_status ON proposals(status);
CREATE INDEX idx_proposals_category ON proposals(category);
CREATE INDEX idx_proposals_voting_dates ON proposals(voting_start_at, voting_end_at);
CREATE INDEX idx_proposals_created_at ON proposals(created_at);

-- 投票表索引
CREATE INDEX idx_votes_proposal_id ON votes(proposal_id);
CREATE INDEX idx_votes_user_id ON votes(user_id);
CREATE INDEX idx_votes_option ON votes(vote_option);
CREATE INDEX idx_votes_created_at ON votes(created_at);

-- 委托表索引
CREATE INDEX idx_vote_delegations_delegator ON vote_delegations(delegator_user_id);
CREATE INDEX idx_vote_delegations_delegate ON vote_delegations(delegate_user_id);
CREATE INDEX idx_vote_delegations_active ON vote_delegations(is_active);

-- 质押表索引
CREATE INDEX idx_staking_pools_active ON staking_pools(is_active);
CREATE INDEX idx_staking_pools_token ON staking_pools(token_mint);
CREATE INDEX idx_user_stakes_user_id ON user_stakes(user_id);
CREATE INDEX idx_user_stakes_pool_id ON user_stakes(pool_id);
CREATE INDEX idx_user_stakes_status ON user_stakes(status);
CREATE INDEX idx_user_stakes_lock_until ON user_stakes(lock_until);

-- 奖励表索引
CREATE INDEX idx_staking_reward_distributions_pool ON staking_reward_distributions(pool_id);
CREATE INDEX idx_staking_reward_distributions_date ON staking_reward_distributions(distribution_date);
CREATE INDEX idx_user_reward_claims_user ON user_reward_claims(user_id);
CREATE INDEX idx_user_reward_claims_stake ON user_reward_claims(stake_id);

-- 抽奖表索引
CREATE INDEX idx_lotteries_status ON lotteries(status);
CREATE INDEX idx_lotteries_times ON lotteries(start_time, end_time);
CREATE INDEX idx_lottery_tickets_lottery ON lottery_tickets(lottery_id);
CREATE INDEX idx_lottery_tickets_user ON lottery_tickets(user_id);
CREATE INDEX idx_lottery_tickets_winner ON lottery_tickets(is_winner);

-- NFT表索引
CREATE INDEX idx_nft_collections_creator ON nft_collections(creator_user_id);
CREATE INDEX idx_nft_collections_status ON nft_collections(status);
CREATE INDEX idx_nfts_collection ON nfts(collection_id);
CREATE INDEX idx_nfts_owner ON nfts(owner_user_id);
CREATE INDEX idx_nfts_status ON nfts(status);
CREATE INDEX idx_nfts_listed ON nfts(is_listed);
CREATE INDEX idx_nft_transactions_nft ON nft_transactions(nft_id);
CREATE INDEX idx_nft_transactions_type ON nft_transactions(transaction_type);
CREATE INDEX idx_nft_transactions_status ON nft_transactions(status);

-- 创建触发器
-- ================================================================

-- 提案表更新时间触发器
CREATE TRIGGER trigger_proposals_updated_at
    BEFORE UPDATE ON proposals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 投票表更新时间触发器
CREATE TRIGGER trigger_votes_updated_at
    BEFORE UPDATE ON votes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 委托表更新时间触发器
CREATE TRIGGER trigger_vote_delegations_updated_at
    BEFORE UPDATE ON vote_delegations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 质押表更新时间触发器
CREATE TRIGGER trigger_staking_pools_updated_at
    BEFORE UPDATE ON staking_pools
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_user_stakes_updated_at
    BEFORE UPDATE ON user_stakes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 抽奖表更新时间触发器
CREATE TRIGGER trigger_lotteries_updated_at
    BEFORE UPDATE ON lotteries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- NFT表更新时间触发器
CREATE TRIGGER trigger_nft_collections_updated_at
    BEFORE UPDATE ON nft_collections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_nfts_updated_at
    BEFORE UPDATE ON nfts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 权限设置
-- ================================================================

-- 授予表权限
GRANT SELECT, INSERT, UPDATE, DELETE ON proposals TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON votes TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON vote_delegations TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON staking_pools TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_stakes TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON staking_reward_distributions TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_reward_claims TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON lotteries TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON lottery_tickets TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON nft_collections TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON nfts TO gccc_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON nft_transactions TO gccc_user;

-- 序列权限
GRANT USAGE, SELECT ON proposal_id_seq TO gccc_user;
GRANT USAGE, SELECT ON lottery_round_seq TO gccc_user;

-- 表注释
-- ================================================================

COMMENT ON TABLE proposals IS '提案管理表';
COMMENT ON TABLE votes IS '投票记录表';
COMMENT ON TABLE vote_delegations IS '投票委托表';
COMMENT ON TABLE staking_pools IS '质押池配置表';
COMMENT ON TABLE user_stakes IS '用户质押记录表';
COMMENT ON TABLE staking_reward_distributions IS '质押奖励分发记录表';
COMMENT ON TABLE user_reward_claims IS '用户奖励领取记录表';
COMMENT ON TABLE lotteries IS '抽奖活动表';
COMMENT ON TABLE lottery_tickets IS '抽奖票表';
COMMENT ON TABLE nft_collections IS 'NFT集合表';
COMMENT ON TABLE nfts IS 'NFT资产表';
COMMENT ON TABLE nft_transactions IS 'NFT交易记录表';

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '业务模块数据表创建完成';
    RAISE NOTICE '已创建表: proposals, votes, vote_delegations';
    RAISE NOTICE '已创建表: staking_pools, user_stakes, staking_reward_distributions, user_reward_claims';
    RAISE NOTICE '已创建表: lotteries, lottery_tickets';
    RAISE NOTICE '已创建表: nft_collections, nfts, nft_transactions';
    RAISE NOTICE '已创建相关索引和触发器';
END
$$;
