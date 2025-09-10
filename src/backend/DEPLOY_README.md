# GCCC 后端一键部署系统

一个完整的 Docker 化后端部署解决方案，包括自动化部署、测试和监控功能。

## 📦 部署脚本概览

| 脚本文件 | 功能描述 | 主要用途 |
|---------|----------|----------|
| `deploy_backend.ps1` | 主要部署脚本 | 一键部署后端服务 |
| `run_tests.ps1` | 测试运行脚本 | 执行单元测试和集成测试 |
| `check_backend_status.ps1` | 状态检查脚本 | 监控服务健康状态 |
| `docker-healthcheck.sh` | Docker 健康检查 | 容器内健康监控 |

## 🚀 快速开始

### 1. 一键部署（开发环境）

```powershell
.\deploy_backend.ps1
```

### 2. 生产环境部署

```powershell
.\deploy_backend.ps1 -Environment production -Force
```

### 3. 运行测试

```powershell
.\run_tests.ps1
```

### 4. 检查服务状态

```powershell
.\check_backend_status.ps1
```

## 📋 详细功能

### 部署脚本 (deploy_backend.ps1)

**支持的环境：**
- `development` - 开发环境（默认）
- `test` - 测试环境
- `production` - 生产环境

**主要功能：**
- ✅ 自动检测和配置依赖服务
- ✅ 多阶段 Docker 镜像构建
- ✅ 自动健康检查
- ✅ 服务编排和网络配置
- ✅ 错误处理和回滚

**常用命令：**

```powershell
# 基本部署
.\deploy_backend.ps1

# 指定环境
.\deploy_backend.ps1 -Environment production

# 强制重新部署
.\deploy_backend.ps1 -Force

# 只构建不启动
.\deploy_backend.ps1 -BuildOnly

# 跳过测试快速部署
.\deploy_backend.ps1 -SkipTests

# 包含数据库服务
.\deploy_backend.ps1 -WithDatabase

# 查看帮助
.\deploy_backend.ps1 -Help
```

### 测试脚本 (run_tests.ps1)

**测试类型：**
- `unit` - 单元测试
- `integration` - 集成测试
- `coverage` - 覆盖率测试
- `all` - 全部测试（默认）

**主要功能：**
- ✅ 独立测试环境
- ✅ 覆盖率报告生成
- ✅ 观察模式（开发时使用）
- ✅ 详细测试日志
- ✅ 自动环境清理

**常用命令：**

```powershell
# 运行所有测试
.\run_tests.ps1

# 单元测试
.\run_tests.ps1 -TestType unit

# 覆盖率测试
.\run_tests.ps1 -Coverage

# 观察模式（开发时）
.\run_tests.ps1 -Watch

# 保持容器用于调试
.\run_tests.ps1 -KeepContainers

# 详细输出
.\run_tests.ps1 -Verbose
```

### 状态检查脚本 (check_backend_status.ps1)

**检查项目：**
- 🔍 容器状态检查
- 🔍 API 健康端点检查
- 🔍 数据库连接检查
- 🔍 Redis 连接检查
- 🔍 服务日志分析

**常用命令：**

```powershell
# 完整状态检查
.\check_backend_status.ps1

# 简要检查
.\check_backend_status.ps1 -Brief

# 显示服务日志
.\check_backend_status.ps1 -ShowLogs

# 指定服务 URL
.\check_backend_status.ps1 -Url http://localhost:3001
```

## 🐳 Docker 配置

### 多阶段构建支持

- `base` - Alpine Linux 基础镜像
- `dev-dependencies` - 开发依赖环境
- `prod-dependencies` - 生产依赖环境
- `build` - 应用构建阶段
- `test` - 测试专用环境
- `production` - 生产运行环境
- `development` - 开发热重载环境

### 健康检查

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD ./docker-healthcheck.sh
```

## 📊 监控和日志

### 查看容器状态

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 查看服务日志

```powershell
# 实时日志
docker logs -f gccc-backend

# 历史日志
docker logs gccc-backend --tail 100
```

### 健康检查历史

```powershell
docker inspect gccc-backend --format='{{json .State.Health}}'
```

## 🔧 故障排除

### 常见问题解决

1. **端口冲突**
   ```powershell
   # 检查端口占用
   netstat -ano | findstr :3000
   
   # 修改端口映射
   -p "3001:3000"
   ```

2. **依赖服务未启动**
   ```powershell
   # 检查数据库服务
   cd ..\database
   .\deploy_database.ps1 -Action status
   ```

3. **镜像构建失败**
   ```powershell
   # 清理 Docker 缓存
   docker system prune -a
   
   # 重新构建
   .\deploy_backend.ps1 -Force -BuildOnly
   ```

### 调试模式

```powershell
# 进入容器调试
docker exec -it gccc-backend sh

# 查看容器内文件
docker exec gccc-backend ls -la /app

# 检查环境变量
docker exec gccc-backend env
```

## 📁 文件结构

```
backend/
├── 🚀 deploy_backend.ps1      # 主部署脚本
├── 🧪 run_tests.ps1           # 测试运行脚本  
├── 📊 check_backend_status.ps1 # 状态检查脚本
├── 🐳 Dockerfile              # 多阶段构建文件
├── 🐳 docker-compose.test.yml # 测试环境配置
├── 🩺 docker-healthcheck.sh   # 健康检查脚本
├── 📚 DEPLOYMENT_GUIDE.md     # 详细部署指南
└── 🔧 .dockerignore           # Docker 忽略文件
```

## 🔐 安全考虑

- ✅ 非 root 用户运行容器
- ✅ Alpine Linux 安全基础镜像
- ✅ 最小化镜像层和依赖
- ✅ 健康检查和故障恢复
- ✅ 网络隔离和端口管理

## 📈 性能优化

- ✅ 多阶段构建减小镜像大小
- ✅ Node.js 生产优化配置
- ✅ Docker 构建缓存优化
- ✅ 资源使用监控

## 📖 更多信息

- 详细部署指南: [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md)
- API 文档: [API Documentation](./docs/api.md)
- 项目主页: [README.md](./README.md)

## 🤝 支持与贡献

如需帮助或发现问题：
1. 查看 [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md) 详细说明
2. 运行 `.\check_backend_status.ps1` 诊断问题
3. 联系 GCCC 开发团队

---

**版本**: 1.0.0  
**更新**: 2025-01-05  
**维护者**: GCCC 开发团队
