# GCCC 前端应用

完整的用户认证系统，支持登录、注册、用户仪表板等功能。

## 🚀 快速开始

### 直接运行
打开 `auth-app.html` 在浏览器中即可使用完整的认证系统。

### 测试账户
- **管理员**: `admin@gccc.com` / `admin123`
- **普通用户**: `user@gccc.com` / `user123`

## 📁 项目结构

```
frontend/
├── auth-app.html      # 主应用文件 (完整的React应用)
├── components/        # React组件库
│   └── ui/
│       └── Button.tsx # 可重用的Button组件
├── contexts/          # React Context
│   └── AuthContext.tsx # 认证状态管理
├── types/            # TypeScript类型定义
│   ├── auth.ts       # 认证相关类型
│   └── index.ts      # 类型导出
├── utils/            # 工具函数和服务
│   ├── authService.ts # 认证服务
│   └── mockData.ts   # 模拟数据
├── package.json      # 项目依赖
├── tsconfig.json     # TypeScript配置
└── README.md         # 本文件
```

## ✨ 功能特色

### 🔐 认证系统
- **用户登录**: 邮箱密码登录，支持管理员和普通用户
- **用户注册**: 完整的注册流程，包含表单验证
- **会话管理**: LocalStorage持久化登录状态
- **角色区分**: 管理员和普通用户不同的界面权限

### 🎨 用户界面
- **现代化设计**: 玻璃态效果 (Glass Morphism)
- **响应式布局**: 适配桌面和移动设备
- **流畅动画**: 加载状态、错误提示、悬停效果
- **专业配色**: 紫蓝渐变背景，白色半透明卡片

### 📊 用户仪表板
- **个人资料**: 头像、用户名、邮箱、角色标签
- **等级系统**: 经验值、等级显示
- **推荐系统**: 推荐码、推荐人数统计
- **账户信息**: KYC状态、注册时间、最后登录

## 🛠️ 技术实现

### 核心技术
- **React 18**: 使用Hooks (useState, useEffect, useContext)
- **TypeScript**: 完整的类型安全
- **Context API**: 全局状态管理
- **Tailwind CSS**: 实用优先的样式框架 (CDN版本)

### 架构设计
- **组件化**: 可重用的UI组件
- **服务层**: 模拟API服务，易于替换为真实API
- **类型安全**: 完整的TypeScript类型定义
- **错误处理**: 友好的错误提示和验证

## 📝 代码结构说明

### 核心文件
- `auth-app.html`: 包含完整React应用的单文件
- `types/auth.ts`: 用户、认证凭据等类型定义
- `utils/authService.ts`: 认证服务，处理登录注册逻辑
- `utils/mockData.ts`: 模拟用户数据
- `contexts/AuthContext.tsx`: React Context，管理认证状态

### 组件组织
```typescript
// 认证相关类型
interface User {
  id: string;
  email: string;
  username: string;
  role: 'admin' | 'user';
  // ... 更多字段
}

// 认证服务
authService.signIn(credentials) // 登录
authService.signUp(credentials) // 注册

// Context状态管理
{ user, isLoading, error, signIn, signUp, signOut }
```

## 🚧 开发说明

### 本地开发
如需修改TypeScript组件:
```bash
# 安装依赖
npm install

# 编辑TypeScript文件
# components/, contexts/, types/, utils/

# 配置已包含在 tsconfig.json 中
```

### 文件修改指南
1. **添加新组件**: 在 `components/` 目录下创建
2. **修改认证逻辑**: 编辑 `utils/authService.ts`
3. **更新用户类型**: 修改 `types/auth.ts`
4. **调整样式**: 主要样式在 `auth-app.html` 的 `<style>` 标签中

## 🔄 下一步开发计划

### 短期目标
- [ ] 添加密码重置功能
- [ ] 实现邮箱验证流程
- [ ] 添加用户头像上传
- [ ] 优化移动端体验

### 中期目标
- [ ] 连接真实后端API
- [ ] 实现JWT认证
- [ ] 添加多语言支持
- [ ] 集成Solana钱包

### 长期目标
- [ ] 实现完整的用户权限系统
- [ ] 添加推荐系统界面
- [ ] 集成区块链功能
- [ ] 完善测试覆盖

## 📋 测试指南

### 手动测试
1. 打开 `auth-app.html`
2. 测试登录功能 (使用提供的测试账户)
3. 测试注册功能 (任意邮箱用户名)
4. 验证仪表板显示
5. 测试退出登录

### 功能验证清单
- [ ] 登录表单验证
- [ ] 注册表单验证
- [ ] 密码确认验证
- [ ] 用户协议确认
- [ ] 管理员/普通用户角色区分
- [ ] 会话持久化 (刷新页面保持登录)
- [ ] 响应式设计 (手机/平板/桌面)

这个完整的认证系统为GCCC项目提供了坚实的前端基础，可以轻松扩展更多功能。

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
