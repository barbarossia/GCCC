# GCCC 源代码

本目录包含 GCCC (Global Consensus Commemorative Coin) 项目的所有源代码。

## 目录结构

```
src/
├── frontend/           # 前端代码
│   ├── demo/          # 用户管理模块演示
│   ├── components/    # React组件 (计划)
│   ├── pages/         # 页面组件 (计划)
│   ├── utils/         # 工具函数 (计划)
│   └── README.md      # 前端说明文档
├── backend/           # 后端代码
│   ├── api/           # API接口 (计划)
│   ├── services/      # 业务逻辑 (计划)
│   ├── models/        # 数据模型 (计划)
│   └── README.md      # 后端说明文档
├── database/          # 数据库相关
│   ├── migrations/    # 数据库迁移 (计划)
│   ├── seeds/         # 初始数据 (计划)
│   └── README.md      # 数据库说明文档
├── smart-contracts/   # 智能合约
│   ├── programs/      # Solana程序 (计划)
│   ├── tests/         # 合约测试 (计划)
│   └── README.md      # 智能合约说明文档
├── test/              # 测试代码
│   ├── frontend/      # 前端测试
│   ├── backend/       # 后端测试
│   ├── integration/   # 集成测试
│   └── README.md      # 测试说明文档
└── README.md          # 本文件
```

## 技术栈

### 前端
- **框架**: React.js + Next.js
- **语言**: TypeScript
- **样式**: Tailwind CSS
- **状态管理**: Redux Toolkit
- **钱包集成**: Solana Wallet Adapter

### 后端
- **框架**: Node.js + Express.js
- **语言**: TypeScript
- **数据库**: PostgreSQL + Redis
- **认证**: JWT + Passport.js
- **API文档**: Swagger/OpenAPI

### 智能合约
- **平台**: Solana
- **语言**: Rust (Anchor框架)
- **代币标准**: SPL Token
- **NFT标准**: Metaplex

### 测试
- **前端测试**: Jest + React Testing Library
- **后端测试**: Jest + Supertest
- **E2E测试**: Playwright
- **合约测试**: Anchor Test Framework

## 开发指南

### 1. 环境设置
```bash
# 安装依赖
npm install

# 设置环境变量
cp .env.example .env.local

# 启动开发环境
npm run dev
```

### 2. 代码规范
- 使用ESLint和Prettier进行代码格式化
- 遵循TypeScript严格模式
- 提交前运行测试和类型检查

### 3. 分支策略
- `main`: 主分支，稳定版本
- `develop`: 开发分支，集成最新功能
- `feature/*`: 功能分支
- `hotfix/*`: 紧急修复分支

## 部署说明

### 1. 开发环境
- 本地开发和测试

### 2. 测试环境
- 功能测试和集成测试
- 使用Solana Devnet

### 3. 生产环境
- 正式发布版本
- 使用Solana Mainnet

## 当前状态

- ✅ **项目结构**: 已完成重构
- ✅ **前端Demo**: 用户管理模块演示已完成
- 🚧 **前端开发**: 规划中
- 🚧 **后端开发**: 规划中
- 🚧 **智能合约**: 规划中
- 🚧 **测试框架**: 规划中
