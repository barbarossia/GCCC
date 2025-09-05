# ================================================================
# GCCC Database One-Click Deployment Script (PowerShell Version)
# Deploy PostgreSQL and Redis using Docker
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

# Script directory and project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$DOCKER_COMPOSE_FILE = Join-Path $SCRIPT_DIR "docker-compose.yml"
$ENV_FILE = Join-Path $SCRIPT_DIR ".env.$Environment"

# Color output functions
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

function Write-Info { param([string]$Message) Write-ColorText "INFO: $Message" "Cyan" }
function Write-Success { param([string]$Message) Write-ColorText "SUCCESS: $Message" "Green" }
function Write-Error { param([string]$Message) Write-ColorText "ERROR: $Message" "Red" }
function Write-Warning { param([string]$Message) Write-ColorText "WARNING: $Message" "Yellow" }
function Write-Step { param([string]$Message) Write-ColorText "STEP: $Message" "Yellow" }
function Write-Header { 
    param([string]$Message) 
    Write-Host ""
    Write-ColorText "===================================" "Cyan"
    Write-ColorText $Message "Cyan"
    Write-ColorText "===================================" "Cyan"
    Write-Host ""
}

# Show help information
function Show-Help {
    Write-Host @"
GCCC Database One-Click Deployment Script

Usage: .\deploy_database.ps1 [Options]

Options:
  -Action <ACTION>           Action: deploy, stop, restart, clean, status (default: deploy)
  -Environment <ENV>         Environment: development, test, production (default: development)  
  -Force                     Force execution, overwrite existing deployment
  -SkipCheck                 Skip status check
  -Help                      Show help information

Examples:
  .\deploy_database.ps1                                    # Deploy development environment
  .\deploy_database.ps1 -Environment production           # Deploy production environment
  .\deploy_database.ps1 -Action restart -Force            # Force restart
  .\deploy_database.ps1 -Action clean -Force              # Clean deployment
  .\deploy_database.ps1 -Action status                    # Check status

"@
}

# Check Docker environment
function Test-DockerEnvironment {
    Write-Step "Checking Docker environment..."
    
    if (!(Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Error "Docker not installed"
        Write-Info "Please visit https://www.docker.com/get-started to install Docker Desktop"
        exit 1
    }
    
    try {
        $dockerVersion = docker --version
        Write-Success "Docker installed: $dockerVersion"
    }
    catch {
        Write-Error "Docker unavailable"
        exit 1
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker compose version 2>$null
        if ($composeVersion) {
            Write-Success "Docker Compose installed: $composeVersion"
            return "docker compose"
        }
    }
    catch {}
    
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($composeVersion) {
            Write-Success "Docker Compose installed: $composeVersion"
            return "docker-compose"
        }
    }
    catch {}
    
    Write-Error "Docker Compose not installed or unavailable"
    exit 1
}

# Create environment file
function New-EnvironmentFile {
    Write-Step "Creating environment configuration file..."
    
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
    Write-Success "Environment file created: $ENV_FILE"
}

# Create Docker Compose file
function New-DockerComposeFile {
    Write-Step "Creating Docker Compose configuration..."
    
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
    Write-Success "Docker Compose file created: $DOCKER_COMPOSE_FILE"
}

# Create Redis configuration file
function New-RedisConfig {
    Write-Step "Creating Redis configuration file..."
    
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
    Write-Success "Redis config file created: $redisConfigPath"
}

# Create initialization structure
function New-InitializationStructure {
    Write-Step "Creating initialization structure..."
    
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
            Write-Success "Created directory: $dir"
        }
    }
    
    # Create initialization SQL script
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
    Write-Success "Initialization SQL script created"
}

# Deploy database
function Start-DatabaseDeploy {
    param([string]$ComposeCmd)
    
    Write-Header "Starting GCCC Database Deployment"
    
    Write-Step "Checking existing containers..."
    $existingContainers = docker ps -a --filter "name=$Environment" --format "{{.Names}}" 2>$null
    
    if ($existingContainers -and !$Force) {
        Write-Info "Found existing containers:"
        $existingContainers
        $response = Read-Host "Force redeploy? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "Deployment cancelled"
            return
        }
        $script:Force = $true
    }
    
    if ($Force) {
        Write-Step "Stopping and removing existing containers..."
        & $ComposeCmd.Split(' ') --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE down -v --remove-orphans 2>$null
        Write-Success "Existing containers cleaned"
    }
    
    Write-Step "Starting database services..."
    $result = & $ComposeCmd.Split(' ') --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database services started successfully"
    } else {
        Write-Error "Database services failed to start"
        exit 1
    }
    
    Write-Step "Waiting for database to be ready..."
    $maxWait = 60
    $waited = 0
    
    do {
        Start-Sleep -Seconds 2
        $waited += 2
        $pgReady = docker exec "gccc-$Environment-postgres" pg_isready -U gccc_user -d "gccc_$($Environment)_db" 2>$null
        if ($pgReady) {
            Write-Success "PostgreSQL ready (waited $waited seconds)"
            break
        }
        Write-Host "." -NoNewline
    } while ($waited -lt $maxWait)
    
    if ($waited -ge $maxWait) {
        Write-Error "PostgreSQL startup timeout"
        exit 1
    }
    
    Write-Step "Verifying Redis connection..."
    $redisCheck = docker exec "gccc-$Environment-redis" redis-cli ping 2>$null
    if ($redisCheck -eq "PONG") {
        Write-Success "Redis connection OK"
    } else {
        Write-Error "Redis connection failed"
    }
}

# Stop database services
function Stop-Database {
    param([string]$ComposeCmd)
    
    Write-Header "Stopping GCCC Database Services"
    Write-Step "Stopping database containers..."
    
    & $ComposeCmd.Split(' ') --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE stop
    Write-Success "Database services stopped"
}

# Restart database services
function Restart-Database {
    param([string]$ComposeCmd)
    
    Write-Header "Restarting GCCC Database Services"
    Stop-Database $ComposeCmd
    Start-Sleep -Seconds 3
    Start-DatabaseDeploy $ComposeCmd
}

# Clean deployment
function Remove-Deployment {
    param([string]$ComposeCmd)
    
    Write-Header "Cleaning GCCC Database Deployment"
    
    if (!$Force) {
        Write-Error "Clean operation requires -Force parameter"
        Write-Info "This will delete all database data, use carefully"
        return
    }
    
    Write-Step "Stopping and removing all services..."
    & $ComposeCmd.Split(' ') --env-file $ENV_FILE -f $DOCKER_COMPOSE_FILE down -v --remove-orphans --rmi local 2>$null
    
    Write-Step "Cleaning data directories..."
    $dataDir = Join-Path $SCRIPT_DIR "data"
    if (Test-Path $dataDir) {
        Remove-Item -Path $dataDir -Recurse -Force
        Write-Success "Data directories cleaned"
    }
    
    Write-Success "Database deployment completely cleaned"
}

# Run status check
function Start-StatusCheck {
    if (!$SkipCheck) {
        Write-Header "Running Database Status Check"
        
        $checkScript = Join-Path $SCRIPT_DIR "check_status.ps1"
        if (Test-Path $checkScript) {
            & $checkScript -DbHost "localhost" -DbPort "5432" -DbName "gccc_$($Environment)_db" -DbUser "gccc_user"
        } else {
            Write-Info "Status check script not found, skipping check"
        }
    }
}

# Show deployment information
function Show-DeploymentInfo {
    Write-Header "Deployment Information"
    
    Write-ColorText "Environment: $Environment" "Cyan"
    Write-ColorText "Project Name: gccc-$Environment" "Cyan"
    Write-Host ""
    
    Write-ColorText "Database Connection Info:" "Yellow"
    Write-Host "  PostgreSQL: localhost:5432"
    Write-Host "  Database Name: gccc_$($Environment)_db"  
    Write-Host "  Username: gccc_user"
    Write-Host "  Redis: localhost:6379"
    Write-Host ""
    
    Write-ColorText "Admin Tools:" "Yellow"
    Write-Host "  Adminer (optional): http://localhost:8080"
    Write-Host "  Enable command: docker compose --profile admin up -d adminer"
    Write-Host ""
    
    Write-ColorText "Common Commands:" "Yellow"
    Write-Host "  View logs: docker compose logs -f"
    Write-Host "  Enter PostgreSQL: docker exec -it gccc-$Environment-postgres psql -U gccc_user -d gccc_$($Environment)_db"
    Write-Host "  Enter Redis: docker exec -it gccc-$Environment-redis redis-cli"
    Write-Host ""
}

# Main program
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Header "GCCC Database One-Click Deployment Script"
    Write-ColorText "Environment: $Environment" "Cyan"
    Write-ColorText "Action: $Action" "Cyan"
    
    # Check Docker environment
    $composeCmd = Test-DockerEnvironment
    
    # Create necessary files
    New-EnvironmentFile
    New-DockerComposeFile
    New-RedisConfig
    New-InitializationStructure
    
    # Execute corresponding commands based on action
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
            Write-Error "Unknown action: $Action"
            Write-Info "Supported actions: deploy, stop, restart, clean, status"
            exit 1
        }
    }
    
    Write-Success "Operation completed!"
}

# Error handling
trap {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

# Execute main program
Main
