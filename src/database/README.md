# GCCC 数据库设计

GCCC项目的数据库设计，包括关系型数据库和缓存系统。

## 目录结构

```
database/
├── migrations/        # 数据库迁移文件
│   ├── 001_create_users.sql
│   ├── 002_create_proposals.sql
│   ├── 003_create_votes.sql
│   ├── 004_create_stakes.sql
│   └── 005_create_transactions.sql
├── seeds/             # 初始数据
│   ├── users.sql
│   ├── proposals.sql
│   └── system_config.sql
├── schemas/           # 数据库模式定义
│   ├── postgresql.sql
│   └── indexes.sql
├── backups/           # 数据库备份
└── README.md          # 本文件
```

## 数据库架构

### 主数据库 (PostgreSQL)
用于存储业务核心数据，确保数据一致性和ACID特性。

### 缓存系统 (Redis)
用于缓存热点数据，提高系统响应速度。

## 数据表设计

### 1. 用户表 (users)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_address VARCHAR(50) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255) UNIQUE,
    avatar_url TEXT,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    kyc_status VARCHAR(20) DEFAULT 'pending',
    referral_code VARCHAR(20) UNIQUE,
    referred_by UUID REFERENCES users(id),
    total_referrals INTEGER DEFAULT 0,
    active_referrals INTEGER DEFAULT 0,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. 提案表 (proposals)
```sql
CREATE TABLE proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    creator_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'draft',
    voting_start_time TIMESTAMP,
    voting_end_time TIMESTAMP,
    stake_amount DECIMAL(20,8) DEFAULT 0,
    total_votes INTEGER DEFAULT 0,
    yes_votes INTEGER DEFAULT 0,
    no_votes INTEGER DEFAULT 0,
    yes_tokens DECIMAL(20,8) DEFAULT 0,
    no_tokens DECIMAL(20,8) DEFAULT 0,
    execution_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. 投票表 (votes)
```sql
CREATE TABLE votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID NOT NULL REFERENCES proposals(id),
    voter_id UUID NOT NULL REFERENCES users(id),
    choice VARCHAR(10) NOT NULL CHECK (choice IN ('yes', 'no')),
    token_amount DECIMAL(20,8) NOT NULL,
    voting_power DECIMAL(20,8) NOT NULL,
    transaction_hash VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(proposal_id, voter_id)
);
```

### 4. 质押表 (stakes)
```sql
CREATE TABLE stakes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    pool_id VARCHAR(50) NOT NULL,
    token_amount DECIMAL(20,8) NOT NULL,
    reward_amount DECIMAL(20,8) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    stake_transaction_hash VARCHAR(100),
    unstake_transaction_hash VARCHAR(100),
    staked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unstaked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5. 交易记录表 (transactions)
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(50) NOT NULL,
    amount DECIMAL(20,8) NOT NULL,
    token_symbol VARCHAR(20) NOT NULL,
    transaction_hash VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    block_number BIGINT,
    gas_fee DECIMAL(20,8),
    related_id UUID, -- 关联的业务ID (提案ID、质押ID等)
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 6. 抽奖表 (lotteries)
```sql
CREATE TABLE lotteries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_number INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    total_tickets INTEGER DEFAULT 0,
    ticket_price DECIMAL(20,8) NOT NULL,
    prize_pool DECIMAL(20,8) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    draw_time TIMESTAMP,
    winner_id UUID REFERENCES users(id),
    winning_numbers JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 7. 抽奖券表 (lottery_tickets)
```sql
CREATE TABLE lottery_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lottery_id UUID NOT NULL REFERENCES lotteries(id),
    user_id UUID NOT NULL REFERENCES users(id),
    ticket_number VARCHAR(50) NOT NULL,
    purchase_price DECIMAL(20,8) NOT NULL,
    is_winner BOOLEAN DEFAULT FALSE,
    purchase_transaction_hash VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 8. NFT表 (nfts)
```sql
CREATE TABLE nfts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mint_address VARCHAR(50) UNIQUE NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    metadata_url TEXT,
    rarity VARCHAR(20),
    attributes JSONB,
    is_synthesizable BOOLEAN DEFAULT TRUE,
    synthesis_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 9. 合成记录表 (synthesis_records)
```sql
CREATE TABLE synthesis_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    input_nfts JSONB NOT NULL, -- 输入的NFT ID数组
    output_nft_id UUID REFERENCES nfts(id),
    recipe_id VARCHAR(50) NOT NULL,
    transaction_hash VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 10. 系统配置表 (system_configs)
```sql
CREATE TABLE system_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 索引设计

### 1. 性能优化索引
```sql
-- 用户表索引
CREATE INDEX idx_users_wallet_address ON users(wallet_address);
CREATE INDEX idx_users_referral_code ON users(referral_code);
CREATE INDEX idx_users_referred_by ON users(referred_by);

-- 提案表索引
CREATE INDEX idx_proposals_creator_id ON proposals(creator_id);
CREATE INDEX idx_proposals_status ON proposals(status);
CREATE INDEX idx_proposals_category ON proposals(category);
CREATE INDEX idx_proposals_voting_time ON proposals(voting_start_time, voting_end_time);

-- 投票表索引
CREATE INDEX idx_votes_proposal_id ON votes(proposal_id);
CREATE INDEX idx_votes_voter_id ON votes(voter_id);
CREATE INDEX idx_votes_created_at ON votes(created_at);

-- 质押表索引
CREATE INDEX idx_stakes_user_id ON stakes(user_id);
CREATE INDEX idx_stakes_pool_id ON stakes(pool_id);
CREATE INDEX idx_stakes_status ON stakes(status);

-- 交易记录索引
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_hash ON transactions(transaction_hash);
CREATE INDEX idx_transactions_status ON transactions(status);
```

## Redis缓存设计

### 1. 缓存键命名规范
```
user:{user_id}                 # 用户基本信息
user:stats:{user_id}           # 用户统计信息
proposal:list:{page}           # 提案列表分页
proposal:{proposal_id}         # 提案详情
voting:results:{proposal_id}   # 投票结果
staking:pools                  # 质押池信息
lottery:current                # 当前抽奖信息
nft:user:{user_id}            # 用户NFT列表
```

### 2. 缓存策略
- **用户信息**: 30分钟过期
- **提案列表**: 5分钟过期
- **投票结果**: 实时更新，1小时过期
- **系统配置**: 不过期，手动更新

## 数据迁移

### 1. 迁移文件命名
```
{timestamp}_{description}.sql
例如：20240101120000_create_users_table.sql
```

### 2. 迁移流程
1. 开发环境测试迁移
2. 测试环境验证
3. 生产环境执行
4. 备份和回滚计划

## 备份策略

### 1. 自动备份
- 每日全量备份
- 每小时增量备份
- 保留30天备份历史

### 2. 备份验证
- 定期恢复测试
- 数据完整性检查
- 备份文件大小监控

## 性能监控

### 1. 监控指标
- 查询响应时间
- 连接池使用率
- 磁盘I/O性能
- 缓存命中率

### 2. 性能优化
- 查询优化
- 索引优化
- 分区策略
- 读写分离

## 安全措施

### 1. 数据库安全
- 最小权限原则
- 连接加密
- 敏感数据加密
- 审计日志

### 2. 备份安全
- 备份文件加密
- 异地存储
- 访问控制
- 完整性校验

## 开发工具

### 1. 数据库管理
- pgAdmin (PostgreSQL GUI)
- Redis Commander (Redis GUI)
- DBeaver (通用数据库工具)

### 2. 版本控制
- Flyway (数据库版本控制)
- Liquibase (替代方案)

### 3. 监控工具
- Prometheus + Grafana
- pg_stat_statements
- Redis监控面板
