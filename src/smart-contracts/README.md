# GCCC 智能合约

GCCC项目的智能合约实现，基于Solana区块链和Anchor框架开发。

## 目录结构

```
smart-contracts/
├── programs/          # Anchor程序
│   ├── gccc-token/    # GCCC代币合约
│   ├── gccc-governance/  # 治理合约
│   ├── gccc-staking/  # 质押合约
│   ├── gccc-lottery/  # 抽奖合约
│   └── gccc-nft/     # NFT合成合约
├── tests/             # 合约测试
│   ├── token.test.ts
│   ├── governance.test.ts
│   ├── staking.test.ts
│   ├── lottery.test.ts
│   └── nft.test.ts
├── scripts/           # 部署和管理脚本
│   ├── deploy.ts
│   ├── initialize.ts
│   └── upgrade.ts
├── target/            # 编译输出
├── Anchor.toml        # Anchor配置
├── Cargo.toml         # Rust项目配置
└── README.md          # 本文件
```

## 技术栈

### 核心框架
- **区块链**: Solana
- **框架**: Anchor Framework
- **语言**: Rust
- **代币标准**: SPL Token
- **NFT标准**: Metaplex

### 开发工具
- **CLI**: Anchor CLI
- **测试**: Mocha + Chai
- **部署**: Anchor Deploy
- **验证**: Solana Verify

## 合约架构

### 1. GCCC代币合约 (gccc-token)
主要代币功能实现

#### 功能特性
- SPL代币标准实现
- 代币铸造和销毁
- 转账和余额查询
- 多签名控制
- 冻结和解冻功能

#### 关键结构
```rust
#[account]
pub struct TokenInfo {
    pub mint: Pubkey,
    pub total_supply: u64,
    pub decimals: u8,
    pub freeze_authority: Option<Pubkey>,
    pub mint_authority: Option<Pubkey>,
}
```

### 2. 治理合约 (gccc-governance)
去中心化治理功能

#### 功能特性
- 提案创建和管理
- 投票机制
- 投票权重计算
- 提案执行
- 治理参数配置

#### 关键结构
```rust
#[account]
pub struct Proposal {
    pub id: u64,
    pub proposer: Pubkey,
    pub title: String,
    pub description: String,
    pub category: ProposalCategory,
    pub voting_start_time: i64,
    pub voting_end_time: i64,
    pub yes_votes: u64,
    pub no_votes: u64,
    pub status: ProposalStatus,
    pub execution_data: Vec<u8>,
}

#[account]
pub struct Vote {
    pub proposal_id: u64,
    pub voter: Pubkey,
    pub choice: VoteChoice,
    pub voting_power: u64,
    pub timestamp: i64,
}
```

### 3. 质押合约 (gccc-staking)
代币质押和奖励机制

#### 功能特性
- 代币质押和取消质押
- 奖励计算和分发
- 多个质押池支持
- 锁定期机制
- VIP等级系统

#### 关键结构
```rust
#[account]
pub struct StakingPool {
    pub pool_id: String,
    pub token_mint: Pubkey,
    pub reward_mint: Pubkey,
    pub total_staked: u64,
    pub reward_rate: u64,
    pub lock_duration: i64,
    pub is_active: bool,
}

#[account]
pub struct UserStake {
    pub user: Pubkey,
    pub pool_id: String,
    pub amount: u64,
    pub reward_debt: u64,
    pub stake_time: i64,
    pub unlock_time: i64,
}
```

### 4. 抽奖合约 (gccc-lottery)
去中心化抽奖系统

#### 功能特性
- 抽奖创建和管理
- 抽奖券购买
- 随机数生成
- 奖金分配
- 历史记录查询

#### 关键结构
```rust
#[account]
pub struct Lottery {
    pub round: u64,
    pub title: String,
    pub ticket_price: u64,
    pub total_tickets: u32,
    pub prize_pool: u64,
    pub start_time: i64,
    pub end_time: i64,
    pub winner: Option<Pubkey>,
    pub random_seed: [u8; 32],
    pub status: LotteryStatus,
}

#[account]
pub struct LotteryTicket {
    pub lottery_round: u64,
    pub owner: Pubkey,
    pub ticket_number: u32,
    pub purchase_time: i64,
}
```

### 5. NFT合成合约 (gccc-nft)
NFT创建和合成功能

#### 功能特性
- NFT铸造
- NFT合成算法
- 稀有度系统
- 属性随机生成
- 合成历史记录

#### 关键结构
```rust
#[account]
pub struct NftMetadata {
    pub mint: Pubkey,
    pub name: String,
    pub symbol: String,
    pub uri: String,
    pub rarity: Rarity,
    pub attributes: Vec<Attribute>,
    pub synthesis_count: u8,
    pub is_synthesizable: bool,
}

#[account]
pub struct SynthesisRecord {
    pub user: Pubkey,
    pub input_nfts: Vec<Pubkey>,
    pub output_nft: Pubkey,
    pub recipe_id: String,
    pub timestamp: i64,
}
```

## 安全特性

### 1. 访问控制
- 多重签名验证
- 角色权限管理
- 紧急停止机制
- 升级控制

### 2. 经济安全
- 重入攻击防护
- 整数溢出检查
- 余额验证
- 滑点保护

### 3. 随机数安全
- Solana Clock作为熵源
- 多重随机因子
- 无法预测性保证
- 历史随机数记录

## 部署配置

### 1. 网络配置
```toml
# Anchor.toml
[features]
seeds = false
skip-lint = false

[programs.localnet]
gccc_token = "Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"
gccc_governance = "Hs7KqWAPnKi1pRVGLvQZpRkQjd2d1YQWfG3tKgEgGqJY"
gccc_staking = "Jd8HqGGPQn5YsHdYKJ2pRNGZs8fDrLKvEkYx7M9GfHWp"
gccc_lottery = "Km9YvPTNQr6FsHhZKL8mRWGYu5dXrDLvEcXz8N7GhJTp"
gccc_nft = "Lp2YwQSNSr7GtJhZMN9nRXGZt6fAsKLvFdYz9P8GjKWq"

[registry]
url = "https://api.apr.dev"

[provider]
cluster = "localnet"
wallet = "~/.config/solana/id.json"
```

### 2. 部署脚本
```typescript
// scripts/deploy.ts
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";

export async function deployPrograms() {
  // 设置提供者
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  // 部署代币合约
  const tokenProgram = await deployTokenProgram();
  
  // 部署治理合约
  const governanceProgram = await deployGovernanceProgram();
  
  // 部署质押合约
  const stakingProgram = await deployStakingProgram();
  
  // 部署抽奖合约
  const lotteryProgram = await deployLotteryProgram();
  
  // 部署NFT合约
  const nftProgram = await deployNftProgram();
  
  console.log("All programs deployed successfully!");
}
```

## 测试策略

### 1. 单元测试
- 每个函数的独立测试
- 边界条件测试
- 错误情况测试
- 状态变化验证

### 2. 集成测试
- 多合约交互测试
- 端到端流程测试
- 性能压力测试
- 并发操作测试

### 3. 测试示例
```typescript
// tests/staking.test.ts
describe("Staking Contract", () => {
  it("should stake tokens successfully", async () => {
    const stakeAmount = new anchor.BN(1000);
    
    await program.rpc.stake(stakeAmount, {
      accounts: {
        user: user.publicKey,
        stakingPool: stakingPool.publicKey,
        userStake: userStake.publicKey,
        tokenAccount: userTokenAccount,
        poolTokenAccount: poolTokenAccount,
      },
      signers: [user],
    });
    
    const stakeAccount = await program.account.userStake.fetch(userStake.publicKey);
    assert.equal(stakeAccount.amount.toNumber(), stakeAmount.toNumber());
  });
});
```

## 安全审计

### 1. 审计清单
- [ ] 访问控制验证
- [ ] 整数溢出检查
- [ ] 重入攻击防护
- [ ] 权限验证
- [ ] 状态一致性
- [ ] 经济模型验证

### 2. 审计工具
- Anchor内置安全检查
- Solana Security.txt
- 第三方安全审计
- 形式化验证

## 升级策略

### 1. 可升级设计
- 代理模式实现
- 状态迁移计划
- 向后兼容性
- 紧急升级机制

### 2. 升级流程
1. 测试网验证
2. 社区投票决定
3. 多签名批准
4. 主网部署
5. 状态迁移

## 监控和维护

### 1. 链上监控
- 交易监控
- 状态监控
- 性能监控
- 异常检测

### 2. 维护任务
- 定期状态检查
- 性能优化
- 安全更新
- 社区反馈处理

## 开发计划

### Phase 1: 基础合约开发
- [ ] GCCC代币合约
- [ ] 基础治理功能
- [ ] 简单质押机制

### Phase 2: 高级功能开发
- [ ] 复杂投票机制
- [ ] 多层次质押池
- [ ] 抽奖系统

### Phase 3: NFT和合成系统
- [ ] NFT铸造功能
- [ ] 合成算法实现
- [ ] 稀有度系统

### Phase 4: 优化和审计
- [ ] 性能优化
- [ ] 安全审计
- [ ] 文档完善

### Phase 5: 主网部署
- [ ] 测试网部署
- [ ] 社区测试
- [ ] 主网发布
