# GCCC 后端部署指南

## 概述

本文档提供了 GCCC 后端服务的完整部署指南，包括 Docker 容器化部署、测试运行和监控。

## 前置要求

### 系统要求
- Docker 20.10 或更高版本
- Docker Compose 1.29 或更高版本
- PowerShell 5.1 或更高版本（Windows）
- 至少 2GB 可用内存
- 至少 10GB 可用磁盘空间

### 依赖服务
- PostgreSQL 数据库（可通过数据库部署脚本启动）
- Redis 缓存服务（可通过数据库部署脚本启动）

## 快速开始

### 1. 部署数据库服务（如果未部署）

```powershell
# 在 database 目录运行
cd ..\database
.\deploy_database.ps1 -StartServices
```

### 2. 部署后端服务

```powershell
# 在 backend 目录运行
.\deploy_backend.ps1
```

### 3. 验证部署

```powershell
# 检查服务状态
.\check_backend_status.ps1

# 或者手动检查
docker ps
curl http://localhost:3000/api/health
```

## 详细部署选项

### deploy_backend.ps1 参数

```powershell
# 基本部署
.\deploy_backend.ps1

# 指定环境和构建选项
.\deploy_backend.ps1 -Environment production -Build -RunTests

# 跳过测试的快速部署
.\deploy_backend.ps1 -SkipTests -SkipHealthCheck

# 强制重新构建
.\deploy_backend.ps1 -ForceRebuild -CleanUp

# 调试模式部署
.\deploy_backend.ps1 -Environment development -Verbose

# 保持容器用于调试
.\deploy_backend.ps1 -KeepContainers
```

### 参数说明

- `-Environment`: 部署环境 (development, test, production)
- `-Build`: 强制重新构建镜像
- `-RunTests`: 部署前运行测试
- `-SkipTests`: 跳过测试
- `-SkipHealthCheck`: 跳过健康检查
- `-ForceRebuild`: 强制重新构建所有镜像
- `-CleanUp`: 部署前清理旧容器
- `-KeepContainers`: 保持容器运行用于调试
- `-Verbose`: 详细输出模式

## 测试

### 运行所有测试

```powershell
.\run_tests.ps1
```

### 特定测试类型

```powershell
# 单元测试
.\run_tests.ps1 -TestType unit

# 集成测试
.\run_tests.ps1 -TestType integration

# 覆盖率测试
.\run_tests.ps1 -Coverage

# 观察模式（开发时使用）
.\run_tests.ps1 -Watch
```

### 测试环境配置

测试会使用独立的数据库和 Redis 实例：
- 测试数据库端口：5433
- 测试 Redis 端口：6380
- 测试 API 端口：3001

## 监控与健康检查

### 健康检查脚本

```powershell
# 完整状态检查
.\check_backend_status.ps1

# 简要状态检查
.\check_backend_status.ps1 -Brief

# 详细日志输出
.\check_backend_status.ps1 -ShowLogs
```

### 手动健康检查

```powershell
# API 健康检查
curl http://localhost:3000/api/health

# 数据库连接检查
curl http://localhost:3000/api/health/database

# Redis 连接检查
curl http://localhost:3000/api/health/redis
```

### Docker 健康检查

Docker 容器内置健康检查，会自动监控服务状态：

```powershell
# 查看健康状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 查看健康检查历史
docker inspect gccc-backend --format='{{json .State.Health}}'
```

## 环境配置

### 开发环境

```powershell
# 启动开发模式（热重载）
.\deploy_backend.ps1 -Environment development

# 查看实时日志
docker logs -f gccc-backend-dev
```

### 生产环境

```powershell
# 生产部署
.\deploy_backend.ps1 -Environment production -Build -RunTests

# 性能优化部署
.\deploy_backend.ps1 -Environment production -ForceRebuild -CleanUp
```

### 测试环境

```powershell
# 测试环境部署
.\deploy_backend.ps1 -Environment test -RunTests

# 持续测试
.\run_tests.ps1 -Watch -KeepContainers
```

## 故障排除

### 常见问题

1. **端口冲突**
   ```powershell
   # 检查端口占用
   netstat -ano | findstr :3000
   
   # 修改端口（在 docker-compose.yml 中）
   ports:
     - "3001:3000"
   ```

2. **数据库连接失败**
   ```powershell
   # 检查数据库状态
   docker ps | findstr postgres
   
   # 重启数据库服务
   cd ..\database
   .\deploy_database.ps1 -RestartServices
   ```

3. **Redis 连接失败**
   ```powershell
   # 检查 Redis 状态
   docker ps | findstr redis
   
   # 重新部署数据库服务
   cd ..\database
   .\deploy_database.ps1 -ForceRebuild
   ```

4. **镜像构建失败**
   ```powershell
   # 清理 Docker 缓存
   docker system prune -a
   
   # 重新构建
   .\deploy_backend.ps1 -ForceRebuild
   ```

### 日志查看

```powershell
# 后端服务日志
docker logs gccc-backend

# 实时日志
docker logs -f gccc-backend

# 测试日志
docker logs gccc-backend-test

# 所有服务日志
docker-compose logs -f
```

### 容器调试

```powershell
# 进入运行中的容器
docker exec -it gccc-backend sh

# 以调试模式启动
.\deploy_backend.ps1 -Environment development -KeepContainers

# 检查容器内文件
docker exec gccc-backend ls -la /app
```

## 性能优化

### 镜像优化
- 使用多阶段构建减小镜像大小
- 合理使用 .dockerignore 排除不必要文件
- 使用 Alpine 基础镜像

### 运行优化
- 配置合适的健康检查间隔
- 设置资源限制
- 使用 PM2 进行进程管理

### 监控优化
- 启用详细日志记录
- 配置性能监控
- 设置告警阈值

## 安全建议

1. **容器安全**
   - 使用非 root 用户运行
   - 定期更新基础镜像
   - 扫描安全漏洞

2. **网络安全**
   - 使用 Docker 网络隔离
   - 限制容器间通信
   - 配置防火墙规则

3. **数据安全**
   - 加密敏感环境变量
   - 定期备份数据库
   - 使用安全的密钥管理

## 维护指南

### 定期维护

```powershell
# 清理未使用的镜像和容器
docker system prune -a

# 更新依赖
npm audit fix

# 备份数据
.\backup_data.ps1
```

### 版本升级

```powershell
# 停止服务
docker-compose down

# 更新代码
git pull

# 重新部署
.\deploy_backend.ps1 -ForceRebuild -RunTests
```

## 支持与联系

如遇到问题，请：
1. 查看日志文件
2. 检查健康状态
3. 参考故障排除指南
4. 联系开发团队

---

**版本**: 1.0.0  
**更新日期**: $(Get-Date -Format 'yyyy-MM-dd')  
**维护者**: GCCC 开发团队
