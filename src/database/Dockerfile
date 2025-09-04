# ========================================
# GCCC Database Dockerfile
# PostgreSQL数据库容器配置
# ========================================

# 使用官方 PostgreSQL 15 镜像
FROM postgres:15-alpine

# 设置维护者信息
LABEL maintainer="GCCC Team"
LABEL description="GCCC DApp PostgreSQL Database with initial schema and data"
LABEL version="1.0.0"

# 设置环境变量
ENV POSTGRES_DB=gccc_db
ENV POSTGRES_USER=gccc_user
ENV POSTGRES_PASSWORD=gccc_password
ENV PGDATA=/var/lib/postgresql/data/pgdata

# 安装额外的工具
RUN apk add --no-cache \
    curl \
    bash \
    && rm -rf /var/cache/apk/*

# 创建必要的目录
RUN mkdir -p /docker-entrypoint-initdb.d
RUN mkdir -p /scripts
RUN mkdir -p /backups

# 复制数据库脚本到初始化目录
# PostgreSQL会按字母顺序执行这些脚本
COPY 01-database-init-config.sql /docker-entrypoint-initdb.d/01-database-init-config.sql
COPY 02-core-tables.sql /docker-entrypoint-initdb.d/02-core-tables.sql
COPY 03-business-tables.sql /docker-entrypoint-initdb.d/03-business-tables.sql
COPY 04-database-functions.sql /docker-entrypoint-initdb.d/04-database-functions.sql
COPY 05-initial-data.sql /docker-entrypoint-initdb.d/05-initial-data.sql

# 复制管理脚本
COPY deploy.sql /scripts/
COPY migrations.sql /scripts/
COPY check_status.sh /scripts/
COPY check_status.ps1 /scripts/

# 创建健康检查脚本
RUN cat > /scripts/health_check.sh << 'EOF'
#!/bin/bash
set -e

# 检查PostgreSQL是否可以连接
pg_isready -h localhost -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB"

# 检查数据库是否包含预期的表
TABLES_COUNT=$(psql -h localhost -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
    SELECT COUNT(*) 
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
" | tr -d ' ')

if [ "$TABLES_COUNT" -lt "20" ]; then
    echo "Database tables not properly initialized. Expected at least 20 tables, found $TABLES_COUNT"
    exit 1
fi

echo "Database health check passed. Found $TABLES_COUNT tables."
EOF

# 创建备份脚本
RUN cat > /scripts/backup.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_FILE="/backups/gccc_backup_$(date +%Y%m%d_%H%M%S).sql"

echo "Creating database backup: $BACKUP_FILE"
pg_dump -h localhost -p 5432 -U "$POSTGRES_USER" "$POSTGRES_DB" > "$BACKUP_FILE"

# 压缩备份文件
gzip "$BACKUP_FILE"

echo "Backup created: ${BACKUP_FILE}.gz"
EOF

# 创建恢复脚本
RUN cat > /scripts/restore.sh << 'EOF'
#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring database from: $BACKUP_FILE"

# 如果备份文件是压缩的，先解压
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | psql -h localhost -p 5432 -U "$POSTGRES_USER" "$POSTGRES_DB"
else
    psql -h localhost -p 5432 -U "$POSTGRES_USER" "$POSTGRES_DB" < "$BACKUP_FILE"
fi

echo "Database restored successfully"
EOF

# 设置脚本权限
RUN chmod +x /scripts/*.sh

# 创建自定义初始化脚本
RUN cat > /docker-entrypoint-initdb.d/99-final-setup.sql << 'EOF'
-- 最终设置和验证
\echo '=========================================='
\echo 'GCCC Database Initialization Complete'
\echo '=========================================='

-- 显示数据库统计信息
SELECT 
    'Tables' as type,
    COUNT(*)::text as count
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'

UNION ALL

SELECT 
    'Functions',
    COUNT(*)::text
FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION'

UNION ALL

SELECT 
    'System Configs',
    COUNT(*)::text
FROM system_configs

UNION ALL

SELECT 
    'Database Size',
    pg_size_pretty(pg_database_size(current_database()))
;

\echo '=========================================='
\echo 'Database is ready for use!'
\echo '=========================================='
EOF

# 设置健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /scripts/health_check.sh || exit 1

# 暴露PostgreSQL端口
EXPOSE 5432

# 数据卷
VOLUME ["/var/lib/postgresql/data", "/backups"]

# 使用默认的PostgreSQL启动命令
# 支持通过环境变量配置PostgreSQL参数
CMD ["postgres", \
     "-c", "shared_preload_libraries=pg_stat_statements", \
     "-c", "pg_stat_statements.track=all", \
     "-c", "log_destination=stderr", \
     "-c", "log_statement=all", \
     "-c", "log_duration=on", \
     "-c", "log_line_prefix='%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '", \
     "-c", "max_connections=200", \
     "-c", "shared_buffers=256MB", \
     "-c", "effective_cache_size=1GB", \
     "-c", "work_mem=4MB", \
     "-c", "maintenance_work_mem=64MB"]

# ========================================
# 使用说明：
#
# 构建镜像：
# docker build -t gccc-database:latest .
#
# 运行容器：
# docker run -d \
#   --name gccc-database \
#   -p 5432:5432 \
#   -e POSTGRES_PASSWORD=your_secure_password \
#   -v gccc_db_data:/var/lib/postgresql/data \
#   -v gccc_db_backups:/backups \
#   gccc-database:latest
#
# 创建备份：
# docker exec gccc-database /scripts/backup.sh
#
# 恢复备份：
# docker exec gccc-database /scripts/restore.sh /backups/backup_file.sql.gz
#
# 健康检查：
# docker exec gccc-database /scripts/health_check.sh
# ========================================
