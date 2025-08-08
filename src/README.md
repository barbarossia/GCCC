# GCCC 源代码

本目录包含 GCCC 项目的所有源代码，已优化为清洁、高效的项目结构。

## 目录结构

```
src/
├── frontend/           # 前端应用 (完整的React认证系统)
│   ├── auth-app.html  # 主应用 - 完整的登录注册系统
│   ├── components/    # React组件
│   │   └── ui/        # UI组件 (Button等)
│   ├── contexts/      # React Context (认证状态管理)
│   ├── types/         # TypeScript类型定义
│   ├── utils/         # 工具函数和服务
│   ├── package.json   # 项目依赖
│   ├── tsconfig.json  # TypeScript配置
│   └── README.md      # 前端说明文档
├── backend/           # 后端服务 (待开发)
│   └── README.md      # 后端说明文档
├── database/          # 数据库相关 (待开发)
│   └── README.md      # 数据库说明文档
├── smart-contracts/   # 智能合约 (待开发)
│   └── README.md      # 智能合约说明文档
├── test/             # 测试文件 (待开发)
│   └── README.md      # 测试说明文档
└── README.md          # 本文件
```

## 当前状态

### ✅ 已完成
- **前端认证系统**: 完整的用户登录注册功能
  - 用户登录页面 (支持管理员和普通用户)
  - 用户注册页面 (完整的表单验证)
  - 用户仪表板 (角色区分显示)
  - 模拟数据服务 (admin@gccc.com/admin123, user@gccc.com/user123)
  - 现代化UI设计 (玻璃态效果，响应式布局)
  - 会话管理 (LocalStorage持久化登录)

### 🔄 待开发
- **后端API**: Node.js + Express 服务器
- **数据库**: PostgreSQL 数据模型和迁移
- **智能合约**: Solana Programs
- **测试**: 单元测试和集成测试

## 快速开始

### 运行前端应用
1. 打开 `frontend/auth-app.html` 在浏览器中
2. 使用测试账户登录:
   - 管理员: `admin@gccc.com` / `admin123`
   - 普通用户: `user@gccc.com` / `user123`

### 前端开发 (如需修改React组件)
```bash
cd frontend
npm install
# 然后编辑相应的TypeScript文件
```

## 技术栈

### 前端 (已实现)
- **React + TypeScript**: 现代化的用户界面框架
- **Tailwind CSS**: 实用优先的CSS框架 (CDN版本)
- **Context API**: 状态管理
- **LocalStorage**: 会话持久化

### 后端 (规划中)
- **Node.js + Express**: 服务器框架
- **TypeScript**: 类型安全的JavaScript
- **JWT Authentication**: 用户认证
- **Prisma ORM**: 数据库ORM

### 数据库 (规划中)
- **PostgreSQL**: 主数据库
- **Redis**: 缓存数据库

### 智能合约 (规划中)
- **Solana Programs**: 基于Solana的智能合约
- **Anchor Framework**: Solana开发框架

## 项目特色

- **零配置运行**: 前端应用可直接在浏览器中运行
- **现代化技术栈**: React + TypeScript + Tailwind CSS
- **清洁架构**: 去除了冗余的目录和空文件
- **模块化设计**: 类型安全的组件和服务
- **用户体验优先**: 流畅的动画和响应式设计

## 重构说明

本次重构完成了以下优化:

### 移除的冗余结构
- ❌ `frontend/src/` (重复的src目录)
- ❌ `frontend/demo/` (已被完整应用替代)
- ❌ `frontend/pages/` (空目录)
- ❌ `backend/api/`, `backend/services/` (空目录)
- ❌ `database/migrations/` (空目录)
- ❌ `smart-contracts/programs/` (空目录)
- ❌ `test/frontend/`, `test/backend/`, `test/integration/` (空目录)

### 保留的核心文件
- ✅ `frontend/auth-app.html` (完整的认证应用)
- ✅ `frontend/components/ui/Button.tsx` (React组件)
- ✅ `frontend/contexts/AuthContext.tsx` (认证上下文)
- ✅ `frontend/types/auth.ts` (类型定义)
- ✅ `frontend/utils/authService.ts`, `mockData.ts` (服务和数据)
- ✅ 各目录的README.md文件

## 下一步开发计划

1. **后端API开发**: 实现真实的用户认证和数据管理
2. **数据库设计**: 用户、角色、推荐系统等数据模型
3. **智能合约集成**: 区块链功能实现
4. **测试覆盖**: 完整的测试套件

详细的开发说明请参考各个子目录中的README文件。
