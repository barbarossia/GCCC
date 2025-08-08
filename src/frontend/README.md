# GCCC 前端应用

完整的用户认证系统，支持登录、注册、用户仪表板等功能。

## ✅ 最新更新 (2025-08-08)

### 🔄 项目重构完成
- **目录结构优化**: 将源代码和测试文件清晰分离到 `src/` 和 `tests/` 目录
- **开发环境完善**: 集成 Vite + TypeScript + Vitest 现代化开发栈
- **VS Code 集成**: 完整的开发环境配置，支持智能提示和错误检查
- **测试覆盖**: 完整的测试套件，所有 10 项测试通过 ✅
- **开发服务器**: 支持热重载的开发服务器运行在 `http://localhost:3001`

### 🎯 当前项目状态
- **✅ 开发环境**: Vite 开发服务器正常运行
- **✅ VS Code 配置**: TypeScript语言服务器和扩展完全配置
- **✅ 测试套件**: 10/10 测试通过，包含认证服务和基础功能测试
- **✅ 类型安全**: 完整的 TypeScript 类型定义和实时检查
- **✅ 代码质量**: ESLint + Prettier 自动化代码格式和质量检查
- **✅ 代码组织**: 专业级别的目录结构和代码分离

### 🆕 VS Code 优化更新
- **智能提示**: 完整的 IntelliSense 和自动补全
- **错误检查**: 实时 TypeScript 和 ESLint 错误提示
- **自动格式化**: 保存时自动格式化代码
- **扩展配置**: 预配置 TypeScript Nightly、ESLint、Prettier 扩展
- **工作区设置**: 优化的 VS Code 工作区配置

## 🚀 快速开始

### 直接运行 (HTML版本)
打开 `auth-app.html` 在浏览器中即可使用完整的认证系统。

### 开发环境运行 (推荐)
```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 访问应用
# http://localhost:3001/
```

### 测试账户
- **管理员**: `admin@gccc.com` / `admin123`
- **普通用户**: `user@gccc.com` / `user123`

## 📁 项目结构

```
frontend/
├── src/                    # 📱 应用程序源代码
│   ├── components/         # React组件库
│   │   ├── AuthApp.tsx     # 认证应用主组件
│   │   ├── Dashboard.tsx   # 用户仪表板
│   │   ├── LoginForm.tsx   # 登录表单
│   │   ├── SignUpForm.tsx  # 注册表单
│   │   └── ui/
│   │       └── Button.tsx  # 可重用的Button组件
│   ├── contexts/           # React Context
│   │   └── AuthContext.tsx # 认证状态管理
│   ├── types/             # TypeScript类型定义
│   │   ├── auth.ts        # 认证相关类型
│   │   └── index.ts       # 类型导出
│   ├── utils/             # 工具函数和服务
│   │   └── authService.ts # 认证服务
│   ├── App.tsx            # 应用程序入口组件
│   └── main.tsx           # React应用启动文件
├── tests/                 # 🧪 测试文件
│   ├── auth-service.test.ts # 认证服务测试
│   ├── basic.test.ts      # 基础功能测试
│   └── setup.ts           # 测试环境配置
├── auth-app.html          # 独立HTML应用文件
├── package.json           # 项目依赖
├── tsconfig.json          # TypeScript配置
├── vite.config.ts         # Vite构建配置
├── vitest.config.ts       # 测试配置
└── README.md              # 本文件
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

### 🛠️ 技术实现

### 核心技术
- **React 18**: 使用Hooks (useState, useEffect, useContext)
- **TypeScript**: 完整的类型安全，现代化配置
- **Vite**: 现代化构建工具和开发服务器
- **Vitest**: 快速的单元测试框架
- **Context API**: 全局状态管理
- **Tailwind CSS**: 实用优先的样式框架

### 开发环境
- **VS Code**: 专业级IDE配置，完整的TypeScript支持
- **ESLint + Prettier**: 代码质量和格式化
- **热重载**: 代码修改后自动刷新
- **类型检查**: 实时TypeScript错误提示和自动修复
- **智能提示**: 完整的IntelliSense和自动导入

### 架构设计
- **组件化**: 可重用的UI组件，清晰的职责分离
- **服务层**: 模拟API服务，易于替换为真实API
- **类型安全**: 完整的TypeScript类型定义
- **错误处理**: 友好的错误提示和验证
- **测试驱动**: 完整的测试覆盖和持续集成

### 开发环境特性
- **热重载**: 代码修改后自动刷新
- **类型检查**: 实时TypeScript错误提示
- **代码分割**: 优化的构建输出
- **开发工具**: 集成React DevTools支持

## 📝 代码结构说明

### 核心文件
- `src/App.tsx`: React应用主入口组件
- `src/main.tsx`: 应用启动文件和React DOM渲染
- `src/types/auth.ts`: 用户、认证凭据等类型定义  
- `src/utils/authService.ts`: 认证服务，处理登录注册逻辑
- `src/contexts/AuthContext.tsx`: React Context，管理认证状态
- `tests/`: 完整的测试套件，确保代码质量

### 组件组织
```typescript
// 认证相关类型 (src/types/auth.ts)
interface User {
  id: string;
  email: string;
  username: string;
  role: 'admin' | 'user';
  // ... 更多字段
}

// 认证服务 (src/utils/authService.ts)
authService.signIn(credentials) // 登录
authService.signUp(credentials) // 注册

// Context状态管理 (src/contexts/AuthContext.tsx)
{ user, isLoading, error, signIn, signUp, signOut }
```

## 🚧 开发指南

### 环境要求
- **Node.js**: >= 18.0.0
- **npm**: >= 8.0.0
- **现代浏览器**: Chrome 90+, Firefox 88+, Safari 14+

### 快速启动
```bash
# 克隆项目
git clone https://github.com/barbarossia/GCCC.git
cd GCCC/src/frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 或运行测试
npm test

# 或直接打开 auth-app.html 在浏览器中
```

### 可用脚本
```bash
npm run dev          # 启动开发服务器 (http://localhost:3001)
npm run build        # 构建生产版本
npm run preview      # 预览生产构建
npm test             # 运行所有测试
npm run test:watch   # 监听模式运行测试
npm run test:coverage # 生成测试覆盖率报告
npm run type-check   # TypeScript类型检查
npm run lint         # 代码质量检查
npm run format       # 代码格式化
```

## 🎯 VS Code 开发环境配置

### 推荐扩展 (已配置)
我们已经为项目配置了最佳的VS Code开发环境，包含以下扩展：

```bash
✅ TypeScript Nightly     # 最新TypeScript语言支持
✅ ESLint                 # 实时代码质量检查  
✅ Prettier               # 自动代码格式化
✅ React Developer Tools  # React组件调试
```

### 工作区配置
项目已包含 `.vscode/settings.json` 配置文件，提供：

- **自动导入**: TypeScript模块自动导入和整理
- **格式化**: 保存时自动格式化代码
- **错误检查**: 实时ESLint错误提示和自动修复
- **类型提示**: 完整的IntelliSense和参数提示

### TypeScript 配置优化
```bash
✅ 现代化配置: 使用最新的TypeScript和Vite兼容设置
✅ 路径映射: 支持 @/ 别名导入
✅ 严格模式: 启用所有TypeScript严格检查
✅ 构建分离: 应用代码和构建工具配置分离
```

### 开发体验特性
- **即时错误检查**: 代码编写时实时显示TypeScript错误
- **智能重构**: 支持变量重命名、函数提取等重构操作
- **自动导入**: 输入组件名时自动添加导入语句
- **代码补全**: 完整的API提示和参数说明
- **格式一致性**: 团队统一的代码格式标准

### 开发模式选择

#### 选项1: Vite开发环境 (推荐)
```bash
# 现代化开发体验
npm run dev

# 特性:
# - 极快的热重载 (<100ms)
# - TypeScript即时编译
# - ES模块支持
# - 完整的VS Code集成
# - 源码映射调试
```

#### 选项2: 直接HTML开发
```bash
# 直接在浏览器中打开
open auth-app.html
# 或在 VS Code 中使用 Live Server 扩展
```

### 开发工作流

#### 1. 添加新功能
```bash
# 创建功能分支
git checkout -b feature/new-feature

# 开发功能 (编辑相应文件)
# - 组件: src/components/
# - 类型: src/types/
# - 服务: src/utils/
# - 上下文: src/contexts/
# - 测试: tests/

# 运行测试确保功能正常
npm test

# 提交更改
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature
```

#### 2. 代码规范
```bash
# 代码格式化 (如果配置了)
npm run format

# 类型检查
npm run type-check

# 代码检查
npm run lint
```

### 本地开发配置

#### package.json 脚本扩展
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build", 
    "preview": "vite preview",
    "type-check": "tsc --noEmit",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,html,css,md}\"",
    "lint": "eslint . --ext .ts,.tsx,.js,.jsx",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  }
}
```

#### 开发工具配置
- **VS Code 扩展推荐**: ES7+ React/Redux/React-Native snippets, TypeScript Importer, Prettier
- **浏览器工具**: React Developer Tools, Redux DevTools
- **Git Hooks**: Husky for pre-commit checks

### 文件修改指南
1. **添加新组件**: 在 `src/components/` 目录下创建，遵循命名约定
2. **修改认证逻辑**: 编辑 `src/utils/authService.ts`
3. **更新用户类型**: 修改 `src/types/auth.ts`
4. **调整样式**: 使用Tailwind CSS类名或在组件中添加样式
5. **添加新服务**: 在 `src/utils/` 目录下创建对应的服务文件
6. **编写测试**: 在 `tests/` 目录下创建对应的测试文件

### 调试指南

#### VS Code 调试设置
```bash
# TypeScript 问题诊断
1. 重启TypeScript语言服务器: Ctrl+Shift+P -> "TypeScript: Restart TS Server"
2. 检查工作区配置: 确保.vscode/settings.json正确加载
3. 验证扩展: 确保TypeScript、ESLint、Prettier扩展已启用

# 常见VS Code问题解决
- 模块找不到: 重启VS Code或重启TS Server
- 导入路径错误: 检查tsconfig.json的paths配置
- 格式化不工作: 确保Prettier设置为默认格式化程序
```

#### 浏览器调试
```bash
# 浏览器开发者工具
F12 -> Console/Network/Application

# React 组件调试
console.log(user, isLoading, error);

# Vite开发工具
# Hot Module Replacement (HMR) 状态检查
# 网络请求监控
# 源码映射调试支持
```

#### TypeScript 类型检查
```bash
# 手动类型检查
npm run type-check

# 实时类型检查 (VS Code)
# 自动显示类型错误和警告
# 智能提示和自动补全
# 重构支持 (F2重命名, F12跳转定义)
```

# 网络请求调试
# 查看 Network 标签页中的模拟请求

# LocalStorage 调试
localStorage.getItem('gccc_token');

# 状态调试
# 使用 React DevTools 扩展查看 Context 状态
```

## 🔄 下一步开发计划

### 短期目标 (1-2 周)
- [ ] 添加密码重置功能
- [ ] 实现邮箱验证流程
- [ ] 添加用户头像上传
- [ ] 优化移动端体验
- [ ] 添加加载骨架屏
- [ ] 实现暗色主题切换

### 中期目标 (1-2 月)
- [ ] 连接真实后端API
- [ ] 实现JWT认证和刷新机制
- [ ] 添加多语言支持 (i18n)
- [ ] 集成Solana钱包
- [ ] 实现推送通知
- [ ] 添加用户反馈系统

### 长期目标 (3-6 月)
- [ ] 实现完整的用户权限系统
- [ ] 添加推荐系统界面
- [ ] 集成区块链功能
- [ ] 完善测试覆盖 (>90%)
- [ ] 性能优化和监控
- [ ] 多平台支持 (PWA)

## 📚 开发资源

### 官方文档
- [React 18 文档](https://react.dev/)
- [TypeScript 手册](https://www.typescriptlang.org/docs/)
- [Tailwind CSS 文档](https://tailwindcss.com/docs)
- [Vite 构建工具](https://vitejs.dev/)

### 推荐学习资源
- [React Patterns](https://reactpatterns.com/)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
- [Testing Library 文档](https://testing-library.com/)
- [Web.dev 性能指南](https://web.dev/performance/)

### 代码质量工具
```bash
# 代码格式化
npm install --save-dev prettier eslint-config-prettier

# Git 提交规范
npm install --save-dev @commitlint/cli @commitlint/config-conventional

# 代码质量检查
npm install --save-dev sonarjs
```

## 🤝 贡献指南

### 提交规范
```bash
# 类型
feat:     新功能
fix:      Bug 修复
docs:     文档更新
style:    代码格式 (不影响功能)
refactor: 代码重构
test:     测试相关
chore:    构建过程或辅助工具的变动

# 示例
git commit -m "feat: add password reset functionality"
git commit -m "fix: resolve login button alignment issue"
git commit -m "docs: update deployment guide"
```

### 代码审查检查项
```bash
□ 代码功能是否符合需求
□ 是否遵循项目代码规范
□ 是否包含适当的错误处理
□ 是否添加了必要的测试
□ 是否更新了相关文档
□ 性能是否有负面影响
□ 安全性是否考虑充分
□ 可访问性是否符合标准
```

## 📞 技术支持

### 常见问题解决

#### 1. VS Code TypeScript 问题
```bash
# 问题: "Cannot find module" 错误
解决方案:
1. 重启TypeScript语言服务器: Ctrl+Shift+P -> "TypeScript: Restart TS Server"
2. 检查 tsconfig.json 配置是否正确
3. 确保依赖已正确安装: npm install
4. 重启VS Code

# 问题: 自动导入不工作
解决方案:
1. 检查VS Code设置中的TypeScript配置
2. 确保 typescript.suggest.autoImports 已启用
3. 验证文件路径映射配置

# 问题: ESLint/Prettier 不工作
解决方案:
1. 确保相关扩展已安装并启用
2. 检查 .vscode/settings.json 配置
3. 重新加载窗口: Ctrl+Shift+P -> "Developer: Reload Window"
```

#### 2. 依赖安装问题
```bash
# 清除缓存
npm cache clean --force
rm -rf node_modules package-lock.json
npm install

# 使用 yarn 替代
npm install -g yarn
yarn install
```

#### 3. TypeScript 编译错误
```bash
# 重新生成类型声明
npx tsc --noEmit

# 检查 tsconfig.json 配置
npx tsc --showConfig

# 如果VS Code中仍有错误，尝试:
# 1. 重启TypeScript服务器
# 2. 重启VS Code
# 3. 检查工作区配置
```

#### 4. 开发服务器问题
```bash
# Vite 开发服务器启动失败
npm run dev

# 端口被占用
# Vite会自动尝试其他端口 (3001, 3002等)

# 热重载不工作
# 检查文件保存，确保修改被检测到
# 重启开发服务器
```

#### 5. 样式问题
```bash
# Tailwind CSS 样式不生效
# 检查 CDN 链接是否正确
# 确认类名拼写正确
```

#### 4. 构建问题
```bash
# 构建失败
npm run clean  # 清除构建缓存
npm run build  # 重新构建

# 检查环境变量
echo $NODE_ENV
```

### 获取帮助
- **项目 Issues**: [GitHub Issues](https://github.com/barbarossia/GCCC/issues)
- **技术讨论**: [GitHub Discussions](https://github.com/barbarossia/GCCC/discussions)
- **邮件支持**: dev@gccc.com
- **文档更新**: 欢迎提交 PR 改进文档

---

**🎯 目标**: 构建现代化、可扩展、用户友好的 Web3 应用前端

**🌟 愿景**: 为 GCCC 生态系统提供世界级的用户体验

这个完整的开发指南为 GCCC 前端项目提供了从开发到部署的全面指导，确保项目能够高质量、高效率地推进。

## 🧪 测试指南

### 测试策略
我们采用多层测试策略确保代码质量和功能稳定性:

#### 1. 单元测试 (Unit Tests)
```bash
# 安装测试依赖
npm install --save-dev vitest @testing-library/react @testing-library/jest-dom
npm install --save-dev @testing-library/user-event jsdom

# 运行单元测试
npm run test

# 监听模式
npm run test:watch

# 覆盖率报告
npm run test:coverage
```

**测试文件结构**:
```
tests/                          # 前端测试目录
├── setup.ts                    # 测试环境配置
├── basic.test.ts              # 基础功能测试
├── auth-service.test.ts       # 认证服务测试
└── [component-tests]/         # 组件测试 (计划添加)
    ├── AuthApp.test.tsx
    ├── LoginForm.test.tsx
    └── Dashboard.test.tsx
```

**示例测试用例**:
```typescript
// tests/components/LoginForm.test.tsx
import { render, screen } from '@testing-library/react';
import { AuthProvider } from '../../src/contexts/AuthContext';
import { LoginForm } from '../../src/components/LoginForm';

describe('LoginForm Component', () => {
  test('renders login form fields', () => {
    render(
      <AuthProvider>
        <LoginForm />
      </AuthProvider>
    );
    expect(screen.getByLabelText('邮箱地址')).toBeInTheDocument();
    expect(screen.getByLabelText('密码')).toBeInTheDocument();
  });
});

// tests/auth-service.test.ts
import { authService } from '../src/utils/authService';

describe('Auth Service', () => {
  test('signIn with valid credentials', async () => {
    const credentials = {
      email: 'admin@gccc.com',
      password: 'admin123'
    };
    const response = await authService.signIn(credentials);
    expect(response.success).toBe(true);
    expect(response.data.role).toBe('admin');
  });
});
```

#### 2. 集成测试 (Integration Tests)
```bash
# 测试组件间集成
npm run test:integration

# 示例: 认证流程集成测试 (../test/frontend/integration/auth.test.tsx)
describe('Authentication Flow', () => {
  test('complete sign-in process', async () => {
    render(<App />);
    
    // 填写登录表单
    await userEvent.type(screen.getByLabelText('邮箱地址'), 'admin@gccc.com');
    await userEvent.type(screen.getByLabelText('密码'), 'admin123');
    await userEvent.click(screen.getByRole('button', { name: '登录' }));
    
    // 验证登录成功
    await waitFor(() => {
      expect(screen.getByText('欢迎回来')).toBeInTheDocument();
    });
  });
});
```

#### 3. 端到端测试 (E2E Tests)
```bash
# 安装 Playwright
npm install --save-dev @playwright/test

# 运行 E2E 测试
npm run test:e2e

# 可视化测试
npm run test:e2e:ui
```

**E2E 测试示例**:
```typescript
// ../test/e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test('user can sign in and access dashboard', async ({ page }) => {
  await page.goto('http://localhost:3000');
  
  // 登录
  await page.fill('[name="email"]', 'admin@gccc.com');
  await page.fill('[name="password"]', 'admin123');
  await page.click('button[type="submit"]');
  
  // 验证仪表板
  await expect(page.locator('h2')).toContainText('admin');
  await expect(page.locator('.glass-effect')).toBeVisible();
});

test('user registration flow', async ({ page }) => {
  await page.goto('http://localhost:3000');
  
  // 切换到注册页面
  await page.click('text=立即注册');
  
  // 填写注册表单
  await page.fill('[name="email"]', 'newuser@test.com');
  await page.fill('[name="username"]', 'newuser');
  await page.fill('[name="password"]', 'password123');
  await page.fill('[name="confirmPassword"]', 'password123');
  await page.check('[name="agreeToTerms"]');
  
  // 提交注册
  await page.click('button[type="submit"]');
  
  // 验证注册成功
  await expect(page.locator('h2')).toContainText('newuser');
});
```

### 手动测试

#### 功能测试清单
```bash
# 认证功能
□ 登录表单验证 (空字段、格式验证)
□ 注册表单验证 (密码匹配、用户协议)
□ 登录成功跳转
□ 注册成功跳转
□ 错误消息显示
□ 加载状态显示

# 用户仪表板
□ 用户信息显示 (头像、用户名、邮箱)
□ 角色标签显示 (管理员/普通用户)
□ 统计数据显示 (经验值、推荐数等)
□ 退出登录功能

# 会话管理
□ 登录状态持久化 (刷新页面)
□ 自动登录 (重新访问)
□ 登出清除状态

# 响应式设计
□ 桌面端布局 (1920x1080)
□ 平板端布局 (768x1024)
□ 手机端布局 (375x667)
□ 触摸交互 (移动设备)

# 浏览器兼容性
□ Chrome (latest)
□ Firefox (latest)
□ Safari (latest)
□ Edge (latest)
```

#### 性能测试
```bash
# 使用浏览器开发者工具
1. Network 标签: 检查资源加载时间
2. Performance 标签: 分析渲染性能
3. Lighthouse: 获取性能评分

# 关键指标
- First Contentful Paint (FCP) < 1.5s
- Largest Contentful Paint (LCP) < 2.5s
- Cumulative Layout Shift (CLS) < 0.1
- First Input Delay (FID) < 100ms
```

#### 可访问性测试
```bash
# 工具推荐
- axe DevTools (浏览器扩展)
- WAVE Web Accessibility Evaluation Tool
- 键盘导航测试

# 检查项目
□ 键盘导航 (Tab, Enter, Esc)
□ 屏幕阅读器兼容
□ 颜色对比度
□ ARIA 标签
□ 焦点管理
```

### 测试环境配置

#### vitest.config.ts
```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'tests/',
        '**/*.d.ts',
      ],
    },
  },
});
```

#### 测试覆盖率目标
- **语句覆盖率**: > 80%
- **分支覆盖率**: > 75%
- **函数覆盖率**: > 80%
- **行覆盖率**: > 80%

## 🚀 部署指南

### 部署策略

#### 1. 静态部署 (推荐快速部署)
适用于当前的单HTML文件应用:

```bash
# 准备部署文件
cp auth-app.html index.html

# 方式1: Netlify 部署
# 1. 访问 https://netlify.com
# 2. 拖拽 auth-app.html 到部署区域
# 3. 获得部署链接

# 方式2: Vercel 部署
npx vercel --prod

# 方式3: GitHub Pages 部署
git add auth-app.html
git commit -m "deploy: add static auth app"
git push origin main
# 在 GitHub repo settings 中启用 Pages
```

#### 2. React 应用部署
适用于完整的React开发环境:

```bash
# 构建生产版本
npm run build

# 部署到 Vercel
npm install -g vercel
vercel --prod

# 部署到 Netlify
npm install -g netlify-cli
netlify deploy --prod --dir=dist

# 部署到 GitHub Pages
npm run build
npm install -g gh-pages
gh-pages -d dist
```

### 环境配置

#### 1. 开发环境 (Development)
```bash
# 环境变量: .env.development
VITE_API_BASE_URL=http://localhost:3001/api
VITE_ENVIRONMENT=development
VITE_DEBUG=true

# 特点:
- 热重载开发服务器
- 详细错误信息
- 开发者工具启用
- 模拟数据服务
```

#### 2. 测试环境 (Staging)
```bash
# 环境变量: .env.staging
VITE_API_BASE_URL=https://staging-api.gccc.com/api
VITE_ENVIRONMENT=staging
VITE_DEBUG=false

# 特点:
- 与生产环境相似的配置
- 测试数据库
- 性能监控
- 用户验收测试
```

#### 3. 生产环境 (Production)
```bash
# 环境变量: .env.production
VITE_API_BASE_URL=https://api.gccc.com/api
VITE_ENVIRONMENT=production
VITE_DEBUG=false
VITE_ANALYTICS_ID=GA_TRACKING_ID

# 特点:
- 最小化和压缩代码
- 错误监控 (Sentry)
- 性能分析
- CDN 加速
```

### CI/CD 管道

#### GitHub Actions 配置
```yaml
# .github/workflows/deploy.yml
name: Deploy Frontend

on:
  push:
    branches: [ main ]
    paths: [ 'src/frontend/**' ]
  pull_request:
    branches: [ main ]
    paths: [ 'src/frontend/**' ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: src/frontend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd src/frontend
          npm ci
      
      - name: Run tests
        run: |
          cd src/frontend
          npm run test:coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          directory: src/frontend/coverage

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: src/frontend/package-lock.json
      
      - name: Install dependencies
        run: |
          cd src/frontend
          npm ci
      
      - name: Build application
        run: |
          cd src/frontend
          npm run build
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-files
          path: src/frontend/dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-files
          path: dist
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: dist
```

### 性能优化

#### 1. 构建优化
```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    target: 'es2015',
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          utils: ['./src/utils/authService', './src/utils/mockData'],
        },
      },
    },
  },
  optimizeDeps: {
    include: ['react', 'react-dom'],
  },
});
```

#### 2. 资源优化
```bash
# 图片优化
npm install --save-dev vite-plugin-imagemin

# 压缩优化
npm install --save-dev vite-plugin-compression

# PWA 支持
npm install --save-dev vite-plugin-pwa
```

#### 3. CDN 配置
```html
<!-- 使用 CDN 加速常用库 -->
<script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
<script src="https://cdn.tailwindcss.com"></script>
```

### 监控和分析

#### 1. 错误监控
```bash
# 安装 Sentry
npm install @sentry/react @sentry/tracing

# 配置错误捕获
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "YOUR_SENTRY_DSN",
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});
```

#### 2. 性能分析
```bash
# Google Analytics
npm install gtag

# Web Vitals 监控
npm install web-vitals
```

#### 3. 安全配置
```bash
# Content Security Policy
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' unpkg.com cdn.tailwindcss.com; style-src 'self' 'unsafe-inline' cdn.tailwindcss.com; img-src 'self' data: api.dicebear.com;

# HTTPS 重定向
# 在 Vercel/Netlify 中自动处理

# 安全头部
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

### 域名和SSL

#### 1. 自定义域名
```bash
# Vercel 配置
vercel domains add your-domain.com

# Netlify 配置
netlify sites:update --name=your-site-name --custom-domain=your-domain.com
```

#### 2. SSL 证书
```bash
# 自动 HTTPS (Vercel/Netlify 自动提供)
# Let's Encrypt 免费证书
# 自动续期
```

### 部署检查清单

#### 部署前检查
```bash
□ 运行所有测试 (npm run test)
□ 检查类型错误 (npm run type-check)
□ 构建成功 (npm run build)
□ 性能审核 (Lighthouse)
□ 安全扫描
□ 可访问性检查
□ 浏览器兼容性测试
```

#### 部署后验证
```bash
□ 网站可访问
□ 所有功能正常
□ 性能指标达标
□ 错误监控配置
□ 分析工具配置
□ SSL 证书有效
□ 移动端适配
□ SEO 优化
```

### 回滚策略
```bash
# Vercel 回滚
vercel rollback [deployment-url]

# Git 回滚
git revert HEAD
git push origin main

# 蓝绿部署
# 保持两个环境，快速切换
```

这个完整的部署指南确保了 GCCC 前端应用能够安全、稳定、高效地部署到生产环境。
