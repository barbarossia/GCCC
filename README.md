# GCCC (Global Consensus Commemorative Coin)

基于Solana区块链的去中心化治理和NFT合成平台。

## 项目概述

GCCC是一个创新的Web3项目，结合了代币经济学、去中心化治理、NFT合成和社区参与机制。通过质押、投票、抽奖等多种方式，为用户提供全方位的区块链体验。

## 项目结构

```
GCCC/
├── docs/                   # 📚 设计文档
│   ├── design/            # 详细设计文档
│   │   ├── frontend/      # 前端模块设计
│   │   ├── 开发文档.md    # 主要开发文档
│   │   ├── 需求文档.md    # 需求规格说明
│   │   ├── 游戏规则.md    # 游戏规则和机制
│   │   └── Global_consensus.txt # 全球共识文档
│   └── README.md          # 文档说明
├── src/                   # 💻 源代码
│   ├── frontend/          # React + Next.js 前端
│   │   ├── demo/         # 用户管理模块演示 ✅
│   │   └── README.md     # 前端开发指南
│   ├── backend/           # Node.js + Express 后端
│   │   └── README.md     # 后端开发指南
│   ├── database/          # PostgreSQL + Redis 数据库
│   │   └── README.md     # 数据库设计文档
│   ├── smart-contracts/   # Solana + Anchor 智能合约
│   │   └── README.md     # 智能合约文档
│   ├── test/             # 🧪 测试套件
│   │   ├── frontend/     # 前端测试
│   │   ├── backend/      # 后端测试
│   │   ├── integration/  # 集成测试
│   │   └── README.md     # 测试指南
│   └── README.md         # 源码总览
└── README.md             # 本文件
```

## 核心特性

### 🔐 用户管理系统
- 钱包连接认证（支持Phantom、Solflare等）
- 用户资料管理和KYC认证
- VIP等级系统和经验值机制
- 推荐系统和社交功能

### 🏛️ 去中心化治理
- 提案创建和管理
- 基于代币的投票机制
- 投票权重计算
- 提案执行自动化

### 💰 质押系统
- 多层次质押池
- 动态收益率
- 锁定期灵活配置
- VIP等级加成

### 🎲 抽奖系统
- 去中心化随机数生成
- 多种奖励类型
- 公平透明的开奖机制
- 历史记录查询

### 🎨 NFT合成系统
- 独特的合成算法
- 稀有度系统
- 属性随机生成
- 合成历史追踪

## 技术架构

### 前端技术栈
- **框架**: React.js + Next.js + TypeScript
- **样式**: Tailwind CSS + CSS Modules
- **状态管理**: Redux Toolkit
- **钱包集成**: Solana Wallet Adapter
- **UI组件**: 自定义组件库

### 后端技术栈
- **运行时**: Node.js + Express.js + TypeScript
- **数据库**: PostgreSQL + Redis
- **认证**: JWT + Passport.js
- **API文档**: Swagger/OpenAPI
- **队列**: Bull Queue

### 智能合约
- **区块链**: Solana
- **框架**: Anchor Framework
- **语言**: Rust
- **代币标准**: SPL Token
- **NFT标准**: Metaplex

### 基础设施
- **容器化**: Docker + Docker Compose
- **CI/CD**: GitHub Actions
- **监控**: Prometheus + Grafana
- **日志**: ELK Stack

## 快速开始

### 环境要求
- Node.js 18+
- Rust 1.70+
- Solana CLI 1.16+
- Anchor CLI 0.28+
- Docker & Docker Compose

### 本地开发

1. **克隆项目**
```bash
git clone https://github.com/your-username/GCCC.git
cd GCCC
```

2. **安装依赖**
```bash
# 前端依赖
cd src/frontend && npm install

# 后端依赖
cd ../backend && npm install

# 智能合约依赖
cd ../smart-contracts && anchor build
```

3. **环境配置**
```bash
# 复制环境变量模板
cp .env.example .env.local

# 配置数据库和其他服务
```

4. **启动服务**
```bash
# 启动数据库服务
docker-compose up -d postgres redis

# 启动后端服务
cd src/backend && npm run dev

# 启动前端服务
cd src/frontend && npm run dev
```

5. **查看演示**
访问前端用户管理模块演示：
```bash
# 在浏览器中打开
file:///path/to/GCCC/src/frontend/demo/index.html
```

## 开发状态

### ✅ 已完成
- [x] 项目架构重构
- [x] 详细设计文档（8个前端模块）
- [x] 用户管理模块前端演示
- [x] 数据库设计文档
- [x] 智能合约架构设计
- [x] 测试框架设计

### 🚧 开发中
- [ ] React前端应用开发
- [ ] Node.js后端API开发
- [ ] Solana智能合约实现
- [ ] 数据库迁移和种子数据

### 📋 计划中
- [ ] 钱包集成和认证系统
- [ ] 治理和投票功能
- [ ] 质押和奖励机制
- [ ] 抽奖系统实现
- [ ] NFT合成功能
- [ ] 生产环境部署

## 贡献指南

### 开发流程
1. Fork项目到个人仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交变更 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

### 代码规范
- 使用TypeScript严格模式
- 遵循ESLint和Prettier配置
- 编写测试用例
- 更新相关文档

### 提交规范
使用[Conventional Commits](https://conventionalcommits.org/)格式：
```
type(scope): description

feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具
```

## 社区

### 官方链接
- 🌐 官网: [gccc.community](https://gccc.community)
- 📱 Twitter: [@GCCC_Official](https://twitter.com/GCCC_Official)
- 💬 Discord: [GCCC Community](https://discord.gg/gccc)
- 📖 文档: [docs.gccc.community](https://docs.gccc.community)

### 支持
- 📧 邮箱: support@gccc.community
- 🐛 Bug报告: [GitHub Issues](https://github.com/your-username/GCCC/issues)
- 💡 功能建议: [GitHub Discussions](https://github.com/your-username/GCCC/discussions)

## 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

## 免责声明

本项目仅用于教育和研究目的。在参与任何代币相关活动之前，请确保遵守当地法律法规。投资有风险，请谨慎参与。
