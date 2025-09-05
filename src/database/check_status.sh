#!/bin/bash

# ================================================================
# GCCC 数据库状态检查脚本 (Bash 版本)
# 检查PostgreSQL和Redis数据库的健康状态
# ================================================================

set -e  # 遇到错误立即退出

# 默认参数
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="gccc_development_db"
DB_USER="gccc_user"
DB_PASSWORD=""
REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD=""
VERBOSE=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 输出函数
log_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_step() {
    echo -e "${YELLOW}➤ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}===================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo ""
}

# 显示帮助信息
show_help() {
    cat << EOF
GCCC 数据库状态检查脚本

用法: $0 [选项]

选项:
  -h, --host HOST           数据库主机地址 (默认: localhost)
  -p, --port PORT           数据库端口 (默认: 5432)
  -d, --database DATABASE   数据库名称 (默认: gccc_development_db)
  -u, --user USER           数据库用户 (默认: gccc_user)
  --password PASSWORD       数据库密码
  --redis-host HOST         Redis主机地址 (默认: localhost)
  --redis-port PORT         Redis端口 (默认: 6379)
  --redis-password PASSWORD Redis密码
  -v, --verbose             详细输出
  --help                    显示帮助信息

示例:
  $0                                    # 使用默认参数检查
  $0 -h localhost -p 5432 -d my_db     # 指定参数检查
  $0 -v                                 # 详细模式检查

EOF
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--host)
                DB_HOST="$2"
                shift 2
                ;;
            -p|--port)
                DB_PORT="$2"
                shift 2
                ;;
            -d|--database)
                DB_NAME="$2"
                shift 2
                ;;
            -u|--user)
                DB_USER="$2"
                shift 2
                ;;
            --password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            --redis-host)
                REDIS_HOST="$2"
                shift 2
                ;;
            --redis-port)
                REDIS_PORT="$2"
                shift 2
                ;;
            --redis-password)
                REDIS_PASSWORD="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 设置密码环境变量
    if [[ -n "$DB_PASSWORD" ]]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
}

# 检查PostgreSQL连接
check_postgresql_connection() {
    log_step "检查PostgreSQL连接..."
    
    if command -v psql &> /dev/null; then
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
            log_success "PostgreSQL连接正常"
            return 0
        else
            log_error "PostgreSQL连接失败"
            return 1
        fi
    elif command -v docker &> /dev/null; then
        # 尝试通过Docker容器连接
        local container_name="gccc-*-postgres"
        local containers=$(docker ps --filter "name=$container_name" --format "{{.Names}}" | head -n 1)
        
        if [[ -n "$containers" ]]; then
            if docker exec "$containers" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
                log_success "PostgreSQL连接正常 (通过Docker)"
                return 0
            else
                log_error "PostgreSQL连接失败 (通过Docker)"
                return 1
            fi
        else
            log_error "未找到PostgreSQL客户端或Docker容器"
            return 1
        fi
    else
        log_error "未找到PostgreSQL客户端"
        return 1
    fi
}

# 检查数据库基本信息
check_database_info() {
    log_step "检查数据库基本信息..."
    
    local sql="
    SELECT 
        current_database() as database_name,
        current_user as current_user,
        version() as version;
    "
    
    if command -v psql &> /dev/null; then
        local result
        result=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null || echo "ERROR")
        
        if [[ "$result" != "ERROR" ]]; then
            log_success "数据库信息获取成功"
            if [[ "$VERBOSE" == "true" ]]; then
                echo "$result"
            fi
        else
            log_error "数据库信息获取失败"
            return 1
        fi
    fi
}

# 检查表数量
check_table_count() {
    log_step "检查表数量..."
    
    local sql="
    SELECT COUNT(*) as table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    "
    
    local table_count=0
    
    if command -v psql &> /dev/null; then
        table_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null | tr -d ' ' || echo "0")
    elif command -v docker &> /dev/null; then
        local containers=$(docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" | head -n 1)
        if [[ -n "$containers" ]]; then
            table_count=$(docker exec "$containers" psql -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null | tr -d ' ' || echo "0")
        fi
    fi
    
    if [[ "$table_count" -ge 20 ]]; then
        log_success "表数量检查通过: $table_count 个表"
    elif [[ "$table_count" -gt 0 ]]; then
        log_warning "表数量较少: $table_count 个表 (建议至少20个)"
    else
        log_error "未找到任何表"
        return 1
    fi
}

# 检查函数数量
check_function_count() {
    log_step "检查函数数量..."
    
    local sql="
    SELECT COUNT(*) as function_count
    FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
    "
    
    local function_count=0
    
    if command -v psql &> /dev/null; then
        function_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null | tr -d ' ' || echo "0")
    elif command -v docker &> /dev/null; then
        local containers=$(docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" | head -n 1)
        if [[ -n "$containers" ]]; then
            function_count=$(docker exec "$containers" psql -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null | tr -d ' ' || echo "0")
        fi
    fi
    
    if [[ "$function_count" -ge 10 ]]; then
        log_success "函数数量检查通过: $function_count 个函数"
    elif [[ "$function_count" -gt 0 ]]; then
        log_warning "函数数量较少: $function_count 个函数 (建议至少10个)"
    else
        log_error "未找到任何函数"
        return 1
    fi
}

# 检查扩展
check_extensions() {
    log_step "检查数据库扩展..."
    
    local sql="
    SELECT extname 
    FROM pg_extension 
    WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin', 'pg_trgm')
    ORDER BY extname;
    "
    
    local extensions=""
    
    if command -v psql &> /dev/null; then
        extensions=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null || echo "")
    elif command -v docker &> /dev/null; then
        local containers=$(docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" | head -n 1)
        if [[ -n "$containers" ]]; then
            extensions=$(docker exec "$containers" psql -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null || echo "")
        fi
    fi
    
    local extension_count=$(echo "$extensions" | grep -v '^$' | wc -l)
    
    if [[ "$extension_count" -ge 4 ]]; then
        log_success "扩展检查通过: $extension_count 个扩展已安装"
    elif [[ "$extension_count" -gt 0 ]]; then
        log_warning "部分扩展已安装: $extension_count/4"
    else
        log_error "未安装必要的扩展"
        return 1
    fi
    
    if [[ "$VERBOSE" == "true" ]] && [[ -n "$extensions" ]]; then
        echo "已安装的扩展:"
        echo "$extensions" | grep -v '^$' | sed 's/^/  /'
    fi
}

# 检查迁移状态
check_migrations() {
    log_step "检查迁移状态..."
    
    local sql="
    SELECT 
        COUNT(*) as migration_count,
        COUNT(CASE WHEN success THEN 1 END) as successful_count
    FROM schema_migrations;
    "
    
    local result=""
    
    if command -v psql &> /dev/null; then
        result=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null || echo "")
    elif command -v docker &> /dev/null; then
        local containers=$(docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" | head -n 1)
        if [[ -n "$containers" ]]; then
            result=$(docker exec "$containers" psql -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" 2>/dev/null || echo "")
        fi
    fi
    
    if [[ -n "$result" ]] && [[ "$result" != *"does not exist"* ]]; then
        local migration_count=$(echo "$result" | awk '{print $1}' | tr -d ' ')
        local successful_count=$(echo "$result" | awk '{print $3}' | tr -d ' ')
        
        if [[ "$migration_count" -eq "$successful_count" ]] && [[ "$migration_count" -gt 0 ]]; then
            log_success "迁移状态正常: $successful_count/$migration_count 个迁移成功"
        else
            log_warning "迁移状态异常: $successful_count/$migration_count 个迁移成功"
        fi
    else
        log_warning "迁移表不存在或无法访问"
    fi
}

# 检查Redis连接
check_redis_connection() {
    log_step "检查Redis连接..."
    
    if command -v redis-cli &> /dev/null; then
        local auth_arg=""
        if [[ -n "$REDIS_PASSWORD" ]]; then
            auth_arg="-a $REDIS_PASSWORD"
        fi
        
        if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" $auth_arg ping &> /dev/null; then
            log_success "Redis连接正常"
            return 0
        else
            log_error "Redis连接失败"
            return 1
        fi
    elif command -v docker &> /dev/null; then
        # 尝试通过Docker容器连接
        local containers=$(docker ps --filter "name=gccc-*-redis" --format "{{.Names}}" | head -n 1)
        
        if [[ -n "$containers" ]]; then
            if docker exec "$containers" redis-cli ping &> /dev/null; then
                log_success "Redis连接正常 (通过Docker)"
                return 0
            else
                log_error "Redis连接失败 (通过Docker)"
                return 1
            fi
        else
            log_warning "未找到Redis客户端或Docker容器"
            return 1
        fi
    else
        log_warning "未找到Redis客户端"
        return 1
    fi
}

# 运行健康检查函数
run_health_check() {
    log_step "运行数据库健康检查函数..."
    
    local sql="SELECT * FROM database_health_check();"
    
    local result=""
    
    if command -v psql &> /dev/null; then
        result=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql" 2>/dev/null || echo "ERROR")
    elif command -v docker &> /dev/null; then
        local containers=$(docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" | head -n 1)
        if [[ -n "$containers" ]]; then
            result=$(docker exec "$containers" psql -U "$DB_USER" -d "$DB_NAME" -c "$sql" 2>/dev/null || echo "ERROR")
        fi
    fi
    
    if [[ "$result" != "ERROR" ]] && [[ -n "$result" ]]; then
        log_success "健康检查函数执行成功"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "$result"
        fi
    else
        log_warning "健康检查函数执行失败或不存在"
    fi
}

# 生成状态报告
generate_status_report() {
    print_header "数据库状态报告"
    
    echo -e "${CYAN}检查时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}PostgreSQL: $DB_HOST:$DB_PORT${NC}"
    echo -e "${CYAN}数据库: $DB_NAME${NC}"
    echo -e "${CYAN}Redis: $REDIS_HOST:$REDIS_PORT${NC}"
    echo ""
}

# 主程序
main() {
    print_header "GCCC 数据库状态检查"
    
    generate_status_report
    
    local exit_code=0
    
    # PostgreSQL 检查
    if ! check_postgresql_connection; then
        exit_code=1
    fi
    
    if ! check_database_info; then
        exit_code=1
    fi
    
    if ! check_table_count; then
        exit_code=1
    fi
    
    if ! check_function_count; then
        exit_code=1
    fi
    
    if ! check_extensions; then
        exit_code=1
    fi
    
    check_migrations  # 不影响退出状态
    
    # Redis 检查
    if ! check_redis_connection; then
        exit_code=1
    fi
    
    # 健康检查
    run_health_check
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "数据库状态检查全部通过!"
    else
        log_error "数据库状态检查发现问题，退出码: $exit_code"
    fi
    
    exit $exit_code
}

# 错误处理
trap 'log_error "脚本执行出错，退出码: $?"' ERR

# 解析参数并执行主程序
parse_arguments "$@"
main
}

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
