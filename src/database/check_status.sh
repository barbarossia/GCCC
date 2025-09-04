#!/bin/bash

# ================================================================
# GCCC 数据库状态检查脚本
# 用于验证数据库部署状态和健康检查
# ================================================================

echo "==================================="
echo "GCCC 数据库状态检查"
echo "==================================="

# 数据库连接参数
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-gccc_db}"
DB_USER="${DB_USER:-postgres}"

echo "连接参数:"
echo "  主机: $DB_HOST"
echo "  端口: $DB_PORT"
echo "  数据库: $DB_NAME"
echo "  用户: $DB_USER"
echo ""

# 检查数据库连接
echo "1. 检查数据库连接..."
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
    echo "   ✓ 数据库连接正常"
else
    echo "   ✗ 数据库连接失败"
    echo "请检查数据库是否运行，连接参数是否正确"
    exit 1
fi

echo ""

# 检查表数量
echo "2. 检查表结构..."
TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) 
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
" 2>/dev/null | tr -d ' ')

echo "   表数量: $TABLE_COUNT"
if [ "$TABLE_COUNT" -ge "20" ]; then
    echo "   ✓ 表结构完整"
else
    echo "   ✗ 表结构不完整，期望至少20个表"
fi

echo ""

# 检查函数
echo "3. 检查存储函数..."
FUNCTION_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
" 2>/dev/null | tr -d ' ')

echo "   函数数量: $FUNCTION_COUNT"
if [ "$FUNCTION_COUNT" -ge "10" ]; then
    echo "   ✓ 函数完整"
else
    echo "   ✗ 函数不完整，期望至少10个函数"
fi

echo ""

# 检查扩展
echo "4. 检查数据库扩展..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 
        extname as \"扩展名\",
        extversion as \"版本\"
    FROM pg_extension 
    WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin', 'pg_trgm')
    ORDER BY extname;
" 2>/dev/null

echo ""

# 检查初始数据
echo "5. 检查初始数据..."
CONFIG_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) FROM system_configs;
" 2>/dev/null | tr -d ' ')

USER_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) FROM users;
" 2>/dev/null | tr -d ' ')

POOL_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) FROM staking_pools;
" 2>/dev/null | tr -d ' ')

echo "   系统配置: $CONFIG_COUNT 条"
echo "   用户数据: $USER_COUNT 个"
echo "   质押池: $POOL_COUNT 个"

if [ "$CONFIG_COUNT" -ge "40" ]; then
    echo "   ✓ 初始数据完整"
else
    echo "   ✗ 初始数据不完整"
fi

echo ""

# 执行数据库健康检查
echo "6. 数据库健康检查..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT * FROM database_health_check();
" 2>/dev/null

echo ""

# 显示数据库大小
echo "7. 数据库信息..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 
        'Database Size' as \"信息类型\",
        pg_size_pretty(pg_database_size(current_database())) as \"值\"
    UNION ALL
    SELECT 
        'Active Connections',
        COUNT(*)::text
    FROM pg_stat_activity 
    WHERE state = 'active' AND datname = current_database();
" 2>/dev/null

echo ""
echo "==================================="
echo "数据库状态检查完成"
echo "==================================="

# 检查迁移状态
echo ""
echo "8. 迁移状态..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 
        version as \"版本\",
        description as \"描述\",
        executed_at as \"执行时间\",
        success as \"成功\"
    FROM get_migration_status() 
    ORDER BY executed_at DESC;
" 2>/dev/null

echo ""
echo "检查完成！如有问题，请查看具体错误信息。"
