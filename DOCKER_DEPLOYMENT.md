# GCCC Docker 部署指南

## 概述

本指南介绍如何使用 Docker 和 Docker Compose 部署 GCCC DApp 的完整服务栈，包括 PostgreSQL 数据库、Redis 缓存、Node.js API 服务器和 Nginx 反向代理。

## 系统要求

### 最低配置

- **CPU**: 2 核心
- **内存**: 4GB RAM
- **存储**: 20GB 可用空间
- **操作系统**: Linux, macOS, Windows (with WSL2)

### 推荐配置 (生产环境)

- **CPU**: 4 核心或以上
- **内存**: 8GB RAM 或以上
- **存储**: 50GB SSD
- **网络**: 稳定的互联网连接

### 软件依赖

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/barbarossia/GCCC.git
cd GCCC
```

### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
nano .env
```

**重要配置项：**

- `DB_PASSWORD`: 数据库密码（生产环境必须更改）
- `JWT_SECRET`: JWT 密钥（至少 32 字符）
- `SOLANA_NETWORK`: Solana 网络 (mainnet-beta/devnet/testnet)
- `GCCC_TOKEN_MINT`: GCCC 代币地址
- `CORS_ORIGIN`: 前端域名

### 3. 启动服务

```bash
# 启动完整服务栈
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 4. 验证部署

```bash
# 检查API健康状态
curl http://localhost:3000/health

# 检查数据库连接
docker-compose exec database /scripts/health_check.sh

# 查看数据库表
docker-compose exec database psql -U gccc_user -d gccc_db -c "\dt"
```

## 服务架构

### 服务组件

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Nginx    │────│   Backend   │────│ PostgreSQL  │
│   (Port 80) │    │ (Port 3000) │    │(Port 5432)  │
└─────────────┘    └─────────────┘    └─────────────┘
                           │
                   ┌─────────────┐
                   │    Redis    │
                   │ (Port 6379) │
                   └─────────────┘
```

### 端口映射

- **80**: Nginx HTTP (可选)
- **443**: Nginx HTTPS (可选)
- **3000**: Backend API
- **5432**: PostgreSQL 数据库
- **6379**: Redis 缓存

## 部署模式

### 开发模式

```bash
# 启动开发环境 (支持热重载)
docker-compose --profile development up -d

# 进入后端容器调试
docker-compose exec backend-dev sh
```

### 生产模式

```bash
# 启动生产环境
docker-compose up -d

# 启动带 Nginx 反向代理的生产环境
docker-compose --profile with-nginx up -d
```

## 数据管理

### 数据库备份

```bash
# 创建备份
docker-compose exec database /scripts/backup.sh

# 查看备份文件
docker-compose exec database ls -la /backups/

# 下载备份到本地
docker cp gccc-database:/backups/gccc_backup_20240904_120000.sql.gz ./
```

### 数据库恢复

```bash
# 从备份恢复
docker-compose exec database /scripts/restore.sh /backups/backup_file.sql.gz

# 从本地文件恢复
docker cp ./backup.sql gccc-database:/tmp/
docker-compose exec database /scripts/restore.sh /tmp/backup.sql
```

### 数据持久化

```bash
# 查看数据卷
docker volume ls | grep gccc

# 备份数据卷
docker run --rm -v gccc_db_data:/data -v $(pwd):/backup alpine tar czf /backup/gccc_db_data.tar.gz /data

# 恢复数据卷
docker run --rm -v gccc_db_data:/data -v $(pwd):/backup alpine tar xzf /backup/gccc_db_data.tar.gz -C /
```

## 监控和维护

### 查看服务状态

```bash
# 查看所有服务
docker-compose ps

# 查看服务资源使用
docker-compose top

# 查看服务日志
docker-compose logs -f backend
docker-compose logs -f database
```

### 性能监控

```bash
# 查看容器资源使用
docker stats

# 查看数据库连接数
docker-compose exec database psql -U gccc_user -d gccc_db -c "SELECT count(*) FROM pg_stat_activity;"

# 查看数据库大小
docker-compose exec database psql -U gccc_user -d gccc_db -c "SELECT pg_size_pretty(pg_database_size('gccc_db'));"
```

### 日志管理

```bash
# 查看日志文件大小
docker-compose exec backend du -sh /app/logs/

# 清理旧日志
docker-compose exec backend find /app/logs/ -name "*.log" -mtime +7 -delete
```

## 扩展和优化

### 水平扩展

```bash
# 扩展后端服务实例
docker-compose up -d --scale backend=3

# 查看负载均衡状态
docker-compose ps backend
```

### 性能优化

```yaml
# docker-compose.override.yml
version: "3.8"
services:
  database:
    command:
      [
        "postgres",
        "-c",
        "max_connections=500",
        "-c",
        "shared_buffers=512MB",
        "-c",
        "effective_cache_size=2GB",
      ]

  backend:
    environment:
      NODE_ENV: production
      NODE_OPTIONS: "--max-old-space-size=2048"
```

## 安全配置

### SSL/TLS 配置

```bash
# 生成自签名证书 (仅用于测试)
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=GCCC/CN=localhost"
```

### 防火墙配置

```bash
# 仅允许必要端口
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw deny 3000   # 阻止直接访问后端
sudo ufw deny 5432   # 阻止直接访问数据库
sudo ufw enable
```

## 故障排除

### 常见问题

1. **容器启动失败**

```bash
# 查看详细错误信息
docker-compose logs container_name

# 检查配置文件语法
docker-compose config
```

2. **数据库连接失败**

```bash
# 检查数据库是否就绪
docker-compose exec database pg_isready

# 检查网络连接
docker-compose exec backend ping database
```

3. **内存不足**

```bash
# 查看系统资源
free -h
df -h

# 限制容器内存使用
docker-compose up -d --memory="1g" backend
```

### 调试命令

```bash
# 进入容器内部
docker-compose exec backend sh
docker-compose exec database bash

# 查看容器配置
docker inspect gccc-backend

# 重启特定服务
docker-compose restart backend

# 强制重新构建
docker-compose build --no-cache
```

## 更新和升级

### 应用更新

```bash
# 拉取最新代码
git pull origin main

# 重新构建镜像
docker-compose build --no-cache

# 滚动更新 (零停机)
docker-compose up -d --no-deps backend
```

### 数据库迁移

```bash
# 运行数据库迁移
docker-compose exec backend npm run migrate

# 检查迁移状态
docker-compose exec database psql -U gccc_user -d gccc_db -c "SELECT * FROM get_migration_status();"
```

## 生产环境检查清单

- [ ] 更改所有默认密码
- [ ] 配置强 JWT 密钥
- [ ] 设置正确的 CORS 域名
- [ ] 启用 SSL/TLS 证书
- [ ] 配置防火墙规则
- [ ] 设置自动备份
- [ ] 配置监控告警
- [ ] 限制容器资源使用
- [ ] 设置日志轮转
- [ ] 测试灾难恢复流程

## 支持和维护

- **文档**: [项目 README](./README.md)
- **API 文档**: http://localhost:3000/docs
- **问题报告**: [GitHub Issues](https://github.com/barbarossia/GCCC/issues)
- **社区**: [Discord](https://discord.gg/gccc)

---

💡 **提示**: 生产环境部署前请仔细阅读安全配置章节，确保所有安全措施得到正确实施。
