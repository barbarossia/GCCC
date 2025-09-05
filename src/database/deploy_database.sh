#!/bin/bash

# ================================================================
# GCCC 数据库一键部署脚本 (Bash 版本)
# 使用Docker部署PostgreSQL和Redis数据库
# ================================================================

set -e  # 遇到错误立即退出

# 默认参数
ACTION="deploy"
ENVIRONMENT="development"
FORCE=false
WITH_SAMPLE=true
SKIP_CHECK=false

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DOCKER_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

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
GCCC 数据库一键部署脚本

用法: $0 [选项]

选项:
  -a, --action ACTION        操作类型: deploy, stop, restart, clean, status (默认: deploy)
  -e, --environment ENV      环境: development, test, production (默认: development)
  -f, --force               强制执行，覆盖现有部署
  -s, --skip-check          跳过状态检查
  -h, --help                显示帮助信息

示例:
  $0                                    # 部署开发环境
  $0 -e production                      # 部署生产环境
  $0 -a restart -f                      # 强制重启
  $0 -a clean -f                        # 清理部署
  $0 -a status                          # 检查状态

EOF
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--action)
                ACTION="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -s|--skip-check)
                SKIP_CHECK=true
                shift
                ;;
            -h|--help)
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

    ENV_FILE="$SCRIPT_DIR/.env.${ENVIRONMENT}"
}

# 检查Docker环境
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        log_info "请访问 https://www.docker.com/get-started 安装Docker"
        exit 1
    fi
    
    if ! docker --version &> /dev/null; then
        log_error "Docker不可用"
        exit 1
    fi
    
    log_success "Docker已安装: $(docker --version)"
    
    # 检查Docker Compose
    if command -v docker-compose &> /dev/null; then
        USE_DOCKER_COMPOSE_V1=true
        log_success "Docker Compose已安装: $(docker-compose --version)"
    elif docker compose version &> /dev/null; then
        USE_DOCKER_COMPOSE_V1=false
        log_success "Docker Compose已安装: $(docker compose version)"
    else
        log_error "Docker Compose未安装或不可用"
        exit 1
    fi
}

# 创建环境文件
create_env_file() {
    log_step "创建环境配置文件..."
    
    cat > "$ENV_FILE" << EOF
# GCCC Database Environment Configuration
# Environment: $ENVIRONMENT
# Generated: $(date '+%Y-%m-%d %H:%M:%S')

# PostgreSQL Configuration
POSTGRES_DB=gccc_${ENVIRONMENT}_db
POSTGRES_USER=gccc_user
POSTGRES_PASSWORD=gccc_secure_password_2024
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_MAX_CONNECTIONS=200

# Redis Configuration  
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_password_2024
REDIS_DB=0

# Docker Configuration
COMPOSE_PROJECT_NAME=gccc-${ENVIRONMENT}
DOCKER_NETWORK=gccc-${ENVIRONMENT}-network

# Volume Configuration
POSTGRES_DATA_PATH=./data/postgres
REDIS_DATA_PATH=./data/redis
BACKUP_PATH=./backups

# Performance Settings
POSTGRES_SHARED_BUFFERS=256MB
POSTGRES_EFFECTIVE_CACHE_SIZE=1GB
POSTGRES_WORK_MEM=16MB
POSTGRES_MAINTENANCE_WORK_MEM=64MB

# Logging
POSTGRES_LOG_LEVEL=info
REDIS_LOG_LEVEL=notice

# Health Check
HEALTH_CHECK_INTERVAL=30s
HEALTH_CHECK_TIMEOUT=10s
HEALTH_CHECK_RETRIES=3
EOF

    log_success "环境文件已创建: $ENV_FILE"
}

# 创建Docker Compose文件
create_docker_compose() {
    log_step "创建Docker Compose配置..."
    
    cat > "$DOCKER_COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: ${COMPOSE_PROJECT_NAME}-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_MAX_CONNECTIONS: ${POSTGRES_MAX_CONNECTIONS}
      POSTGRES_SHARED_BUFFERS: ${POSTGRES_SHARED_BUFFERS}
      POSTGRES_EFFECTIVE_CACHE_SIZE: ${POSTGRES_EFFECTIVE_CACHE_SIZE}
      POSTGRES_WORK_MEM: ${POSTGRES_WORK_MEM}
      POSTGRES_MAINTENANCE_WORK_MEM: ${POSTGRES_MAINTENANCE_WORK_MEM}
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d
      - ./backups:/backups
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: ${HEALTH_CHECK_INTERVAL}
      timeout: ${HEALTH_CHECK_TIMEOUT}
      retries: ${HEALTH_CHECK_RETRIES}
    command: >
      postgres
      -c shared_buffers=${POSTGRES_SHARED_BUFFERS}
      -c effective_cache_size=${POSTGRES_EFFECTIVE_CACHE_SIZE}
      -c work_mem=${POSTGRES_WORK_MEM}
      -c maintenance_work_mem=${POSTGRES_MAINTENANCE_WORK_MEM}
      -c max_connections=${POSTGRES_MAX_CONNECTIONS}
      -c log_statement=all
      -c log_destination=stderr
      -c logging_collector=on
      -c log_directory=pg_log
      -c log_filename=postgresql-%Y-%m-%d.log

  redis:
    image: redis:7-alpine
    container_name: ${COMPOSE_PROJECT_NAME}-redis
    restart: unless-stopped
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: ${HEALTH_CHECK_INTERVAL}
      timeout: ${HEALTH_CHECK_TIMEOUT}
      retries: ${HEALTH_CHECK_RETRIES}
    command: redis-server /usr/local/etc/redis/redis.conf --requirepass ${REDIS_PASSWORD}

  # Database Administration Tool (Optional)
  adminer:
    image: adminer:latest
    container_name: ${COMPOSE_PROJECT_NAME}-adminer
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      ADMINER_DEFAULT_SERVER: postgres
    networks:
      - gccc-network
    depends_on:
      - postgres
    profiles:
      - admin

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${PWD}/data/postgres
  redis_data:
    driver: local
    driver_opts:
      type: none  
      o: bind
      device: ${PWD}/data/redis

networks:
  gccc-network:
    driver: bridge
    name: ${DOCKER_NETWORK}
EOF

    log_success "Docker Compose文件已创建: $DOCKER_COMPOSE_FILE"
}

# 创建Redis配置文件
create_redis_config() {
    log_step "创建Redis配置文件..."
    
    cat > "$SCRIPT_DIR/redis.conf" << EOF
# GCCC Redis Configuration
# Environment: $ENVIRONMENT

# Network
bind 0.0.0.0
port 6379
timeout 300

# Security
protected-mode yes

# Memory Management
maxmemory 512mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# Logging
loglevel notice
logfile /data/redis.log

# Performance
tcp-backlog 511
tcp-keepalive 300
EOF

    log_success "Redis配置文件已创建: $SCRIPT_DIR/redis.conf"
}

# 创建初始化结构
create_init_structure() {
    log_step "创建初始化结构..."
    
    # 创建目录
    local dirs=(
        "data/postgres"
        "data/redis" 
        "backups"
        "init"
        "logs"
    )
    
    for dir in "${dirs[@]}"; do
        local full_path="$SCRIPT_DIR/$dir"
        if [[ ! -d "$full_path" ]]; then
            mkdir -p "$full_path"
            log_success "创建目录: $dir"
        fi
    done
    
    # 创建初始化SQL脚本
    cat > "$SCRIPT_DIR/init/01-init.sql" << EOF
-- GCCC Database Initialization Script
-- Environment: $ENVIRONMENT
-- Generated: $(date '+%Y-%m-%d %H:%M:%S')

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create application user
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gccc_app') THEN
        CREATE ROLE gccc_app WITH LOGIN PASSWORD 'gccc_app_password_2024';
    END IF;
END
\$\$;

-- Grant permissions
GRANT CONNECT ON DATABASE gccc_${ENVIRONMENT}_db TO gccc_app;
GRANT CREATE ON SCHEMA public TO gccc_app;
GRANT USAGE ON SCHEMA public TO gccc_app;

-- Create basic monitoring functions
CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS \$\$
BEGIN
    -- Connection check
    RETURN QUERY SELECT 'connection'::TEXT, 'healthy'::TEXT, 'Database is accessible'::TEXT;
    
    -- Table count check
    RETURN QUERY SELECT 
        'table_count'::TEXT,
        CASE WHEN COUNT(*) >= 20 THEN 'healthy' ELSE 'warning' END::TEXT,
        ('Found ' || COUNT(*) || ' tables')::TEXT
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    
    -- Extension check
    RETURN QUERY SELECT
        'extensions'::TEXT,
        CASE WHEN COUNT(*) >= 4 THEN 'healthy' ELSE 'warning' END::TEXT,
        ('Found ' || COUNT(*) || ' extensions')::TEXT
    FROM pg_extension
    WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin', 'pg_trgm');
END;
\$\$ LANGUAGE plpgsql;

-- Create migration tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    description TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE
);

-- Create migration status function
CREATE OR REPLACE FUNCTION get_migration_status()
RETURNS TABLE(
    version TEXT,
    description TEXT,
    executed_at TIMESTAMP,
    success BOOLEAN
) AS \$\$
BEGIN
    RETURN QUERY 
    SELECT sm.version::TEXT, sm.description, sm.executed_at, sm.success
    FROM schema_migrations sm
    ORDER BY sm.executed_at DESC;
END;
\$\$ LANGUAGE plpgsql;

-- Insert initial migration record
INSERT INTO schema_migrations (version, description) 
VALUES ('001', 'Database initialization') 
ON CONFLICT (version) DO NOTHING;

-- Create system configuration table
CREATE TABLE IF NOT EXISTS system_configs (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert system configurations
INSERT INTO system_configs (key, value, description) VALUES
('db.version', '1.0.0', 'Database schema version'),
('app.environment', '$ENVIRONMENT', 'Application environment'),
('deployment.timestamp', '$(date '+%Y-%m-%d %H:%M:%S')', 'Deployment timestamp'),
('health.check.enabled', 'true', 'Health check enabled'),
('logging.level', 'info', 'Logging level')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = CURRENT_TIMESTAMP;

-- Log successful initialization
DO \$\$
BEGIN
    RAISE NOTICE 'GCCC Database initialized successfully for % environment', '$ENVIRONMENT';
END
\$\$;
EOF

    log_success "初始化SQL脚本已创建"
}

# 获取Docker Compose命令
get_compose_cmd() {
    if [[ "$USE_DOCKER_COMPOSE_V1" == "true" ]]; then
        echo "docker-compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE"
    else
        echo "docker compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE"
    fi
}

# 部署数据库
deploy_database() {
    print_header "开始部署GCCC数据库"
    
    log_step "检查现有容器..."
    local existing_containers
    existing_containers=$(docker ps -a --filter "name=${ENVIRONMENT}" --format "{{.Names}}" 2>/dev/null || true)
    
    if [[ -n "$existing_containers" ]] && [[ "$FORCE" != "true" ]]; then
        log_info "发现现有容器:"
        echo "$existing_containers"
        echo ""
        read -p "是否要强制重新部署? (y/N): " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "部署已取消"
            return
        fi
        FORCE=true
    fi
    
    if [[ "$FORCE" == "true" ]]; then
        log_step "停止并移除现有容器..."
        $(get_compose_cmd) down -v --remove-orphans 2>/dev/null || true
        log_success "现有容器已清理"
    fi
    
    log_step "启动数据库服务..."
    $(get_compose_cmd) up -d
    
    if [[ $? -eq 0 ]]; then
        log_success "数据库服务启动成功"
    else
        log_error "数据库服务启动失败"
        exit 1
    fi
    
    log_step "等待数据库就绪..."
    local max_wait=60
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        sleep 2
        waited=$((waited + 2))
        
        if docker exec "gccc-${ENVIRONMENT}-postgres" pg_isready -U gccc_user -d "gccc_${ENVIRONMENT}_db" &>/dev/null; then
            log_success "PostgreSQL已就绪 (等待了 ${waited} 秒)"
            break
        fi
        echo -n "."
    done
    
    if [[ $waited -ge $max_wait ]]; then
        log_error "PostgreSQL启动超时"
        exit 1
    fi
    
    log_step "验证Redis连接..."
    local redis_check
    redis_check=$(docker exec "gccc-${ENVIRONMENT}-redis" redis-cli ping 2>/dev/null || echo "FAILED")
    
    if [[ "$redis_check" == "PONG" ]]; then
        log_success "Redis连接正常"
    else
        log_error "Redis连接失败"
    fi
}

# 停止数据库服务
stop_database() {
    print_header "停止GCCC数据库服务"
    
    log_step "停止数据库容器..."
    $(get_compose_cmd) stop
    
    log_success "数据库服务已停止"
}

# 重启数据库服务
restart_database() {
    print_header "重启GCCC数据库服务"
    
    stop_database
    sleep 3
    deploy_database
}

# 清理部署
clean_deployment() {
    print_header "清理GCCC数据库部署"
    
    if [[ "$FORCE" != "true" ]]; then
        log_error "清理操作需要使用 -f/--force 参数确认"
        log_info "这将删除所有数据库数据，请谨慎操作"
        return
    fi
    
    log_step "停止并移除所有服务..."
    $(get_compose_cmd) down -v --remove-orphans --rmi local 2>/dev/null || true
    
    log_step "清理数据目录..."
    if [[ -d "$SCRIPT_DIR/data" ]]; then
        rm -rf "$SCRIPT_DIR/data"
        log_success "数据目录已清理"
    fi
    
    log_success "数据库部署已完全清理"
}

# 运行状态检查
run_status_check() {
    if [[ "$SKIP_CHECK" != "true" ]]; then
        print_header "运行数据库状态检查"
        
        local check_script="$SCRIPT_DIR/check_status.sh"
        if [[ -f "$check_script" ]]; then
            bash "$check_script" -h "localhost" -p "5432" -d "gccc_${ENVIRONMENT}_db" -u "gccc_user"
        elif [[ -f "$SCRIPT_DIR/check_status.ps1" ]]; then
            log_info "找到PowerShell版本的状态检查脚本"
            log_info "请在PowerShell中运行: .\\check_status.ps1 -DbHost localhost -DbPort 5432 -DbName gccc_${ENVIRONMENT}_db -DbUser gccc_user"
        else
            log_info "状态检查脚本未找到，跳过状态检查"
        fi
    fi
}

# 显示部署信息
show_deployment_info() {
    print_header "部署信息"
    
    echo -e "${CYAN}环境: $ENVIRONMENT${NC}"
    echo -e "${CYAN}项目名: gccc-$ENVIRONMENT${NC}"
    echo ""
    
    echo -e "${YELLOW}数据库连接信息:${NC}"
    echo "  PostgreSQL: localhost:5432"
    echo "  数据库名: gccc_${ENVIRONMENT}_db"  
    echo "  用户名: gccc_user"
    echo "  Redis: localhost:6379"
    echo ""
    
    echo -e "${YELLOW}管理工具:${NC}"
    echo "  Adminer (可选): http://localhost:8080"
    echo "  启用命令: $(get_compose_cmd) --profile admin up -d adminer"
    echo ""
    
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  查看日志: $(get_compose_cmd) logs -f"
    echo "  进入PostgreSQL: docker exec -it gccc-$ENVIRONMENT-postgres psql -U gccc_user -d gccc_${ENVIRONMENT}_db"
    echo "  进入Redis: docker exec -it gccc-$ENVIRONMENT-redis redis-cli"
    echo "  状态检查: $0 -a status"
    echo ""
}

# 主程序
main() {
    print_header "GCCC 数据库一键部署脚本"
    echo -e "${CYAN}环境: $ENVIRONMENT${NC}"
    echo -e "${CYAN}操作: $ACTION${NC}"
    
    # 检查Docker环境
    check_docker
    
    # 创建必要文件
    create_env_file
    create_docker_compose
    create_redis_config
    create_init_structure
    
    # 根据操作执行相应命令
    case "$ACTION" in
        "deploy")
            deploy_database
            run_status_check
            show_deployment_info
            ;;
        "stop")
            stop_database
            ;;
        "restart")
            restart_database
            run_status_check
            ;;
        "clean")
            clean_deployment
            ;;
        "status")
            run_status_check
            ;;
        *)
            log_error "未知操作: $ACTION"
            log_info "支持的操作: deploy, stop, restart, clean, status"
            exit 1
            ;;
    esac
    
    log_success "操作完成!"
}

# 错误处理
trap 'log_error "脚本执行出错，退出码: $?"' ERR

# 解析参数并执行主程序
parse_arguments "$@"
main
