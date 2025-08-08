# GCCC 后端服务

GCCC项目的后端服务，提供RESTful API和WebSocket支持。

## 目录结构

```
backend/
├── api/               # API路由和控制器
│   ├── auth/          # 认证相关API
│   ├── users/         # 用户管理API
│   ├── proposals/     # 提案管理API
│   ├── voting/        # 投票相关API
│   ├── staking/       # 质押相关API
│   ├── lottery/       # 抽奖相关API
│   └── synthesis/     # 合成相关API
├── services/          # 业务逻辑服务
│   ├── auth.service.js
│   ├── user.service.js
│   ├── proposal.service.js
│   ├── voting.service.js
│   ├── staking.service.js
│   ├── lottery.service.js
│   └── synthesis.service.js
├── models/            # 数据模型
│   ├── User.js
│   ├── Proposal.js
│   ├── Vote.js
│   ├── Stake.js
│   └── Transaction.js
├── middleware/        # 中间件
│   ├── auth.js
│   ├── validation.js
│   ├── rateLimit.js
│   └── logging.js
├── utils/             # 工具函数
│   ├── crypto.js
│   ├── validation.js
│   └── helpers.js
├── config/            # 配置文件
│   ├── database.js
│   ├── redis.js
│   └── solana.js
└── README.md          # 本文件
```

## 技术栈

### 核心框架
- **运行时**: Node.js 18+
- **框架**: Express.js
- **语言**: TypeScript
- **API文档**: Swagger/OpenAPI

### 数据存储
- **主数据库**: PostgreSQL
- **缓存**: Redis
- **文件存储**: AWS S3 / IPFS

### 区块链集成
- **Solana**: @solana/web3.js
- **钱包验证**: nacl (签名验证)
- **代币操作**: @solana/spl-token

### 认证和安全
- **JWT**: jsonwebtoken
- **密码加密**: bcrypt
- **速率限制**: express-rate-limit
- **CORS**: cors

## API设计

### 1. 认证相关 (/api/auth)
```
POST   /auth/connect-wallet     # 钱包连接认证
POST   /auth/verify-signature   # 签名验证
POST   /auth/refresh           # 刷新Token
DELETE /auth/logout            # 登出
```

### 2. 用户管理 (/api/users)
```
GET    /users/profile          # 获取用户资料
PUT    /users/profile          # 更新用户资料
GET    /users/stats            # 获取用户统计
GET    /users/history          # 获取操作历史
POST   /users/kyc              # KYC认证
```

### 3. 提案管理 (/api/proposals)
```
GET    /proposals              # 获取提案列表
POST   /proposals              # 创建提案
GET    /proposals/:id          # 获取提案详情
PUT    /proposals/:id          # 更新提案
DELETE /proposals/:id          # 删除提案
```

### 4. 投票系统 (/api/voting)
```
POST   /voting/vote            # 投票
GET    /voting/results/:id     # 获取投票结果
GET    /voting/user-votes      # 获取用户投票记录
```

### 5. 质押系统 (/api/staking)
```
POST   /staking/stake          # 质押代币
POST   /staking/unstake        # 取消质押
GET    /staking/pools          # 获取质押池信息
GET    /staking/user-stakes    # 获取用户质押信息
```

### 6. 抽奖系统 (/api/lottery)
```
GET    /lottery/rounds         # 获取抽奖轮次
POST   /lottery/participate    # 参与抽奖
GET    /lottery/results        # 获取抽奖结果
GET    /lottery/user-tickets   # 获取用户抽奖券
```

### 7. 合成系统 (/api/synthesis)
```
POST   /synthesis/combine      # NFT合成
GET    /synthesis/recipes      # 获取合成配方
GET    /synthesis/user-nfts    # 获取用户NFT
```

## 数据模型

### 1. 用户模型 (User)
```typescript
interface User {
  id: string;
  walletAddress: string;
  username?: string;
  email?: string;
  avatar?: string;
  level: number;
  experience: number;
  kycStatus: 'pending' | 'verified' | 'rejected';
  referralCode: string;
  referredBy?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### 2. 提案模型 (Proposal)
```typescript
interface Proposal {
  id: string;
  title: string;
  description: string;
  category: string;
  creator: string;
  status: 'draft' | 'active' | 'passed' | 'rejected';
  votingStartTime: Date;
  votingEndTime: Date;
  totalVotes: number;
  yesVotes: number;
  noVotes: number;
  createdAt: Date;
  updatedAt: Date;
}
```

### 3. 投票模型 (Vote)
```typescript
interface Vote {
  id: string;
  proposalId: string;
  userId: string;
  choice: 'yes' | 'no';
  tokenAmount: number;
  transactionHash: string;
  createdAt: Date;
}
```

## 业务逻辑

### 1. 钱包认证流程
1. 用户发起钱包连接请求
2. 生成随机消息用于签名
3. 验证钱包签名的有效性
4. 创建或更新用户记录
5. 生成JWT令牌

### 2. 提案管理流程
1. 创建提案需要质押一定代币
2. 提案进入审核状态
3. 通过审核后开始投票期
4. 投票结束后统计结果
5. 执行提案或返还质押

### 3. 投票权重计算
- 基础投票权重 = 质押代币数量
- VIP等级加成
- 早期参与者加成
- 连续参与奖励

### 4. 抽奖机制
- 基于质押量分配抽奖券
- 使用区块链随机数确保公平
- 多层次奖励结构
- 防作弊机制

## 开发计划

### Phase 1: 基础框架搭建
- [ ] Express.js项目初始化
- [ ] TypeScript配置
- [ ] 数据库连接和模型定义
- [ ] 基础中间件配置
- [ ] API文档框架

### Phase 2: 用户认证系统
- [ ] 钱包连接认证
- [ ] JWT令牌管理
- [ ] 用户资料管理
- [ ] 权限控制中间件

### Phase 3: 核心业务模块
- [ ] 提案管理系统
- [ ] 投票系统
- [ ] 质押系统
- [ ] 抽奖系统
- [ ] 合成系统

### Phase 4: 优化和监控
- [ ] 性能优化
- [ ] 错误处理和日志
- [ ] 监控和告警
- [ ] API限流和安全

### Phase 5: 测试和部署
- [ ] 单元测试
- [ ] 集成测试
- [ ] 压力测试
- [ ] 生产部署

## 部署配置

### 1. 环境变量
```bash
# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/gccc
REDIS_URL=redis://localhost:6379

# JWT配置
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=7d

# Solana配置
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
SOLANA_NETWORK=mainnet-beta

# 其他配置
PORT=3001
NODE_ENV=production
```

### 2. Docker部署
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```
