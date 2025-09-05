# ================================================================
# GCCC 数据库一键部署脚本 (PowerShell 版本)
# 使用Docker部署PostgreSQL和Redis数据库
# ================================================================

param(
    [string]$Action = "deploy",  # deploy, stop, restart, clean
    [string]$Environment = "development",  # development, test, production
    [switch]$Force = $false,
    [switch]$WithSample = $true,
    [switch]$SkipCheck = $false
)

# 全局变量
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$DOCKER_COMPOSE_FILE = Join-Path $SCRIPT_DIR "docker-compose.yml"
$ENV_FILE = Join-Path $SCRIPT_DIR ".env.${Environment}"

# 颜色输出函数
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "===================================" "Cyan"
    Write-ColorOutput $Title "Cyan"
    Write-ColorOutput "===================================" "Cyan"
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "➤ $Message" "Yellow"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" "Cyan"
}

# 检查Docker是否安装
function Test-Docker {
    Write-Step "检查Docker环境..."
    
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker已安装: $dockerVersion"
        } else {
            throw "Docker命令执行失败"
        }
    } catch {
        Write-Error "Docker未安装或不可用"
        Write-Info "请访问 https://www.docker.com/get-started 安装Docker"
        exit 1
    }
    
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker Compose已安装: $composeVersion"
        } else {
            Write-Info "尝试使用docker compose命令..."
            $composeVersion = docker compose version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Docker Compose已安装: $composeVersion"
                $global:USE_DOCKER_COMPOSE_V2 = $true
            } else {
                throw "Docker Compose命令执行失败"
            }
        }
    } catch {
        Write-Error "Docker Compose未安装或不可用"
        exit 1
    }
}

# 创建环境文件
function New-EnvironmentFile {
    Write-Step "创建环境配置文件..."
    
    $envContent = @"
# GCCC Database Environment Configuration
# Environment: $Environment
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# PostgreSQL Configuration
POSTGRES_DB=gccc_${Environment}_db
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
COMPOSE_PROJECT_NAME=gccc-${Environment}
DOCKER_NETWORK=gccc-${Environment}-network

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
'@

    $composeContent | Out-File -FilePath $DOCKER_COMPOSE_FILE -Encoding UTF8
    Write-Success "Docker Compose文件已创建: $DOCKER_COMPOSE_FILE"
}

# 创建Redis配置文件
function New-RedisConfig {
    Write-Step "创建Redis配置文件..."
    
    $redisConfigPath = Join-Path $SCRIPT_DIR "redis.conf"
    $redisConfig = @'
# GCCC Redis Configuration
# Environment: ${Environment}

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
'@

    $redisConfig | Out-File -FilePath $redisConfigPath -Encoding UTF8
    Write-Success "Redis配置文件已创建: $redisConfigPath"
}

# 创建初始化目录和文件
function New-InitStructure {
    Write-Step "创建初始化结构..."
    
    # 创建目录
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

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create application user
DO ```$```$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gccc_app') THEN
        CREATE ROLE gccc_app WITH LOGIN PASSWORD 'gccc_app_password_2024';
    END IF;
END
```$```$;

-- Grant permissions
GRANT CONNECT ON DATABASE gccc_$($Environment)_db TO gccc_app;
GRANT CREATE ON SCHEMA public TO gccc_app;
GRANT USAGE ON SCHEMA public TO gccc_app;

-- Create basic monitoring functions
CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS ```$```$
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
```$```$ LANGUAGE plpgsql;

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
) AS ```$```$
BEGIN
    RETURN QUERY 
    SELECT sm.version::TEXT, sm.description, sm.executed_at, sm.success
    FROM schema_migrations sm
    ORDER BY sm.executed_at DESC;
END;
```$```$ LANGUAGE plpgsql;

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
('app.environment', '$Environment', 'Application environment'),
('deployment.timestamp', '$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")', 'Deployment timestamp'),
('health.check.enabled', 'true', 'Health check enabled'),
('logging.level', 'info', 'Logging level')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = CURRENT_TIMESTAMP;

-- Log successful initialization
DO ```$```$
BEGIN
    RAISE NOTICE 'GCCC Database initialized successfully for % environment', '$Environment';
END
```$```$;
"@
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
`$`$ LANGUAGE plpgsql;

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
) AS `$`$
BEGIN
    RETURN QUERY 
    SELECT sm.version::TEXT, sm.description, sm.executed_at, sm.success
    FROM schema_migrations sm
    ORDER BY sm.executed_at DESC;
END;
`$`$ LANGUAGE plpgsql;

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
('app.environment', '$Environment', 'Application environment'),
('deployment.timestamp', '$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")', 'Deployment timestamp'),
('health.check.enabled', 'true', 'Health check enabled'),
('logging.level', 'info', 'Logging level')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = CURRENT_TIMESTAMP;

-- Log successful initialization
DO `$`$
BEGIN
    RAISE NOTICE 'GCCC Database initialized successfully for % environment', '$Environment';
END
`$`$;
"@

    $initSql | Out-File -FilePath $initSqlPath -Encoding UTF8
    Write-Success "初始化SQL脚本已创建"
}

# 部署数据库
function Start-DatabaseDeployment {
    Write-Header "开始部署GCCC数据库"
    
    Write-Step "检查现有容器..."
    $existingContainers = docker ps -a --filter "name=$($Environment)" --format "table {{.Names}}" 2>$null
    
    if ($existingContainers -and !$Force) {
        Write-Info "发现现有容器:"
        Write-Host $existingContainers
        
        $response = Read-Host "是否要强制重新部署? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-Info "部署已取消"
            return
        }
        $Force = $true
    }
    
    if ($Force) {
        Write-Step "停止并移除现有容器..."
        if ($global:USE_DOCKER_COMPOSE_V2) {
            docker compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE down -v --remove-orphans 2>$null
        } else {
            docker-compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE down -v --remove-orphans 2>$null
        }
        Write-Success "现有容器已清理"
    }
    
    Write-Step "启动数据库服务..."
    if ($global:USE_DOCKER_COMPOSE_V2) {
        docker compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE up -d
    } else {
        docker-compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE up -d
    }
    
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
        $healthCheck = docker exec "$($Environment)-postgres" pg_isready -U gccc_user -d "gccc_${Environment}_db" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PostgreSQL已就绪 (等待了 ${waited} 秒)"
            break
        }
        Write-Host "." -NoNewline
    } while ($waited -lt $maxWait)
    
    if ($waited -ge $maxWait) {
        Write-Error "PostgreSQL启动超时"
        exit 1
    }
    
    Write-Step "验证Redis连接..."
    $redisCheck = docker exec "$($Environment)-redis" redis-cli ping 2>$null
    if ($redisCheck -eq "PONG") {
        Write-Success "Redis连接正常"
    } else {
        Write-Error "Redis连接失败"
    }
}

# 停止数据库服务
function Stop-DatabaseServices {
    Write-Header "停止GCCC数据库服务"
    
    Write-Step "停止数据库容器..."
    if ($global:USE_DOCKER_COMPOSE_V2) {
        docker compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE stop
    } else {
        docker-compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE stop
    }
    
    Write-Success "数据库服务已停止"
}

# 重启数据库服务
function Restart-DatabaseServices {
    Write-Header "重启GCCC数据库服务"
    
    Stop-DatabaseServices
    Start-Sleep -Seconds 3
    Start-DatabaseDeployment
}

# 清理部署
function Remove-DatabaseDeployment {
    Write-Header "清理GCCC数据库部署"
    
    if (!$Force) {
        Write-Error "清理操作需要使用 -Force 参数确认"
        Write-Info "这将删除所有数据库数据，请谨慎操作"
        return
    }
    
    Write-Step "停止并移除所有服务..."
    if ($global:USE_DOCKER_COMPOSE_V2) {
        docker compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE down -v --remove-orphans --rmi local
    } else {
        docker-compose --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE down -v --remove-orphans --rmi local
    }
    
    Write-Step "清理数据目录..."
    if (Test-Path (Join-Path $SCRIPT_DIR "data")) {
        Remove-Item -Path (Join-Path $SCRIPT_DIR "data") -Recurse -Force
        Write-Success "数据目录已清理"
    }
    
    Write-Success "数据库部署已完全清理"
}

# 运行状态检查
function Invoke-StatusCheck {
    if (!$SkipCheck) {
        Write-Header "运行数据库状态检查"
        
        $checkScriptPath = Join-Path $SCRIPT_DIR "check_status.ps1"
        if (Test-Path $checkScriptPath) {
            & $checkScriptPath -DbHost "localhost" -DbPort "5432" -DbName "gccc_${Environment}_db" -DbUser "gccc_user"
        } else {
            Write-Info "状态检查脚本未找到，跳过状态检查"
        }
    }
}

# 显示部署信息
function Show-DeploymentInfo {
    Write-Header "部署信息"
    
    Write-ColorOutput "环境: $Environment" "Cyan"
    Write-ColorOutput "项目名: gccc-$Environment" "Cyan"
    Write-Host ""
    
    Write-ColorOutput "数据库连接信息:" "Yellow"
    Write-Host "  PostgreSQL: localhost:5432"
    Write-Host "  数据库名: gccc_${Environment}_db"  
    Write-Host "  用户名: gccc_user"
    Write-Host "  Redis: localhost:6379"
    Write-Host ""
    
    Write-ColorOutput "管理工具:" "Yellow"
    Write-Host "  Adminer (可选): http://localhost:8080"
    Write-Host "  启用命令: docker-compose --profile admin up -d adminer"
    Write-Host ""
    
    Write-ColorOutput "常用命令:" "Yellow"
    Write-Host "  查看日志: docker-compose logs -f"
    Write-Host "  进入PostgreSQL: docker exec -it gccc-$Environment-postgres psql -U gccc_user -d gccc_${Environment}_db"
    Write-Host "  进入Redis: docker exec -it gccc-$Environment-redis redis-cli"
    Write-Host "  状态检查: .\deploy_database.ps1 -Action status"
    Write-Host ""
}

# 主程序
function Main {
    Write-Header "GCCC 数据库一键部署脚本"
    Write-ColorOutput "环境: $Environment" "Cyan"
    Write-ColorOutput "操作: $Action" "Cyan"
    
    # 检查Docker环境
    Test-Docker
    
    # 创建必要文件
    New-EnvironmentFile
    New-DockerComposeFile
    New-RedisConfig
    New-InitStructure
    
    # 根据操作执行相应命令
    switch ($Action.ToLower()) {
        "deploy" {
            Start-DatabaseDeployment
            Invoke-StatusCheck
            Show-DeploymentInfo
        }
        "stop" {
            Stop-DatabaseServices
        }
        "restart" {
            Restart-DatabaseServices
            Invoke-StatusCheck
        }
        "clean" {
            Remove-DatabaseDeployment
        }
        "status" {
            Invoke-StatusCheck
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
    Write-Info "请检查错误信息并重试"
    exit 1
}

# 执行主程序
Main
