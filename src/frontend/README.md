# GCCC 前端代码

GCCC项目的前端实现，基于React.js和Next.js构建的现代化Web应用。

## 目录结构

```
frontend/
├── demo/              # 用户管理模块演示
│   ├── index.html     # 演示页面
│   ├── styles.css     # 样式文件
│   ├── script.js      # 交互逻辑
│   └── README.md      # 演示说明
├── components/        # React组件 (计划开发)
├── pages/             # 页面组件 (计划开发)
├── utils/             # 工具函数 (计划开发)
├── hooks/             # 自定义Hook (计划开发)
├── styles/            # 全局样式 (计划开发)
└── README.md          # 本文件
```

## 当前实现

### 1. 用户管理模块演示 (demo/)
已完成的功能演示，包括：
- 用户登录/注册流程
- 用户仪表盘界面
- 个人资料管理
- 钱包连接集成
- 安全设置管理

**技术实现**:
- 纯HTML/CSS/JavaScript
- 现代化UI设计
- 响应式布局
- 完整的交互逻辑

## 计划开发

### 1. React应用架构
```
components/
├── common/            # 通用组件
│   ├── Button/
│   ├── Modal/
│   ├── Layout/
│   └── Loading/
├── wallet/            # 钱包相关组件
│   ├── ConnectWallet/
│   ├── WalletInfo/
│   └── WalletSelector/
├── user/              # 用户相关组件
│   ├── LoginModal/
│   ├── RegisterForm/
│   ├── UserProfile/
│   └── UserDashboard/
├── proposal/          # 提案模块组件
├── voting/            # 投票模块组件
├── staking/           # 质押模块组件
├── lottery/           # 抽奖模块组件
└── synthesis/         # 合成模块组件
```

### 2. 页面结构
```
pages/
├── index.tsx          # 首页
├── dashboard/         # 用户仪表盘
├── proposals/         # 提案列表
├── voting/            # 投票页面
├── staking/           # 质押页面
├── lottery/           # 抽奖页面
├── synthesis/         # 合成页面
└── profile/           # 个人资料
```

### 3. 状态管理
- 使用Redux Toolkit进行全局状态管理
- 钱包连接状态
- 用户认证状态
- 应用配置状态

### 4. 钱包集成
- Solana Wallet Adapter
- 支持多种钱包：Phantom、Solflare、Backpack等
- 钱包连接状态管理
- 交易签名处理

## 技术规范

### 1. 开发技术栈
- **框架**: React.js 18+ + Next.js 14+
- **语言**: TypeScript
- **样式**: Tailwind CSS + CSS Modules
- **状态管理**: Redux Toolkit + RTK Query
- **钱包**: @solana/wallet-adapter-react
- **图标**: React Icons
- **动画**: Framer Motion

### 2. 代码规范
- 使用TypeScript严格模式
- 遵循React函数组件和Hooks模式
- 组件使用PascalCase命名
- 文件使用kebab-case命名
- 使用ESLint和Prettier

### 3. 组件设计原则
- 单一职责原则
- 可复用性
- 可测试性
- 性能优化
- 无障碍访问

## 开发计划

### Phase 1: 基础架构搭建
- [ ] Next.js项目初始化
- [ ] TypeScript配置
- [ ] Tailwind CSS集成
- [ ] ESLint/Prettier配置
- [ ] 基础Layout组件

### Phase 2: 钱包集成
- [ ] Solana Wallet Adapter集成
- [ ] 钱包连接组件
- [ ] 钱包状态管理
- [ ] 交易处理逻辑

### Phase 3: 用户系统
- [ ] 用户认证组件
- [ ] 用户仪表盘
- [ ] 个人资料管理
- [ ] 安全设置

### Phase 4: 核心功能模块
- [ ] 提案模块
- [ ] 投票模块
- [ ] 质押模块
- [ ] 抽奖模块
- [ ] 合成模块

### Phase 5: 优化和测试
- [ ] 性能优化
- [ ] 单元测试
- [ ] 集成测试
- [ ] E2E测试

## 部署说明

### 1. 开发环境
```bash
npm run dev
```

### 2. 构建生产版本
```bash
npm run build
npm run start
```

### 3. 静态导出
```bash
npm run export
```
