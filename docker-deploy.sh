#!/bin/bash

# ========================================
# GCCC Docker 快速启动脚本
# ========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} GCCC DApp Docker 部署脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 检查依赖
check_dependencies() {
    print_status "检查系统依赖..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi
    
    print_status "依赖检查完成 ✓"
}

# 环境配置
setup_environment() {
    print_status "配置环境变量..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_warning "已从 .env.example 创建 .env 文件"
            print_warning "请编辑 .env 文件配置生产环境密码和密钥！"
        else
            print_error ".env.example 文件不存在"
            exit 1
        fi
    else
        print_status "发现现有 .env 文件"
    fi
}

# 构建镜像
build_images() {
    print_status "构建 Docker 镜像..."
    
    # 构建数据库镜像
    print_status "构建数据库镜像..."
    docker-compose build database
    
    # 构建后端镜像
    print_status "构建后端镜像..."
    docker-compose build backend
    
    print_status "镜像构建完成 ✓"
}

# 启动服务
start_services() {
    local mode=$1
    
    case $mode in
        "dev")
            print_status "启动开发环境..."
            docker-compose --profile development up -d
            ;;
        "prod")
            print_status "启动生产环境..."
            docker-compose up -d
            ;;
        "nginx")
            print_status "启动生产环境 (包含 Nginx)..."
            docker-compose --profile with-nginx up -d
            ;;
        *)
            print_status "启动默认环境..."
            docker-compose up -d
            ;;
    esac
}

# 等待服务就绪
wait_for_services() {
    print_status "等待服务启动..."
    
    # 等待数据库
    print_status "等待数据库启动..."
    timeout=60
    counter=0
    
    while [ $counter -lt $timeout ]; do
        if docker-compose exec -T database pg_isready -U gccc_user -d gccc_db > /dev/null 2>&1; then
            print_status "数据库已就绪 ✓"
            break
        fi
        counter=$((counter + 1))
        sleep 1
    done
    
    if [ $counter -eq $timeout ]; then
        print_error "数据库启动超时"
        exit 1
    fi
    
    # 等待后端API
    print_status "等待后端API启动..."
    counter=0
    
    while [ $counter -lt $timeout ]; do
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            print_status "后端API已就绪 ✓"
            break
        fi
        counter=$((counter + 1))
        sleep 1
    done
    
    if [ $counter -eq $timeout ]; then
        print_warning "后端API启动超时，但可能仍在初始化中"
    fi
}

# 验证部署
verify_deployment() {
    print_status "验证部署状态..."
    
    # 检查容器状态
    print_status "检查容器状态..."
    docker-compose ps
    
    # 检查数据库健康状态
    print_status "检查数据库健康状态..."
    if docker-compose exec -T database /scripts/health_check.sh; then
        print_status "数据库健康检查通过 ✓"
    else
        print_warning "数据库健康检查失败"
    fi
    
    # 检查API健康状态
    print_status "检查API健康状态..."
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        print_status "API健康检查通过 ✓"
    else
        print_warning "API健康检查失败"
    fi
}

# 显示访问信息
show_access_info() {
    print_header
    print_status "部署完成！"
    echo ""
    echo -e "${GREEN}访问信息:${NC}"
    echo -e "  API服务器: ${BLUE}http://localhost:3000${NC}"
    echo -e "  API文档:   ${BLUE}http://localhost:3000/docs${NC}"
    echo -e "  健康检查: ${BLUE}http://localhost:3000/health${NC}"
    echo ""
    echo -e "${GREEN}管理命令:${NC}"
    echo -e "  查看日志: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "  查看状态: ${YELLOW}docker-compose ps${NC}"
    echo -e "  停止服务: ${YELLOW}docker-compose down${NC}"
    echo -e "  数据备份: ${YELLOW}docker-compose exec database /scripts/backup.sh${NC}"
    echo ""
    echo -e "${YELLOW}注意: 首次启动可能需要几分钟来初始化数据库${NC}"
    print_header
}

# 清理函数
cleanup() {
    print_status "停止所有服务..."
    docker-compose down
    
    if [ "$1" = "--volumes" ]; then
        print_warning "删除所有数据卷..."
        docker-compose down -v
    fi
    
    if [ "$1" = "--all" ]; then
        print_warning "删除所有容器、镜像和数据卷..."
        docker-compose down -v --rmi all
    fi
}

# 主函数
main() {
    print_header
    
    case "${1:-}" in
        "start")
            check_dependencies
            setup_environment
            build_images
            start_services "${2:-}"
            wait_for_services
            verify_deployment
            show_access_info
            ;;
        "stop")
            print_status "停止服务..."
            docker-compose down
            print_status "服务已停止"
            ;;
        "restart")
            print_status "重启服务..."
            docker-compose restart
            wait_for_services
            verify_deployment
            ;;
        "logs")
            docker-compose logs -f "${2:-}"
            ;;
        "status")
            docker-compose ps
            ;;
        "cleanup")
            cleanup "${2:-}"
            ;;
        "backup")
            print_status "创建数据库备份..."
            docker-compose exec database /scripts/backup.sh
            ;;
        "help"|"-h"|"--help")
            echo "用法: $0 <命令> [选项]"
            echo ""
            echo "命令:"
            echo "  start [dev|prod|nginx]  启动服务 (默认: 生产模式)"
            echo "  stop                    停止服务"
            echo "  restart                 重启服务"
            echo "  logs [service]          查看日志"
            echo "  status                  查看服务状态"
            echo "  cleanup [--volumes|--all] 清理容器和数据"
            echo "  backup                  创建数据库备份"
            echo "  help                    显示帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 start              # 启动生产环境"
            echo "  $0 start dev          # 启动开发环境"
            echo "  $0 start nginx        # 启动带Nginx的生产环境"
            echo "  $0 logs backend       # 查看后端日志"
            echo "  $0 cleanup --volumes  # 清理包括数据卷"
            ;;
        *)
            print_error "未知命令: ${1:-}"
            echo "使用 '$0 help' 查看帮助信息"
            exit 1
            ;;
    esac
}

# 错误处理
trap 'print_error "脚本执行失败，退出码: $?"' ERR

# 执行主函数
main "$@"
