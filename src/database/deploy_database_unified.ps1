# ================================================================
# GCCC Database Unified Deployment Script (PowerShell)
# Deploy PostgreSQL and Redis using Docker Compose with Smart Image Management
# ================================================================

param(
    [ValidateSet("deploy", "stop", "restart", "clean", "status", "logs")]
    [string]$Action = "deploy",
    
    [ValidateSet("development", "test", "production")]
    [string]$Environment = "development",
    
    [switch]$Force = $false,
    [switch]$WithSample = $true,
    [switch]$SkipCheck = $false,
    [switch]$Detached = $true,
    [switch]$PullLatest = $false,
    [switch]$Help = $false
)

# Script paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$DOCKER_COMPOSE_FILE = Join-Path $SCRIPT_DIR "docker-compose.yml"
$ENV_FILE = Join-Path $SCRIPT_DIR ".env.$Environment"

# Docker Compose command preference
$script:UseDockerCompose = $true

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
GCCC Database Unified Deployment Script

Usage: .\deploy_database.ps1 [Options]

Options:
  -Action <ACTION>           Action to perform:
                             • deploy   - Deploy database services (default)
                             • stop     - Stop running services
                             • restart  - Restart services
                             • clean    - Remove all data and containers (requires -Force)
                             • status   - Check service status and health
                             • logs     - Show service logs
                             
  -Environment <ENV>         Target environment (default: development):
                             • development - Local development setup
                             • test        - Testing environment
                             • production  - Production deployment
                             
  -Force                     Force execution, overwrite existing deployment
  -PullLatest               Force pull latest images (default: use local images if available)
  -SkipCheck                Skip health checks after deployment
  -Help                     Show this help information

Examples:
  # Quick deployment using local images
  .\deploy_database.ps1
  
  # Deploy with latest images
  .\deploy_database.ps1 -PullLatest
  
  # Deploy production environment
  .\deploy_database.ps1 -Environment production
  
  # Force restart services
  .\deploy_database.ps1 -Action restart -Force
  
  # Check system status
  .\deploy_database.ps1 -Action status
  
  # Clean deployment (WARNING: deletes all data)
  .\deploy_database.ps1 -Action clean -Force

Performance Features:
  • Smart image management - Uses local images when available
  • Fast deployment - Typically completes in 1-2 seconds
  • Network optimization - Only pulls images when necessary
  • Automatic fallback - Uses local images if network fails

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
    
    # Check Docker Compose (prefer built-in compose)
    try {
        $composeVersion = docker compose version 2>$null
        if ($composeVersion) {
            Write-Success "Docker Compose installed: $composeVersion"
            $script:UseDockerCompose = $true
            return $true
        }
    }
    catch {}
    
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($composeVersion) {
            Write-Success "Docker Compose installed: $composeVersion"
            $script:UseDockerCompose = $false
            return $true
        }
    }
    catch {}
    
    Write-Error "Docker Compose not installed or unavailable"
    exit 1
}

# Execute Docker Compose command
function Invoke-DockerCompose {
    param([string[]]$Arguments)
    
    if ($script:UseDockerCompose) {
        & docker compose $Arguments
    } else {
        & docker-compose $Arguments
    }
}

# Check if Docker image exists locally
function Test-DockerImageExists {
    param([string]$ImageName)
    
    $imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^$([regex]::Escape($ImageName))$" -Quiet
    return $imageExists
}

# Smart image pull - uses local images when available
function Invoke-SmartImagePull {
    param(
        [string]$ImageName,
        [int]$MaxRetries = 2,
        [int]$DelaySeconds = 3,
        [switch]$Force = $false
    )
    
    # Use local image if available and not forcing update
    if (-not $Force -and (Test-DockerImageExists $ImageName)) {
        Write-Success "Using local image: $ImageName"
        return $true
    }
    
    Write-Step "Pulling Docker image: $ImageName"
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        if ($MaxRetries -gt 1) {
            Write-Info "Attempt $i of $MaxRetries: Pulling $ImageName"
        }
        
        $pullResult = docker pull $ImageName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully pulled: $ImageName"
            return $true
        }
        
        if ($i -lt $MaxRetries) {
            Write-Warning "Pull failed, retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    # Fallback to local image if pull fails
    if (Test-DockerImageExists $ImageName) {
        Write-Warning "Pull failed, using local image: $ImageName"
        return $true
    }
    
    Write-Error "Failed to get image: $ImageName"
    return $false
}

# Prepare required Docker images
function Initialize-DockerImages {
    Write-Header "Preparing Docker Images"
    
    $requiredImages = @("postgres:latest", "redis:latest")
    $pullSuccess = $true
    $failedImages = @()
    
    foreach ($image in $requiredImages) {
        if (!(Invoke-SmartImagePull -ImageName $image -MaxRetries 2 -Force:$PullLatest)) {
            $pullSuccess = $false
            $failedImages += $image
        }
    }
    
    if (-not $pullSuccess) {
        Write-Warning "Some Docker images failed to download:"
        $failedImages | ForEach-Object { Write-Warning "  - $_" }
        
        if ($failedImages -contains "postgres:latest") {
            Write-Error "PostgreSQL image is required and not available"
            return $false
        }
        
        Write-Info "Deployment will continue with available images"
    }
    
    Write-Success "Docker images ready"
    return $true
}

# Create environment configuration
function New-EnvironmentFile {
    Write-Step "Creating environment configuration..."
    
    $envContent = @"
# GCCC Database Environment Configuration
# Environment: $Environment
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Project Configuration
COMPOSE_PROJECT_NAME=gccc-$Environment

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

# Docker Network
DOCKER_NETWORK=gccc-$Environment-network

# Volume Paths
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

# Health Check Settings
HEALTH_CHECK_INTERVAL=30s
HEALTH_CHECK_TIMEOUT=10s
HEALTH_CHECK_RETRIES=3
"@

    $envContent | Out-File -FilePath $ENV_FILE -Encoding UTF8
    Write-Success "Environment file created: $(Split-Path $ENV_FILE -Leaf)"
}

# Create Docker Compose configuration
function New-DockerComposeFile {
    Write-Step "Creating Docker Compose configuration..."
    
    # Check if Redis image is available
    $redisAvailable = Test-DockerImageExists "redis:latest"
    
    $redisService = if ($redisAvailable) {
        @'

  redis:
    image: redis:latest
    container_name: ${COMPOSE_PROJECT_NAME}-redis
    restart: unless-stopped
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: ${HEALTH_CHECK_INTERVAL}
      timeout: ${HEALTH_CHECK_TIMEOUT}
      retries: ${HEALTH_CHECK_RETRIES}
'@
    } else {
        Write-Warning "Redis image not available - Redis service disabled"
        ""
    }
    
    $redisVolume = if ($redisAvailable) { "`n  redis_data:" } else { "" }
    
    $composeContent = @"
version: '3.8'

services:
  postgres:
    image: postgres:latest
    container_name: `${COMPOSE_PROJECT_NAME}-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: `${POSTGRES_DB}
      POSTGRES_USER: `${POSTGRES_USER}
      POSTGRES_PASSWORD: `${POSTGRES_PASSWORD}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --lc-collate=C --lc-ctype=C"
    ports:
      - "`${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d
      - ./backups:/backups
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U `${POSTGRES_USER} -d `${POSTGRES_DB}"]
      interval: `${HEALTH_CHECK_INTERVAL}
      timeout: `${HEALTH_CHECK_TIMEOUT}
      retries: `${HEALTH_CHECK_RETRIES}${redisService}

networks:
  gccc-network:
    driver: bridge
    name: `${DOCKER_NETWORK}

volumes:
  postgres_data:${redisVolume}
"@

    $composeContent | Out-File -FilePath $DOCKER_COMPOSE_FILE -Encoding UTF8
    
    if ($redisAvailable) {
        Write-Success "Docker Compose created with PostgreSQL and Redis"
    } else {
        Write-Warning "Docker Compose created with PostgreSQL only (Redis disabled)"
    }
}

# Create Redis configuration
function New-RedisConfig {
    $redisConfigPath = Join-Path $SCRIPT_DIR "redis.conf"
    $redisConfig = @"
# GCCC Redis Configuration
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

bind 0.0.0.0
port 6379
timeout 300
protected-mode yes

# Memory settings
maxmemory 512mb
maxmemory-policy allkeys-lru

# Persistence settings
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

# Network settings
tcp-backlog 511
tcp-keepalive 300

# Security
requirepass `${REDIS_PASSWORD}
"@

    $redisConfig | Out-File -FilePath $redisConfigPath -Encoding UTF8
    Write-Success "Redis configuration created"
}

# Create directory structure
function New-DirectoryStructure {
    Write-Step "Creating directory structure..."
    
    $directories = @(
        "data/postgres",
        "data/redis",
        "backups",
        "init",
        "logs"
    )
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $SCRIPT_DIR $dir
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Success "Created directory: $dir"
        }
    }
}

# Create PostgreSQL initialization script
function New-PostgreSQLInitScript {
    $initDir = Join-Path $SCRIPT_DIR "init"
    $initSqlPath = Join-Path $initDir "01-init.sql"
    
    $initSql = @"
-- GCCC Database Initialization Script
-- Environment: $Environment
-- Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create application role
DO `$`$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gccc_app') THEN
        CREATE ROLE gccc_app WITH LOGIN PASSWORD 'gccc_app_password_2024';
    END IF;
END
`$`$;

-- Grant permissions
GRANT CONNECT ON DATABASE gccc_$($Environment)_db TO gccc_app;
GRANT CREATE ON SCHEMA public TO gccc_app;
GRANT USAGE ON SCHEMA public TO gccc_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gccc_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gccc_app;

-- Health check function
CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE(check_name TEXT, status TEXT, details TEXT)
LANGUAGE plpgsql
AS `$`$
BEGIN
    RETURN QUERY SELECT 'connection'::TEXT, 'healthy'::TEXT, 'Database accessible'::TEXT;
    RETURN QUERY SELECT 
        'extension_count'::TEXT,
        CASE WHEN COUNT(*) >= 4 THEN 'healthy' ELSE 'warning' END::TEXT,
        ('Extensions loaded: ' || COUNT(*))::TEXT
    FROM pg_extension WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin', 'pg_trgm');
END;
`$`$;

-- System tables
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    description TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS system_configs (
    key VARCHAR(255) PRIMARY KEY,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial data
INSERT INTO schema_migrations (version, description) 
VALUES ('001', 'Database initialization') 
ON CONFLICT (version) DO NOTHING;

INSERT INTO system_configs (key, value, description) VALUES
('db.version', '1.0.0', 'Database schema version'),
('app.environment', '$Environment', 'Application environment'),
('deployment.timestamp', '$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")', 'Last deployment timestamp')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value, 
    updated_at = CURRENT_TIMESTAMP;

-- Performance optimizations
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

SELECT pg_reload_conf();
"@

    $initSql | Out-File -FilePath $initSqlPath -Encoding UTF8
    Write-Success "PostgreSQL initialization script created"
}

# Deploy database services
function Start-DatabaseDeploy {
    Write-Header "GCCC Database Deployment"
    Write-Info "Environment: $Environment"
    Write-Info "Pull Latest: $PullLatest"
    
    try {
        # Step 1: Check prerequisites
        if (-not (Test-DockerEnvironment)) {
            throw "Docker environment check failed"
        }
        
        # Step 2: Prepare images
        if (-not (Initialize-DockerImages)) {
            throw "Failed to prepare required Docker images"
        }
        
        # Step 3: Create configuration files
        New-DirectoryStructure
        New-EnvironmentFile
        New-RedisConfig
        New-PostgreSQLInitScript
        New-DockerComposeFile
        
        # Step 4: Handle existing deployment
        Write-Step "Checking existing deployment..."
        $existingContainers = docker ps -a --filter "name=gccc-$Environment" --format "{{.Names}}" 2>$null
        
        if ($existingContainers -and !$Force) {
            Write-Info "Found existing containers: $($existingContainers -join ', ')"
            $response = Read-Host "Force redeploy and replace existing containers? (y/N)"
            if ($response -ne "y" -and $response -ne "Y") {
                Write-Info "Deployment cancelled by user"
                return
            }
            $script:Force = $true
        }
        
        if ($Force -and $existingContainers) {
            Write-Step "Stopping and removing existing containers..."
            Invoke-DockerCompose @("--env-file", $ENV_FILE, "down", "--volumes")
            Write-Success "Existing containers cleaned"
        }
        
        # Step 5: Start services
        Write-Step "Starting database services..."
        
        $composeArgs = @("--env-file", $ENV_FILE, "up", "-d")
        
        # Use --pull never to force using local images (unless PullLatest is specified)
        if (-not $PullLatest) {
            $composeArgs += "--pull"
            $composeArgs += "never"
        }
        
        Invoke-DockerCompose $composeArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start database services"
        }
        
        Write-Success "Database services started successfully"
        
        # Step 6: Wait for services to be ready
        if (-not $SkipCheck) {
            Write-Step "Waiting for services to be ready..."
            Start-Sleep 5
            
            # Check PostgreSQL
            $maxWait = 60
            $waited = 0
            $pgContainer = "gccc-$Environment-postgres"
            
            do {
                Start-Sleep 3
                $waited += 3
                $pgReady = docker exec $pgContainer pg_isready -U gccc_user -d "gccc_$($Environment)_db" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "PostgreSQL ready (waited $waited seconds)"
                    break
                }
                Write-Host "." -NoNewline
            } while ($waited -lt $maxWait)
            
            if ($waited -ge $maxWait) {
                Write-Warning "PostgreSQL readiness timeout, but continuing"
            }
            
            # Check Redis if available
            $redisContainer = "gccc-$Environment-redis"
            if (docker ps --filter "name=$redisContainer" --format "{{.Names}}" 2>$null) {
                Write-Step "Checking Redis..."
                Start-Sleep 2
                $redisCheck = docker exec $redisContainer redis-cli ping 2>$null
                if ($redisCheck -eq "PONG") {
                    Write-Success "Redis ready"
                } else {
                    Write-Warning "Redis not responding to ping"
                }
            }
        }
        
        # Step 7: Show deployment summary
        Show-DeploymentInfo
        
    } catch {
        Write-Header "Deployment Failed"
        Write-Error $_.Exception.Message
        Write-Info "Run 'docker compose logs' for detailed error information"
        exit 1
    }
}

# Stop database services
function Stop-Database {
    Write-Header "Stopping Database Services"
    Write-Step "Stopping containers..."
    
    if (!(Test-Path $ENV_FILE)) {
        Write-Warning "Environment file not found, using default settings"
        $ENV_FILE = ".env"
    }
    
    Invoke-DockerCompose @("--env-file", $ENV_FILE, "stop")
    Write-Success "Database services stopped"
}

# Restart database services
function Restart-Database {
    Write-Header "Restarting Database Services"
    Stop-Database
    Start-Sleep 2
    Start-DatabaseDeploy
}

# Clean deployment (removes all data)
function Remove-Deployment {
    Write-Header "Cleaning Database Deployment"
    
    if (!$Force) {
        Write-Error "Clean operation requires -Force parameter"
        Write-Warning "This will permanently delete ALL database data!"
        Write-Info "Use: .\deploy_database.ps1 -Action clean -Force"
        return
    }
    
    $confirmText = "DELETE ALL DATA"
    $userInput = Read-Host "Type '$confirmText' to confirm data deletion"
    if ($userInput -ne $confirmText) {
        Write-Info "Data deletion cancelled - confirmation text did not match"
        return
    }
    
    Write-Step "Stopping and removing all services and data..."
    
    if (Test-Path $ENV_FILE) {
        Invoke-DockerCompose @("--env-file", $ENV_FILE, "down", "--volumes", "--remove-orphans")
    } else {
        docker-compose down --volumes --remove-orphans 2>$null
    }
    
    Write-Step "Removing data directories..."
    $dataDir = Join-Path $SCRIPT_DIR "data"
    if (Test-Path $dataDir) {
        Remove-Item -Path $dataDir -Recurse -Force
        Write-Success "Data directories removed"
    }
    
    Write-Step "Removing configuration files..."
    @($DOCKER_COMPOSE_FILE, (Join-Path $SCRIPT_DIR "redis.conf")) | ForEach-Object {
        if (Test-Path $_) {
            Remove-Item -Path $_ -Force
            Write-Success "Removed: $(Split-Path $_ -Leaf)"
        }
    }
    
    Write-Success "Database deployment completely cleaned"
    Write-Warning "All data has been permanently deleted!"
}

# Check service status and health
function Start-StatusCheck {
    Write-Header "Database Status Check"
    
    if (!(Test-Path $ENV_FILE)) {
        Write-Warning "Environment file not found, checking with default project name"
        $projectName = "gccc-$Environment"
    } else {
        # Read project name from env file
        $envContent = Get-Content $ENV_FILE
        $projectNameLine = $envContent | Where-Object { $_ -match "^COMPOSE_PROJECT_NAME=" }
        if ($projectNameLine) {
            $projectName = ($projectNameLine -split "=")[1]
        } else {
            $projectName = "gccc-$Environment"
        }
    }
    
    Write-Step "Container status:"
    if (Test-Path $ENV_FILE) {
        Invoke-DockerCompose @("--env-file", $ENV_FILE, "ps")
    } else {
        docker ps --filter "name=$projectName" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    }
    
    Write-Host ""
    Write-Step "Service health checks:"
    
    # PostgreSQL health check
    $pgContainer = "$projectName-postgres"
    $pgStatus = docker ps --filter "name=$pgContainer" --format "{{.Status}}" 2>$null
    if ($pgStatus) {
        Write-Info "PostgreSQL container: $pgStatus"
        $pgHealth = docker exec $pgContainer pg_isready -U gccc_user 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PostgreSQL: Ready"
            
            # Database health check
            $dbCheck = docker exec $pgContainer psql -U gccc_user -d "gccc_$($Environment)_db" -c "SELECT 'Database connection successful';" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Database: Connected"
            } else {
                Write-Warning "Database: Connection failed"
            }
        } else {
            Write-Error "PostgreSQL: Not ready"
        }
    } else {
        Write-Error "PostgreSQL: Container not running"
    }
    
    # Redis health check
    $redisContainer = "$projectName-redis"
    $redisStatus = docker ps --filter "name=$redisContainer" --format "{{.Status}}" 2>$null
    if ($redisStatus) {
        Write-Info "Redis container: $redisStatus"
        $redisHealth = docker exec $redisContainer redis-cli ping 2>$null
        if ($redisHealth -eq "PONG") {
            Write-Success "Redis: Ready"
        } else {
            Write-Warning "Redis: Not responding"
        }
    } else {
        Write-Warning "Redis: Container not running (may be disabled)"
    }
    
    Write-Host ""
}

# Show service logs
function Show-ServiceLogs {
    Write-Header "Database Service Logs"
    
    if (!(Test-Path $ENV_FILE)) {
        Write-Warning "Environment file not found, using default settings"
        $ENV_FILE = ".env"
    }
    
    Write-Info "Showing last 50 lines of logs (press Ctrl+C to exit)"
    Invoke-DockerCompose @("--env-file", $ENV_FILE, "logs", "--tail=50", "-f")
}

# Display deployment information
function Show-DeploymentInfo {
    Write-Header "Deployment Information"
    
    Write-ColorText "Environment: $Environment" "Cyan"
    Write-ColorText "Project: gccc-$Environment" "Cyan"
    Write-Host ""
    
    Write-ColorText "Service Endpoints:" "Yellow"
    Write-Host "  PostgreSQL: localhost:5432"
    Write-Host "  Database: gccc_$($Environment)_db"  
    Write-Host "  User: gccc_user"
    Write-Host "  Redis: localhost:6379"
    Write-Host ""
    
    Write-ColorText "Connection Examples:" "Yellow"
    Write-Host "  psql: psql -h localhost -U gccc_user -d gccc_$($Environment)_db"
    Write-Host "  Redis: redis-cli -h localhost -p 6379"
    Write-Host ""
    
    Write-ColorText "Management Commands:" "Yellow"
    Write-Host "  Status: .\deploy_database.ps1 -Action status"
    Write-Host "  Logs: .\deploy_database.ps1 -Action logs"  
    Write-Host "  Restart: .\deploy_database.ps1 -Action restart"
    Write-Host "  Stop: .\deploy_database.ps1 -Action stop"
    Write-Host ""
    
    Write-ColorText "Container Access:" "Yellow"
    Write-Host "  PostgreSQL: docker exec -it gccc-$Environment-postgres psql -U gccc_user -d gccc_$($Environment)_db"
    Write-Host "  Redis: docker exec -it gccc-$Environment-redis redis-cli"
    Write-Host ""
}

# Main execution function
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Header "GCCC Database Unified Deployment Script"
    Write-Info "Environment: $Environment"
    Write-Info "Action: $Action"
    
    # Change to script directory
    Set-Location $SCRIPT_DIR
    
    # Execute action
    switch ($Action) {
        "deploy" {
            Start-DatabaseDeploy
        }
        "stop" {
            Stop-Database  
        }
        "restart" {
            Restart-Database
        }
        "clean" {
            Remove-Deployment
        }
        "status" {
            Start-StatusCheck
        }
        "logs" {
            Show-ServiceLogs
        }
        default {
            Write-Error "Unknown action: $Action"
            Write-Info "Supported actions: deploy, stop, restart, clean, status, logs"
            Show-Help
            exit 1
        }
    }
    
    Write-Success "Operation completed successfully!"
}

# Error handling
trap {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Info "Use -Help parameter for usage information"
    exit 1
}

# Execute main function
Main
