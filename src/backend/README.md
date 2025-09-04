# GCCC 后端项目结构

## 项目概述

GCCC 后端服务是一个基于 Node.js + Express 构建的 Web3 DApp 后端系统，提供用户认证、权限管理、积分系统、提案投票、质押系统等核心功能。

## 目录结构

```
src/backend/
├── docs/                           # 文档目录
│   ├── API_Documentation.md        # API接口文档
│   └── README.md                   # 项目说明文档
├── api/                            # API路由目录
│   ├── auth/                       # 认证相关路由
│   │   ├── auth.routes.js          # 认证路由定义
│   │   ├── auth.controller.js      # 认证控制器
│   │   └── auth.validation.js      # 认证参数验证
│   ├── user/                       # 用户管理路由
│   │   ├── user.routes.js          # 用户路由定义
│   │   ├── user.controller.js      # 用户控制器
│   │   └── user.validation.js      # 用户参数验证
│   ├── admin/                      # 管理员路由
│   │   ├── admin.routes.js         # 管理员路由定义
│   │   ├── admin.controller.js     # 管理员控制器
│   │   └── admin.validation.js     # 管理员参数验证
│   ├── points/                     # 积分系统路由
│   │   ├── points.routes.js        # 积分路由定义
│   │   ├── points.controller.js    # 积分控制器
│   │   └── points.validation.js    # 积分参数验证
│   ├── proposals/                  # 提案投票路由
│   │   ├── proposals.routes.js     # 提案路由定义
│   │   ├── proposals.controller.js # 提案控制器
│   │   └── proposals.validation.js # 提案参数验证
│   ├── staking/                    # 质押系统路由
│   │   ├── staking.routes.js       # 质押路由定义
│   │   ├── staking.controller.js   # 质押控制器
│   │   └── staking.validation.js   # 质押参数验证
│   ├── lottery/                    # 抽奖系统路由
│   │   ├── lottery.routes.js       # 抽奖路由定义
│   │   ├── lottery.controller.js   # 抽奖控制器
│   │   └── lottery.validation.js   # 抽奖参数验证
│   ├── nft/                        # NFT管理路由
│   │   ├── nft.routes.js           # NFT路由定义
│   │   ├── nft.controller.js       # NFT控制器
│   │   └── nft.validation.js       # NFT参数验证
│   └── index.js                    # 路由入口文件
├── middleware/                     # 中间件目录
│   ├── auth.middleware.js          # 身份验证中间件
│   ├── permission.middleware.js    # 权限检查中间件
│   ├── validation.middleware.js    # 参数验证中间件
│   ├── rateLimit.middleware.js     # 频率限制中间件
│   ├── error.middleware.js         # 错误处理中间件
│   ├── logging.middleware.js       # 日志记录中间件
│   └── cors.middleware.js          # 跨域处理中间件
├── services/                       # 服务层目录
│   ├── database/                   # 数据库服务
│   │   ├── index.js                # 数据库连接配置
│   │   ├── auth.service.js         # 认证数据服务
│   │   ├── user.service.js         # 用户数据服务
│   │   ├── points.service.js       # 积分数据服务
│   │   ├── proposals.service.js    # 提案数据服务
│   │   ├── staking.service.js      # 质押数据服务
│   │   ├── lottery.service.js      # 抽奖数据服务
│   │   └── nft.service.js          # NFT数据服务
│   ├── blockchain/                 # 区块链服务
│   │   ├── index.js                # Solana连接配置
│   │   ├── wallet.service.js       # 钱包验证服务
│   │   ├── token.service.js        # Token操作服务
│   │   ├── nft.service.js          # NFT操作服务
│   │   └── staking.service.js      # 质押合约服务
│   ├── external/                   # 外部服务
│   │   ├── email.service.js        # 邮件发送服务
│   │   ├── ipfs.service.js         # IPFS存储服务
│   │   └── oracle.service.js       # 预言机服务
│   └── cache/                      # 缓存服务
│       ├── redis.service.js        # Redis缓存服务
│       └── memory.service.js       # 内存缓存服务
├── utils/                          # 工具函数目录
│   ├── crypto.js                   # 加密工具
│   ├── validation.js               # 验证工具
│   ├── response.js                 # 响应格式化工具
│   ├── logger.js                   # 日志工具
│   ├── constants.js                # 常量定义
│   ├── helpers.js                  # 辅助函数
│   └── errors.js                   # 错误定义
├── config/                         # 配置文件目录
│   ├── database.js                 # 数据库配置
│   ├── blockchain.js               # 区块链配置
│   ├── server.js                   # 服务器配置
│   ├── security.js                 # 安全配置
│   └── index.js                    # 配置入口文件
├── tests/                          # 测试目录
│   ├── unit/                       # 单元测试
│   ├── integration/                # 集成测试
│   ├── fixtures/                   # 测试数据
│   └── helpers/                    # 测试辅助函数
├── scripts/                        # 脚本目录
│   ├── migrate.js                  # 数据库迁移脚本
│   ├── seed.js                     # 数据种子脚本
│   └── deploy.js                   # 部署脚本
├── app.js                          # Express应用入口
├── server.js                       # 服务器启动文件
├── package.json                    # 项目依赖配置
├── .env.example                    # 环境变量示例
├── .gitignore                      # Git忽略文件
├── README.md                       # 项目说明
└── ecosystem.config.js             # PM2配置文件
```

## 技术栈

### 核心框架
- **Node.js**: JavaScript运行时
- **Express.js**: Web应用框架
- **PostgreSQL**: 关系型数据库
- **Redis**: 缓存和会话存储

### Web3集成
- **@solana/web3.js**: Solana区块链交互
- **@solana/spl-token**: SPL Token操作
- **@metaplex-foundation/js**: NFT操作

### 身份验证
- **jsonwebtoken**: JWT token生成和验证
- **bcryptjs**: 密码哈希
- **tweetnacl**: 钱包签名验证

### 数据验证
- **joi**: 输入参数验证
- **express-validator**: Express验证中间件

### 开发工具
- **nodemon**: 开发热重载
- **jest**: 单元测试框架
- **supertest**: API测试
- **eslint**: 代码规范检查
- **prettier**: 代码格式化
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
