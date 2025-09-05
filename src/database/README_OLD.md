# GCCC 数据库部署指南

## 概述

本文档描述了如何部署和管理 GCCC (Global Consensus Crypto Community) DApp 的 PostgreSQL 数据库。

## 前置要求

- PostgreSQL 13+ (推荐 15+)
- 具有创建数据库权限的 PostgreSQL 用户
- psql 命令行工具

## 文件结构

```
src/database/
├── 01-database-init-config.sql    # 数据库初始化和基础配置
├── 02-core-tables.sql              # 核心业务表结构
├── 03-business-tables.sql          # 业务模块表结构
├── 04-database-functions.sql       # 存储过程和函数
├── 05-initial-data.sql             # 初始配置和示例数据
├── deploy.sql                      # 完整部署脚本
├── migrations.sql                  # 迁移管理系统
└── README.md                       # 本文档
```

## 快速部署

### 方法一：使用部署脚本（推荐）

```bash
# 进入数据库目录
cd src/database

# 使用psql执行部署脚本
psql -U postgres -h localhost -f deploy.sql
```

### 方法二：逐步执行

```bash
# 1. 创建数据库和基础配置
psql -U postgres -h localhost -f 01-database-init-config.sql

# 2. 连接到新数据库
psql -U postgres -h localhost -d gccc_db

# 3. 在gccc_db中执行后续脚本
\i 02-core-tables.sql
\i 03-business-tables.sql
\i 04-database-functions.sql
\i 05-initial-data.sql
```

## 数据库配置

### 连接参数

- **数据库名**: `gccc_db`
- **用户名**: `gccc_user`
- **编码**: `UTF8`
- **时区**: `UTC`

### 必需扩展

数据库自动安装以下扩展：

- `uuid-ossp`: UUID 生成
- `pgcrypto`: 加密功能
- `btree_gin`: 复合索引支持
- `pg_trgm`: 文本搜索优化

## 数据库架构

### 核心表

| 表名                  | 用途     | 记录数（初始） |
| --------------------- | -------- | -------------- |
| `users`               | 用户管理 | 1              |
| `user_sessions`       | 会话管理 | 0              |
| `user_wallets`        | 钱包关联 | 0              |
| `user_permissions`    | 权限管理 | 10             |
| `user_points`         | 积分系统 | 1              |
| `daily_checkins`      | 签到记录 | 5              |
| `points_transactions` | 积分交易 | 6              |
| `system_configs`      | 系统配置 | 45             |

### 业务模块表

| 表名              | 用途     | 记录数（初始） |
| ----------------- | -------- | -------------- |
| `proposals`       | 提案管理 | 3              |
| `proposal_votes`  | 投票记录 | 0              |
| `staking_pools`   | 质押池   | 4              |
| `user_stakes`     | 用户质押 | 0              |
| `lotteries`       | 抽奖活动 | 2              |
| `lottery_tickets` | 抽奖票   | 0              |
| `nft_collections` | NFT 集合 | 3              |
| `nfts`            | NFT 资产 | 0              |

### 关键功能函数

| 函数名                | 用途       |
| --------------------- | ---------- |
| `register_user()`     | 用户注册   |
| `authenticate_user()` | 用户认证   |
| `add_points()`        | 积分增加   |
| `deduct_points()`     | 积分扣除   |
| `daily_checkin()`     | 每日签到   |
| `create_proposal()`   | 创建提案   |
| `cast_vote()`         | 投票       |
| `create_admin_user()` | 创建管理员 |

## 初始数据

### 系统配置

部署后包含 45 项系统配置，覆盖：

- 用户系统配置（注册、验证等）
- 积分系统配置（奖励、费用等）
- 质押系统配置（APY、锁定期等）
- 提案系统配置（投票规则等）
- 抽奖系统配置（价格、限制等）
- NFT 系统配置（铸造、版税等）
- 区块链配置（网络、地址等）
- 安全配置（JWT、会话等）

### 演示数据

- **演示用户**: `demo_user` (钱包已验证)
- **质押池**: 4 个不同期限的质押池
- **提案**: 3 个不同类型的示例提案
- **NFT 集合**: 3 个不同用途的 NFT 集合
- **抽奖活动**: 2 个示例抽奖活动

## 迁移管理

### 迁移系统

数据库包含完整的迁移管理系统：

```sql
-- 查看迁移状态
SELECT * FROM get_migration_status();

-- 执行健康检查
SELECT * FROM database_health_check();

-- 创建备份元数据
SELECT create_backup_metadata('backup_name');
```

### 版本管理

- **v1.0.0**: 初始数据库架构
- **v1.0.1**: 初始数据填充

## 安全注意事项

### 权限管理

1. **生产环境**: 使用专用用户 `gccc_user`，限制权限
2. **开发环境**: 可以使用 `postgres` 用户
3. **备份**: 定期备份数据库和配置

### 密码安全

```sql
-- 修改默认密码
ALTER USER gccc_user PASSWORD 'your_secure_password_here';
```

### 连接限制

```sql
-- 限制并发连接数
ALTER DATABASE gccc_db CONNECTION LIMIT 100;
```

## 监控和维护

### 性能监控

```sql
-- 查看表大小
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 查看活跃连接
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

### 定期维护

```sql
-- 更新表统计信息
ANALYZE;

-- 重建索引（如需要）
REINDEX DATABASE gccc_db;

-- 清理无用数据
VACUUM;
```

## 故障排除

### 常见问题

1. **连接失败**

   - 检查 PostgreSQL 服务状态
   - 验证连接参数
   - 检查防火墙设置

2. **权限错误**

   - 确认用户具有足够权限
   - 检查数据库和表的所有权

3. **扩展安装失败**
   - 确认 PostgreSQL 安装了对应扩展包
   - 使用管理员权限安装扩展

### 日志查看

```sql
-- 查看系统日志
SELECT * FROM system_logs ORDER BY created_at DESC LIMIT 50;

-- 查看错误日志
SELECT * FROM audit_logs WHERE log_level = 'error' ORDER BY created_at DESC;
```

## 备份和恢复

### 创建备份

```bash
# 完整备份
pg_dump -U postgres -h localhost gccc_db > gccc_backup_$(date +%Y%m%d_%H%M%S).sql

# 仅架构备份
pg_dump -U postgres -h localhost --schema-only gccc_db > gccc_schema_backup.sql

# 仅数据备份
pg_dump -U postgres -h localhost --data-only gccc_db > gccc_data_backup.sql
```

### 恢复数据库

```bash
# 从备份恢复
createdb -U postgres gccc_db_restored
psql -U postgres -h localhost -d gccc_db_restored -f gccc_backup_20241225_120000.sql
```

## 联系支持

如遇到问题，请检查：

1. PostgreSQL 日志文件
2. 应用程序日志
3. 系统资源使用情况
4. 网络连接状态

更多技术支持，请参考项目文档或联系开发团队。
│ ├── 002_create_proposals.sql
│ ├── 003_create_votes.sql
│ ├── 004_create_stakes.sql
│ └── 005_create_transactions.sql
├── seeds/ # 初始数据
│ ├── users.sql
│ ├── proposals.sql
│ └── system_config.sql
├── schemas/ # 数据库模式定义
│ ├── postgresql.sql
│ └── indexes.sql
├── backups/ # 数据库备份
└── README.md # 本文件

````

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
````

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

### 8. NFT 表 (nfts)

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

## Redis 缓存设计

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

- **用户信息**: 30 分钟过期
- **提案列表**: 5 分钟过期
- **投票结果**: 实时更新，1 小时过期
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
- 保留 30 天备份历史

### 2. 备份验证

- 定期恢复测试
- 数据完整性检查
- 备份文件大小监控

## 性能监控

### 1. 监控指标

- 查询响应时间
- 连接池使用率
- 磁盘 I/O 性能
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
- Redis 监控面板
