# ================================================================
# GCCC 数据库一键部署脚本 (PowerShell 版本)
# 使用Docker部署PostgreSQL和Redis数据库
# ================================================================

param(
    [ValidateSet("deploy", "stop", "restart", "clean", "status")]
    [string]$Action = "deploy",
    
    [ValidateSet("development", "test", "production")]
    [string]$Environment = "development",
    
    [switch]$Force = $false,
    [switch]$WithSample = $true,
    [switch]$SkipCheck = $false,
    [switch]$Help = $false
)

# 获取脚本目录和项目根目录
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$DOCKER_COMPOSE_FILE = Join-Path $SCRIPT_DIR "docker-compose.yml"
$ENV_FILE = Join-Path $SCRIPT_DIR ".env.$Environment"

# 颜色输出函数
function Write-ColorText {
    param([string]$Text, [string]$Color)
    $colors = @{
        "Red" = "DarkRed"
        "Green" = "Green" 
        "Yellow" = "Yellow"
        "Blue" = "Blue"
        "Cyan" = "Cyan"
    }
    Write-Host $Text -ForegroundColor $colors[$Color]
}

function Write-Info { param([string]$Message) Write-ColorText "ℹ $Message" "Cyan" }
function Write-Success { param([string]$Message) Write-ColorText "✓ $Message" "Green" }
function Write-Error { param([string]$Message) Write-ColorText "✗ $Message" "Red" }
function Write-Warning { param([string]$Message) Write-ColorText "⚠ $Message" "Yellow" }
function Write-Step { param([string]$Message) Write-ColorText "➤ $Message" "Yellow" }
function Write-Header { 
    param([string]$Message) 
    Write-Host ""
    Write-ColorText "===================================" "Cyan"
    Write-ColorText $Message "Cyan"
    Write-ColorText "===================================" "Cyan"
    Write-Host ""
}

# 显示帮助信息
function Show-Help {
    Write-Host @"
GCCC 数据库一键部署脚本

用法: .\deploy_database.ps1 [参数]

参数:
  -Action <ACTION>           操作类型: deploy, stop, restart, clean, status (默认: deploy)
  -Environment <ENV>         环境: development, test, production (默认: development)  
  -Force                     强制执行，覆盖现有部署
  -SkipCheck                 跳过状态检查
  -Help                      显示帮助信息

示例:
  .\deploy_database.ps1                                    # 部署开发环境
  .\deploy_database.ps1 -Environment production           # 部署生产环境
  .\deploy_database.ps1 -Action restart -Force            # 强制重启
  .\deploy_database.ps1 -Action clean -Force              # 清理部署
  .\deploy_database.ps1 -Action status                    # 检查状态

"@
}

# 检查Docker环境
function Test-DockerEnvironment {
    Write-Step "检查Docker环境..."
    
    if (!(Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Error "Docker未安装"
        Write-Info "请访问 https://www.docker.com/get-started 安装Docker Desktop"
        exit 1
    }
    
    try {
        $dockerVersion = docker --version
        Write-Success "Docker已安装: $dockerVersion"
    }
    catch {
        Write-Error "Docker不可用"
        exit 1
    }
    
    # 检查Docker Compose
    try {
        $composeVersion = docker compose version 2>$null
        if ($composeVersion) {
            Write-Success "Docker Compose已安装: $composeVersion"
            return "docker compose"
        }
    }
    catch {}
    
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($composeVersion) {
            Write-Success "Docker Compose已安装: $composeVersion"
            return "docker-compose"
        }
    }
    catch {}
    
    Write-Error "Docker Compose未安装或不可用"
    exit 1
}

# 创建环境文件
function New-EnvironmentFile {
    Write-Step "创建环境配置文件..."
    
    $envContent = @"
# GCCC Database Environment Configuration
# Environment: $Environment
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# PostgreSQL Configuration
POSTGRES_DB=gccc_$($Environment)_db
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
COMPOSE_PROJECT_NAME=gccc-$Environment
DOCKER_NETWORK=gccc-$Environment-network

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
"@

    $envContent | Out-File -FilePath $ENV_FILE -Encoding UTF8
    Write-Success "环境文件已创建: $ENV_FILE"
}

# 创建Docker Compose文件
function New-DockerComposeFile {
    Write-Step "创建Docker Compose配置..."
    
    $composeContent = @'
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
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: ${COMPOSE_PROJECT_NAME}-redis
    restart: unless-stopped
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    command: redis-server /usr/local/etc/redis/redis.conf --requirepass ${REDIS_PASSWORD}

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
  redis_data:

networks:
  gccc-network:
    driver: bridge
    name: ${DOCKER_NETWORK}
'@

    $composeContent | Out-File -FilePath $DOCKER_COMPOSE_FILE -Encoding UTF8
    Write-Success "Docker Compose文件已创建: $DOCKER_COMPOSE_FILE"
}

# 创建Redis配置文件
function New-RedisConfig {
    Write-Step "创建Redis配置文件..."
    
    $redisConfigPath = Join-Path $SCRIPT_DIR "redis.conf"
    $redisConfig = @"
# GCCC Redis Configuration
bind 0.0.0.0
port 6379
timeout 300
protected-mode yes
maxmemory 512mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data
loglevel notice
logfile /data/redis.log
tcp-backlog 511
tcp-keepalive 300
"@

    $redisConfig | Out-File -FilePath $redisConfigPath -Encoding UTF8
    Write-Success "Redis配置文件已创建: $redisConfigPath"
}

# 创建初始化结构
function New-InitializationStructure {
    Write-Step "创建初始化结构..."
    
    $dirs = @(
        "data/postgres",
        "data/redis", 
        "backups",
        "init",
        "logs"
    )
    
    foreach ($dir in $dirs) {
        $fullPath = Join-Path $SCRIPT_DIR $dir
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Success "创建目录: $dir"
        }
    }
    
    # 创建初始化SQL脚本
    $initSqlPath = Join-Path $SCRIPT_DIR "init/01-init.sql"
    $initSql = @"
-- GCCC Database Initialization Script
-- Environment: $Environment
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

DO ${'$'}${'$'}
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gccc_app') THEN
        CREATE ROLE gccc_app WITH LOGIN PASSWORD 'gccc_app_password_2024';
    END IF;
END
${'$'}${'$'};

GRANT CONNECT ON DATABASE gccc_$($Environment)_db TO gccc_app;
GRANT CREATE ON SCHEMA public TO gccc_app;
GRANT USAGE ON SCHEMA public TO gccc_app;

CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE(check_name TEXT, status TEXT, details TEXT)
AS ${'$'}${'$'}
BEGIN
    RETURN QUERY SELECT 'connection'::TEXT, 'healthy'::TEXT, 'Database accessible'::TEXT;
    RETURN QUERY SELECT 
        'table_count'::TEXT,
        CASE WHEN COUNT(*) >= 20 THEN 'healthy' ELSE 'warning' END::TEXT,
        ('Found ' || COUNT(*) || ' tables')::TEXT
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
END;
${'$'}${'$'} LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    description TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE
);

INSERT INTO schema_migrations (version, description) 
VALUES ('001', 'Database initialization') 
ON CONFLICT (version) DO NOTHING;

CREATE TABLE IF NOT EXISTS system_configs (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_configs (key, value, description) VALUES
('db.version', '1.0.0', 'Database schema version'),
('app.environment', '$Environment', 'Application environment'),
('deployment.timestamp', '$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")', 'Deployment timestamp')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = CURRENT_TIMESTAMP;
"@

    $initSql | Out-File -FilePath $initSqlPath -Encoding UTF8
    Write-Success "初始化SQL脚本已创建"
}

# 部署数据库
function Start-DatabaseDeploy {
    param([string]$ComposeCmd)
    
    Write-Header "开始部署GCCC数据库"
    
    Write-Step "检查现有容器..."
    $existingContainers = docker ps -a --filter "name=$Environment" --format "{{.Names}}" 2>$null
    
    if ($existingContainers -and !$Force) {
        Write-Info "发现现有容器:"
        $existingContainers
        $response = Read-Host "是否要强制重新部署? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "部署已取消"
            return
        }
        $script:Force = $true
    }
    
    if ($Force) {
        Write-Step "停止并移除现有容器..."
        & $ComposeCmd.Split(' ') down -v --remove-orphans 2>$null
        Write-Success "现有容器已清理"
    }
    
    Write-Step "启动数据库服务..."
    $envArgs = @("--env-file", $ENV_FILE, "-f", $DOCKER_COMPOSE_FILE)
    & $ComposeCmd.Split(' ') $envArgs up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "数据库服务启动成功"
    } else {
        Write-Error "数据库服务启动失败"
        exit 1
    }
    
    Write-Step "等待数据库就绪..."
    $maxWait = 60
    $waited = 0
    
    do {
        Start-Sleep -Seconds 2
        $waited += 2
        $pgReady = docker exec "gccc-$Environment-postgres" pg_isready -U gccc_user -d "gccc_$($Environment)_db" 2>$null
        if ($pgReady) {
            Write-Success "PostgreSQL已就绪 (等待了 $waited 秒)"
            break
        }
        Write-Host "." -NoNewline
    } while ($waited -lt $maxWait)
    
    if ($waited -ge $maxWait) {
        Write-Error "PostgreSQL启动超时"
        exit 1
    }
    
    Write-Step "验证Redis连接..."
    $redisCheck = docker exec "gccc-$Environment-redis" redis-cli ping 2>$null
    if ($redisCheck -eq "PONG") {
        Write-Success "Redis连接正常"
    } else {
        Write-Error "Redis连接失败"
    }
}

# 停止数据库服务
function Stop-Database {
    param([string]$ComposeCmd)
    
    Write-Header "停止GCCC数据库服务"
    Write-Step "停止数据库容器..."
    
    $envArgs = @("--env-file", $ENV_FILE, "-f", $DOCKER_COMPOSE_FILE)
    & $ComposeCmd.Split(' ') $envArgs stop
    Write-Success "数据库服务已停止"
}

# 重启数据库服务
function Restart-Database {
    param([string]$ComposeCmd)
    
    Write-Header "重启GCCC数据库服务"
    Stop-Database $ComposeCmd
    Start-Sleep -Seconds 3
    Start-DatabaseDeploy $ComposeCmd
}

# 清理部署
function Remove-Deployment {
    param([string]$ComposeCmd)
    
    Write-Header "清理GCCC数据库部署"
    
    if (!$Force) {
        Write-Error "清理操作需要使用 -Force 参数确认"
        Write-Info "这将删除所有数据库数据，请谨慎操作"
        return
    }
    
    Write-Step "停止并移除所有服务..."
    $envArgs = @("--env-file", $ENV_FILE, "-f", $DOCKER_COMPOSE_FILE)
    & $ComposeCmd.Split(' ') $envArgs down -v --remove-orphans --rmi local 2>$null
    
    Write-Step "清理数据目录..."
    $dataDir = Join-Path $SCRIPT_DIR "data"
    if (Test-Path $dataDir) {
        Remove-Item -Path $dataDir -Recurse -Force
        Write-Success "数据目录已清理"
    }
    
    Write-Success "数据库部署已完全清理"
}

# 运行状态检查
function Start-StatusCheck {
    if (!$SkipCheck) {
        Write-Header "运行数据库状态检查"
        
        $checkScript = Join-Path $SCRIPT_DIR "check_status.ps1"
        if (Test-Path $checkScript) {
            & $checkScript -DbHost "localhost" -DbPort "5432" -DbName "gccc_$($Environment)_db" -DbUser "gccc_user"
        } else {
            Write-Info "状态检查脚本未找到，跳过状态检查"
        }
    }
}

# 显示部署信息
function Show-DeploymentInfo {
    Write-Header "部署信息"
    
    Write-ColorText "环境: $Environment" "Cyan"
    Write-ColorText "项目名: gccc-$Environment" "Cyan"
    Write-Host ""
    
    Write-ColorText "数据库连接信息:" "Yellow"
    Write-Host "  PostgreSQL: localhost:5432"
    Write-Host "  数据库名: gccc_$($Environment)_db"  
    Write-Host "  用户名: gccc_user"
    Write-Host "  Redis: localhost:6379"
    Write-Host ""
    
    Write-ColorText "管理工具:" "Yellow"
    Write-Host "  Adminer (可选): http://localhost:8080"
    Write-Host "  启用命令: docker compose --profile admin up -d adminer"
    Write-Host ""
    
    Write-ColorText "常用命令:" "Yellow"
    Write-Host "  查看日志: docker compose logs -f"
    Write-Host "  进入PostgreSQL: docker exec -it gccc-$Environment-postgres psql -U gccc_user -d gccc_$($Environment)_db"
    Write-Host "  进入Redis: docker exec -it gccc-$Environment-redis redis-cli"
    Write-Host ""
}

# 主程序
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Header "GCCC 数据库一键部署脚本"
    Write-ColorText "环境: $Environment" "Cyan"
    Write-ColorText "操作: $Action" "Cyan"
    
    # 检查Docker环境
    $composeCmd = Test-DockerEnvironment
    
    # 创建必要文件
    New-EnvironmentFile
    New-DockerComposeFile
    New-RedisConfig
    New-InitializationStructure
    
    # 根据操作执行相应命令
    switch ($Action) {
        "deploy" {
            Start-DatabaseDeploy $composeCmd
            Start-StatusCheck
            Show-DeploymentInfo
        }
        "stop" {
            Stop-Database $composeCmd
        }
        "restart" {
            Restart-Database $composeCmd
        }
        "clean" {
            Remove-Deployment $composeCmd
        }
        "status" {
            Start-StatusCheck
        }
        default {
            Write-Error "未知操作: $Action"
            Write-Info "支持的操作: deploy, stop, restart, clean, status"
            exit 1
        }
    }
    
    Write-Success "操作完成!"
}

# 错误处理
trap {
    Write-Error "脚本执行出错: $($_.Exception.Message)"
    exit 1
}

# 执行主程序
Main
