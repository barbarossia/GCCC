#!/bin/bash
# ========================================
# GCCC 数据库服务健康检查脚本（优化版）
# 功能：网络连通性、服务可用性、性能检查
# ========================================

set -euo pipefail

# 颜色输出函数
print_color() {
    local color=$1
    local message=$2
    case $color in
        "red")    echo -e "\033[31m$message\033[0m" ;;
        "green")  echo -e "\033[32m$message\033[0m" ;;
        "yellow") echo -e "\033[33m$message\033[0m" ;;
        "blue")   echo -e "\033[34m$message\033[0m" ;;
        "cyan")   echo -e "\033[36m$message\033[0m" ;;
        *)        echo "$message" ;;
    esac
}

# 配置参数
TIMEOUT=10
MAX_RETRIES=3
POSTGRES_CONTAINER="${COMPOSE_PROJECT_NAME:-gccc}-postgres"
REDIS_CONTAINER="${COMPOSE_PROJECT_NAME:-gccc}-redis"

# 网络连通性检查
check_network_connectivity() {
    print_color "blue" "🌐 检查网络连通性..."
    
    # 检查容器网络
    if docker network ls | grep -q "gccc-network"; then
        print_color "green" "✅ Docker网络 'gccc-network' 存在"
    else
        print_color "red" "❌ Docker网络 'gccc-network' 不存在"
        return 1
    fi
    
    # 检查容器是否在运行
    local running_containers
    running_containers=$(docker ps --format "{{.Names}}" | grep -E "(postgres|redis)" | wc -l)
    
    if [ "$running_containers" -ge 2 ]; then
        print_color "green" "✅ 数据库容器运行中 ($running_containers/2)"
    else
        print_color "yellow" "⚠️ 部分容器未运行 ($running_containers/2)"
    fi
}

# PostgreSQL健康检查（增强版）
check_postgresql() {
    print_color "blue" "🐘 检查 PostgreSQL..."
    
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        print_color "cyan" "   尝试 $attempt/$MAX_RETRIES"
        
        # 基础连接检查
        if timeout $TIMEOUT docker exec "$POSTGRES_CONTAINER" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
            print_color "green" "✅ PostgreSQL 连接正常"
            
            # 详细状态检查
            local db_version
            db_version=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT version();" 2>/dev/null | head -1)
            print_color "cyan" "   版本: ${db_version:0:50}..."
            
            # 检查数据库大小
            local db_size
            db_size=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT pg_size_pretty(pg_database_size('$POSTGRES_DB'));" 2>/dev/null)
            print_color "cyan" "   数据库大小: $db_size"
            
            # 检查活跃连接数
            local connections
            connections=$(docker exec "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null)
            print_color "cyan" "   活跃连接: $connections"
            
            # 性能测试 - 简单查询
            local query_time
            query_time=$(docker exec "$POSTGRES_CONTAINER" bash -c "time -p psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT 1;' >/dev/null" 2>&1 | grep real | awk '{print $2}')
            print_color "cyan" "   查询响应时间: ${query_time}s"
            
            return 0
        else
            print_color "yellow" "⚠️ PostgreSQL 连接失败 (尝试 $attempt/$MAX_RETRIES)"
            ((attempt++))
            sleep 2
        fi
    done
    
    print_color "red" "❌ PostgreSQL 健康检查失败"
    return 1
}

# Redis健康检查（增强版）
check_redis() {
    print_color "blue" "🔴 检查 Redis..."
    
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        print_color "cyan" "   尝试 $attempt/$MAX_RETRIES"
        
        # 基础连接检查
        if timeout $TIMEOUT docker exec "$REDIS_CONTAINER" redis-cli ping | grep -q "PONG"; then
            print_color "green" "✅ Redis 连接正常"
            
            # 详细状态检查
            local redis_info
            redis_info=$(docker exec "$REDIS_CONTAINER" redis-cli info server 2>/dev/null | grep "redis_version" | cut -d: -f2 | tr -d '\r')
            print_color "cyan" "   Redis版本: $redis_info"
            
            # 检查内存使用
            local memory_usage
            memory_usage=$(docker exec "$REDIS_CONTAINER" redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
            print_color "cyan" "   内存使用: $memory_usage"
            
            # 检查键数量
            local key_count
            key_count=$(docker exec "$REDIS_CONTAINER" redis-cli dbsize 2>/dev/null)
            print_color "cyan" "   键数量: $key_count"
            
            # 性能测试 - 简单读写
            local start_time end_time duration
            start_time=$(date +%s.%N)
            docker exec "$REDIS_CONTAINER" redis-cli set test_key "test_value" >/dev/null 2>&1
            docker exec "$REDIS_CONTAINER" redis-cli get test_key >/dev/null 2>&1
            docker exec "$REDIS_CONTAINER" redis-cli del test_key >/dev/null 2>&1
            end_time=$(date +%s.%N)
            duration=$(echo "$end_time - $start_time" | bc -l)
            print_color "cyan" "   读写响应时间: ${duration:0:6}s"
            
            return 0
        else
            print_color "yellow" "⚠️ Redis 连接失败 (尝试 $attempt/$MAX_RETRIES)"
            ((attempt++))
            sleep 2
        fi
    done
    
    print_color "red" "❌ Redis 健康检查失败"
    return 1
}

# 容器资源使用检查
check_resource_usage() {
    print_color "blue" "📊 检查容器资源使用..."
    
    local containers=("$POSTGRES_CONTAINER" "$REDIS_CONTAINER")
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
            print_color "cyan" "   容器: $container"
            
            # CPU和内存使用
            local stats
            stats=$(docker stats "$container" --no-stream --format "{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}")
            local cpu_percent=$(echo "$stats" | cut -f1)
            local mem_usage=$(echo "$stats" | cut -f2)
            local mem_percent=$(echo "$stats" | cut -f3)
            
            print_color "cyan" "     CPU: $cpu_percent"
            print_color "cyan" "     内存: $mem_usage ($mem_percent)"
            
            # 磁盘使用（如果有挂载卷）
            local disk_usage
            disk_usage=$(docker exec "$container" df -h / 2>/dev/null | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}') || disk_usage="N/A"
            print_color "cyan" "     磁盘: $disk_usage"
        else
            print_color "red" "❌ 容器未运行: $container"
        fi
    done
}

# 主程序
main() {
    print_color "blue" "🏥 GCCC 数据库健康检查开始"
    print_color "blue" "=" * 50
    
    local overall_status=0
    
    # 网络连通性检查
    if ! check_network_connectivity; then
        overall_status=1
    fi
    
    echo
    
    # PostgreSQL检查
    if ! check_postgresql; then
        overall_status=1
    fi
    
    echo
    
    # Redis检查
    if ! check_redis; then
        overall_status=1
    fi
    
    echo
    
    # 资源使用检查
    check_resource_usage
    
    echo
    print_color "blue" "=" * 50
    
    if [ $overall_status -eq 0 ]; then
        print_color "green" "🎉 所有服务健康检查通过！"
    else
        print_color "red" "⚠️ 部分服务存在问题，请检查上述输出"
    fi
    
    return $overall_status
}

# 脚本参数处理
case "${1:-}" in
    "postgres") check_postgresql ;;
    "redis") check_redis ;;
    "network") check_network_connectivity ;;
    "resources") check_resource_usage ;;
    *) main ;;
esac
