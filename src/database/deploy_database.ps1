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

# Execute Docker Compose command with retry
function Invoke-DockerCompose {
    param([string[]]$Arguments)
    
    if ($script:UseDockerCompose) {
        & docker compose $Arguments
    } else {
        & docker-compose $Arguments
    }
}

# Test prerequisites
function Test-Prerequisites {
    Write-Step "Testing prerequisites..."
    
    # Check if Docker is available
    $dockerCheck = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not installed or not available in PATH"
    }
    
    # Check if Docker Compose is available
    $composeCheck = docker-compose --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose is not installed or not available in PATH"
    }
    
    Write-Success "All prerequisites met"
}

# Pull Docker images with retry mechanism
function Invoke-DockerPull {
    param(
        [string]$ImageName,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )
    
    Write-Step "Pulling Docker image: $ImageName"
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        Write-Info "Attempt $i of $MaxRetries`: Pulling $ImageName"
        
        $output = docker pull $ImageName 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully pulled $ImageName"
            return $true
        }
        
        if ($i -lt $MaxRetries) {
            Write-Warning "Failed to pull $ImageName, retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        } else {
            Write-Error "Failed to pull $ImageName after $MaxRetries attempts"
            return $false
        }
    }
}

# Pre-pull required Docker images
function Initialize-DockerImages {
    Write-Header "Preparing Docker Images"
    
    $requiredImages = @(
        "postgres:latest",
        "redis:latest"
    )
    
    $pullSuccess = $true
    $failedImages = @()
    
    foreach ($image in $requiredImages) {
        if (!(Invoke-DockerPull -ImageName $image -MaxRetries 3)) {
            $pullSuccess = $false
            $failedImages += $image
        }
    }
    
    if (-not $pullSuccess) {
        Write-Warning "Some Docker images failed to download:"
        $failedImages | ForEach-Object { Write-Warning "  - $_" }
        Write-Info "Services using failed images will be disabled"
        return $false
    }
    
    Write-Success "All required Docker images are ready"
    return $true
}
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

# Create Docker Compose file with available services
function New-DockerComposeFile {
    param([bool]$IncludeRedis = $true)
    
    Write-Step "Creating Docker Compose configuration..."
    
    # Check if Redis image is available
    $redisAvailable = $IncludeRedis -and (docker images redis:latest --quiet 2>$null)
    
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
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
'@
    } else {
        Write-Warning "Redis image not available - Redis service will be disabled"
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
      interval: 30s
      timeout: 10s
      retries: 3${redisService}

networks:
  gccc-network:
    driver: bridge

volumes:
  postgres_data:${redisVolume}
"@

    $composeContent | Out-File -FilePath "docker-compose.yml" -Encoding UTF8
    
    if ($redisAvailable) {
        Write-Host "✅ Docker Compose created with PostgreSQL and Redis" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Docker Compose created with PostgreSQL only (Redis disabled)" -ForegroundColor Yellow
    }
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
}

# Create environment file
function New-EnvFile {
    Write-Step "Creating environment configuration..."
    
    # Create .env file with all necessary variables
    $envContent = @"
# GCCC Database Configuration
# Environment: $Environment
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

COMPOSE_PROJECT_NAME=gccc-$Environment
POSTGRES_DB=gccc_$($Environment)_db
POSTGRES_USER=gccc_user
POSTGRES_PASSWORD=gccc_secure_password_2024
POSTGRES_PORT=5432
REDIS_PASSWORD=redis_secure_password_2024
REDIS_PORT=6379
"@

    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Success "Environment file created"
}

# Create PostgreSQL initialization script
function New-PostgresInitScript {
    # Ensure init directory exists
    $initDir = Join-Path $SCRIPT_DIR "init"
    if (!(Test-Path $initDir)) {
        New-Item -ItemType Directory -Path $initDir -Force | Out-Null
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

DO `$`$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gccc_app') THEN
        CREATE ROLE gccc_app WITH LOGIN PASSWORD 'gccc_app_password_2024';
    END IF;
END
`$`$;

GRANT CONNECT ON DATABASE gccc_$($Environment)_db TO gccc_app;
GRANT CREATE ON SCHEMA public TO gccc_app;
GRANT USAGE ON SCHEMA public TO gccc_app;

CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE(check_name TEXT, status TEXT, details TEXT)
AS `$`$
BEGIN
    RETURN QUERY SELECT 'connection'::TEXT, 'healthy'::TEXT, 'Database accessible'::TEXT;
    RETURN QUERY SELECT 
        'table_count'::TEXT,
        CASE WHEN COUNT(*) >= 20 THEN 'healthy' ELSE 'warning' END::TEXT,
        ('Found ' || COUNT(*) || ' tables')::TEXT
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
END;
`$`$ LANGUAGE plpgsql;

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
    param([switch]$EnableRedis = $true)
    
    Write-Header "Starting GCCC Database Deployment"
    
    try {
        # Step 1: Check prerequisites
        Test-Prerequisites
        
        # Step 2: Initialize directories and configuration files
        New-InitializationStructure
        New-EnvFile
        New-PostgresInitScript
        New-RedisConfig
        
        # Step 3: Try to pull Docker images with retry
        Write-Step "Pulling Docker images..."
        $postgresSuccess = Invoke-DockerPull "postgres:latest" -MaxRetries 3
        if (-not $postgresSuccess) {
            throw "Failed to pull PostgreSQL image after multiple attempts"
        }
        Write-Success "PostgreSQL image ready"
        
        $redisSuccess = $false
        if ($EnableRedis) {
            $redisSuccess = Invoke-DockerPull "redis:latest" -MaxRetries 3
            if ($redisSuccess) {
                Write-Success "Redis image ready"
            } else {
                Write-Warning "Failed to pull Redis image - continuing with PostgreSQL only"
            }
        }
        
        # Step 4: Create Docker Compose file with available services
        New-DockerComposeFile -IncludeRedis:$redisSuccess
        
        # Step 5: Handle existing containers
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
            docker-compose down --volumes 2>$null
            Write-Success "Existing containers cleaned"
        }
        
        # Step 6: Start services
        Write-Step "Starting database services..."
        $deployResult = docker-compose up -d
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start database services"
        }
        Write-Success "Database services started successfully"
        
        # Step 7: Wait for PostgreSQL to be ready
        Write-Step "Waiting for PostgreSQL to be ready..."
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
            throw "PostgreSQL startup timeout"
        }
        
        # Step 8: Wait for Redis if enabled
        if ($redisSuccess) {
            Write-Step "Waiting for Redis to be ready..."
            $maxRedisWait = 30
            $redisWaited = 0
            
            do {
                Start-Sleep -Seconds 2
                $redisWaited += 2
                $redisCheck = docker exec "gccc-$Environment-redis" redis-cli ping 2>$null
                if ($redisCheck -eq "PONG") {
                    Write-Success "Redis ready (waited $redisWaited seconds)"
                    break
                }
                Write-Host "." -NoNewline
            } while ($redisWaited -lt $maxRedisWait)
            
            if ($redisWaited -ge $maxRedisWait) {
                Write-Warning "Redis startup timeout, but continuing deployment"
            }
        }
        
        Write-Header "Database Deployment Completed Successfully" -Color Green
        Write-Host ""
        Write-Host "Services Status:" -ForegroundColor Cyan
        Write-Host "  ✅ PostgreSQL: Running on port $env:POSTGRES_PORT" -ForegroundColor Green
        if ($redisSuccess) {
            Write-Host "  ✅ Redis: Running on port $env:REDIS_PORT" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Redis: Disabled (image not available)" -ForegroundColor Yellow
        }
        Write-Host ""
        
    } catch {
        Write-Header "Database Deployment Failed" -Color Red
        Write-Error $_.Exception.Message
        Write-Host "Run 'docker-compose logs' to see container logs" -ForegroundColor Yellow
        exit 1
    }
}

# Stop database services
function Stop-Database {
    Write-Header "Stopping GCCC Database Services"
    Write-Step "Stopping database containers..."
    
    Invoke-DockerCompose @("--env-file", $ENV_FILE, "-f", $DOCKER_COMPOSE_FILE, "stop")
    Write-Success "Database services stopped"
}

# Restart database services
function Restart-Database {
    Write-Header "Restarting GCCC Database Services"
    Stop-Database
    Start-Sleep -Seconds 3
    Start-DatabaseDeploy
}

# Clean deployment
function Remove-Deployment {
    Write-Header "Cleaning GCCC Database Deployment"
    
    if (!$Force) {
        Write-Error "Clean operation requires -Force parameter"
        Write-Info "This will delete all database data, use carefully"
        return
    }
    
    Write-Step "Stopping and removing all services..."
    Invoke-DockerCompose @("--env-file", $ENV_FILE, "-f", $DOCKER_COMPOSE_FILE, "down", "-v", "--remove-orphans", "--rmi", "local")
    
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
            & $checkScript -DbHost "localhost" -DbPort "5432" -DbName "gccc_$($Environment)_db" -DbUser "gccc_user" -DbPassword "gccc_secure_password_2024" -RedisPassword "redis_secure_password_2024"
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
    if (-not (Test-DockerEnvironment)) {
        Write-Error "Docker environment check failed"
        exit 1
    }
    
    # Create necessary files
    New-EnvironmentFile
    New-DockerComposeFile
    New-RedisConfig
    New-InitializationStructure
    
    # Execute corresponding commands based on action
    switch ($Action) {
        "deploy" {
            Start-DatabaseDeploy
            Start-StatusCheck
            Show-DeploymentInfo
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
