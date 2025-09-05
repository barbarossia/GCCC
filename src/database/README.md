# GCCC 数据库一键部署脚本

## 概述

该目录包含GCCC项目的数据库一键部署脚本，支持使用Docker自动部署PostgreSQL和Redis数据库。

## 文件说明

```
src/database/
├── deploy_database.ps1     # PowerShell版本部署脚本
├── deploy_database.sh      # Bash版本部署脚本
├── check_status.ps1        # PowerShell版本状态检查脚本
├── check_status.sh         # Bash版本状态检查脚本
├── docker-compose.yml      # Docker Compose配置文件 (自动生成)
├── .env.development        # 开发环境配置 (自动生成)
├── .env.test              # 测试环境配置 (自动生成)
├── .env.production        # 生产环境配置 (自动生成)
├── init/                  # 数据库初始化脚本目录
├── data/                  # 数据库数据存储目录
└── backups/               # 数据库备份目录
```

## 快速开始

### Windows (PowerShell)

```powershell
# 部署开发环境数据库
.\deploy_database.ps1

# 部署生产环境数据库
.\deploy_database.ps1 -Environment production

# 检查数据库状态
.\check_status.ps1

# 强制重新部署
.\deploy_database.ps1 -Force

# 停止数据库服务
.\deploy_database.ps1 -Action stop

# 清理数据库部署（谨慎使用）
.\deploy_database.ps1 -Action clean -Force
```

### Linux/macOS (Bash)

```bash
# 设置执行权限（首次运行）
chmod +x deploy_database.sh check_status.sh

# 部署开发环境数据库
./deploy_database.sh

# 部署生产环境数据库
./deploy_database.sh -e production

# 检查数据库状态
./check_status.sh

# 强制重新部署
./deploy_database.sh -f

# 停止数据库服务
./deploy_database.sh -a stop

# 清理数据库部署（谨慎使用）
./deploy_database.sh -a clean -f
```

## 功能特性

### 部署脚本功能

- ✅ **Docker容器化部署**: 使用Docker Compose自动部署PostgreSQL 15和Redis 7
- ✅ **多环境支持**: 支持development、test、production三种环境
- ✅ **自动配置管理**: 自动生成环境配置文件和Docker Compose配置
- ✅ **健康检查**: 内置数据库连接和服务健康检查
- ✅ **数据持久化**: 数据存储在本地目录，支持备份和恢复
- ✅ **一键操作**: 支持部署、停止、重启、清理等一键操作
- ✅ **错误处理**: 完善的错误处理和回滚机制
- ✅ **跨平台**: 同时支持Windows PowerShell和Linux/macOS Bash

### 状态检查功能

- ✅ **连接检查**: 检查PostgreSQL和Redis数据库连接
- ✅ **结构验证**: 验证数据库表结构和函数数量
- ✅ **扩展检查**: 检查必要的PostgreSQL扩展安装情况
- ✅ **迁移状态**: 检查数据库迁移执行状态
- ✅ **健康监控**: 运行自定义健康检查函数
- ✅ **详细报告**: 生成完整的数据库状态报告

## 环境配置

### 开发环境 (development)

- PostgreSQL端口: 5432
- Redis端口: 6379
- 数据库名: gccc_development_db
- 自动创建测试数据

### 测试环境 (test)

- PostgreSQL端口: 5433
- Redis端口: 6380
- 数据库名: gccc_test_db
- 仅基础结构，无测试数据

### 生产环境 (production)

- PostgreSQL端口: 5434
- Redis端口: 6381
- 数据库名: gccc_production_db
- 优化配置，增强安全性

## 数据库配置

### PostgreSQL 配置

```yaml
版本: PostgreSQL 15 Alpine
用户: gccc_user
密码: gccc_secure_password_2024
最大连接数: 200
共享缓冲区: 256MB
有效缓存: 1GB
```

### Redis 配置

```yaml
版本: Redis 7 Alpine
密码: redis_secure_password_2024
最大内存: 512MB
持久化: RDB + AOF
```

## 管理工具

### Adminer (可选)

部署后可以启用Adminer作为数据库管理工具：

```bash
# 启用Adminer
docker compose --profile admin up -d adminer

# 访问地址
http://localhost:8080
```

### 常用Docker命令

```bash
# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f

# 进入PostgreSQL容器
docker exec -it gccc-development-postgres psql -U gccc_user -d gccc_development_db

# 进入Redis容器
docker exec -it gccc-development-redis redis-cli

# 重启服务
docker compose restart

# 停止服务
docker compose stop

# 移除服务和数据
docker compose down -v
```

## 状态检查集成

部署脚本会自动调用状态检查脚本进行验证，确保：

1. 数据库连接正常
2. 表数量不少于20个
3. 函数数量不少于10个
4. 必要扩展已安装
5. 迁移状态正常
6. Redis服务可用

## 故障排除

### 常见问题

1. **Docker未安装或未启动**
   ```bash
   # 检查Docker状态
   docker --version
   docker compose version
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -an | grep 5432
   netstat -an | grep 6379
   ```

3. **权限问题**
   ```bash
   # Linux/macOS设置执行权限
   chmod +x *.sh
   
   # Windows可能需要管理员权限运行PowerShell
   ```

4. **数据库连接失败**
   - 检查防火墙设置
   - 验证用户名密码
   - 确认服务已启动

### 日志查看

```bash
# 查看部署日志
docker compose logs postgres
docker compose logs redis

# 查看实时日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f postgres
```

## 数据备份

### 自动备份

脚本会在部署时自动创建备份目录，可以设置定时任务：

```bash
# PostgreSQL备份
docker exec gccc-development-postgres pg_dump -U gccc_user gccc_development_db > ./backups/backup_$(date +%Y%m%d_%H%M%S).sql

# Redis备份
docker exec gccc-development-redis redis-cli BGSAVE
```

### 数据恢复

```bash
# PostgreSQL恢复
docker exec -i gccc-development-postgres psql -U gccc_user gccc_development_db < ./backups/backup_file.sql

# Redis恢复
docker cp backup.rdb gccc-development-redis:/data/dump.rdb
docker restart gccc-development-redis
```

## 安全注意事项

1. **生产环境**: 务必修改默认密码
2. **网络安全**: 生产环境不要暴露数据库端口到公网
3. **权限控制**: 使用最小权限原则
4. **定期备份**: 设置自动备份策略
5. **监控告警**: 配置数据库监控和告警

## 联系支持

如果在使用过程中遇到问题，请：

1. 查看日志文件
2. 运行状态检查脚本
3. 查阅故障排除章节
4. 联系开发团队

---

**版本**: 1.0.0  
**更新时间**: 2024-12-19  
**维护者**: GCCC开发团队
