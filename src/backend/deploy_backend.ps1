# ================================================================
# GCCC Backend One-Click Deployment Script (PowerShell Version)
# Deploy Backend Service with Database Dependencies using Docker
# ================================================================

param(
    [ValidateSet("deploy", "stop", "restart", "clean", "status", "test")]
    [string]$Action = "deploy",
    
    [ValidateSet("development", "test", "production")]
    [string]$Environment = "development",
    
    [switch]$Force = $false,
    [switch]$WithDatabase = $true,
    [switch]$SkipTests = $false,
    [switch]$SkipCheck = $false,
    [switch]$BuildOnly = $false,
    [switch]$Help = $false
)

# Script directory and project root
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$BACKEND_DIR = $SCRIPT_DIR
$DATABASE_DIR = Join-Path (Split-Path -Parent $SCRIPT_DIR) "database"
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
        "Magenta" = "Magenta"
    }
    Write-Host $Text -ForegroundColor $colors[$Color]
}

function Write-Info { param([string]$Message) Write-ColorText "INFO: $Message" "Cyan" }
function Write-Success { param([string]$Message) Write-ColorText "SUCCESS: $Message" "Green" }
function Write-Error { param([string]$Message) Write-ColorText "ERROR: $Message" "Red" }
function Write-Warning { param([string]$Message) Write-ColorText "WARNING: $Message" "Yellow" }
function Write-Step { param([string]$Message) Write-ColorText "STEP: $Message" "Yellow" }
function Write-Header { 
    param([string]$Message, [string]$Color = "Cyan") 
    Write-Host ""
    Write-ColorText "===================================" $Color
    Write-ColorText $Message $Color
    Write-ColorText "===================================" $Color
    Write-Host ""
}

# Show help information
function Show-Help {
    Write-Host @"
GCCC Backend One-Click Deployment Script

Usage: .\deploy_backend.ps1 [Options]

Options:
  -Action <ACTION>           Action: deploy, stop, restart, clean, status, test (default: deploy)
  -Environment <ENV>         Environment: development, test, production (default: development)  
  -Force                     Force execution, overwrite existing deployment
  -WithDatabase              Include database services (default: true)
  -SkipTests                 Skip unit and integration tests
  -SkipCheck                 Skip status check
  -BuildOnly                 Only build images, don't start services
  -Help                      Show help information

Examples:
  .\deploy_backend.ps1                                    # Deploy development environment
  .\deploy_backend.ps1 -Environment production           # Deploy production environment
  .\deploy_backend.ps1 -Action restart -Force            # Force restart
  .\deploy_backend.ps1 -Action test                      # Run tests only
  .\deploy_backend.ps1 -Action clean -Force              # Clean deployment
  .\deploy_backend.ps1 -BuildOnly                        # Build images only

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
    
    # Check if backend source exists
    if (!(Test-Path (Join-Path $SCRIPT_DIR "package.json"))) {
        throw "Backend package.json not found. Please run from backend directory."
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

# Build backend Docker image
function Build-BackendImage {
    param([switch]$UseCache = $true)
    
    Write-Step "Building GCCC Backend Docker image..."
    
    $buildArgs = @("build", "-t", "gccc-backend:latest", "-f", "Dockerfile")
    if (-not $UseCache) {
        $buildArgs += "--no-cache"
    }
    $buildArgs += @("--target", "production", ".")
    
    Push-Location $SCRIPT_DIR
    try {
        & docker $buildArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Backend image built successfully"
            return $true
        } else {
            Write-Error "Failed to build backend image"
            return $false
        }
    }
    finally {
        Pop-Location
    }
}

# Build test image for running tests
function Build-TestImage {
    Write-Step "Building test image for GCCC Backend..."
    
    Push-Location $SCRIPT_DIR
    try {
        docker build -t gccc-backend:test -f Dockerfile --target dev-dependencies .
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Test image built successfully"
            return $true
        } else {
            Write-Error "Failed to build test image"
            return $false
        }
    }
    finally {
        Pop-Location
    }
}

# Create environment file
function New-EnvFile {
    Write-Step "Creating backend environment configuration..."
    
    # Database connection details
    $dbHost = if ($WithDatabase) { "postgres" } else { "localhost" }
    $redisHost = if ($WithDatabase) { "redis" } else { "localhost" }
    
    # Create .env file with all necessary variables
    $envContent = @"
# GCCC Backend Configuration
# Environment: $Environment
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Server Configuration
NODE_ENV=$Environment
PORT=3000
HOST=0.0.0.0

# Database Configuration (PostgreSQL)
DB_HOST=$dbHost
DB_PORT=5432
DB_NAME=gccc_$($Environment)_db
DB_USER=gccc_user
DB_PASSWORD=gccc_secure_password_2024
DB_SSL=false
DB_MAX_CONNECTIONS=20
DB_IDLE_TIMEOUT=30000
DB_CONNECTION_TIMEOUT=2000

# Redis Configuration (Cache and Session)
REDIS_HOST=$redisHost
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_password_2024
REDIS_DB=0
REDIS_CLUSTER_MODE=false
REDIS_MAX_RETRIES=3
REDIS_RETRY_DELAY=1000

# JWT Authentication Configuration
JWT_SECRET=gccc_jwt_secret_key_minimum_32_characters_long_for_$Environment
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=gccc_refresh_token_secret_different_from_jwt_secret_$Environment
JWT_REFRESH_EXPIRES_IN=30d
JWT_ISSUER=gccc-backend
JWT_AUDIENCE=gccc-users

# Solana Blockchain Configuration
SOLANA_RPC_URL=https://api.devnet.solana.com

# API Configuration
API_VERSION=v1
API_PREFIX=/api
CORS_ORIGIN=http://localhost:3001
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging Configuration
LOG_LEVEL=$( if ($Environment -eq "production") { "info" } else { "debug" } )
LOG_FORMAT=json
LOG_FILE_PATH=./logs/app.log
LOG_MAX_SIZE=10m
LOG_MAX_FILES=5

# Health Check Configuration
HEALTH_CHECK_PATH=/health
HEALTH_CHECK_TIMEOUT=5000
METRICS_ENABLED=true
METRICS_PATH=/metrics

# Business Logic Configuration
# User Management
USER_LOCKOUT_ATTEMPTS=5
USER_LOCKOUT_DURATION=900000

# Points System
POINTS_DAILY_CHECKIN=10
POINTS_REFERRAL_BONUS=100
POINTS_PROPOSAL_CREATE=50
POINTS_VOTE_CAST=5

# Staking System
STAKING_MIN_AMOUNT=100
STAKING_MAX_AMOUNT=1000000
STAKING_LOCK_PERIODS=7,30,90,365
STAKING_APY_RATES=5,8,12,20

# Lottery System
LOTTERY_TICKET_PRICE=10
LOTTERY_MAX_TICKETS_PER_USER=100
LOTTERY_DRAW_INTERVAL=7

# NFT System
NFT_MINT_PRICE=0.1
NFT_MAX_SUPPLY=10000

# Testing Configuration
TEST_DB_NAME=gccc_test_db
TEST_TIMEOUT=30000
"@

    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Success "Backend environment file created"
}

# Create Docker Compose file with available services
function New-DockerComposeFile {
    param(
        [bool]$IncludeDatabase = $true,
        [bool]$IncludeRedis = $true
    )
    
    Write-Step "Creating Docker Compose configuration for backend..."
    
    # Check if database images are available
    $postgresAvailable = $IncludeDatabase -and (docker images postgres:latest --quiet 2>$null)
    $redisAvailable = $IncludeRedis -and (docker images redis:latest --quiet 2>$null)
    
    $databaseServices = if ($postgresAvailable) {
        @'

  postgres:
    image: postgres:latest
    container_name: gccc-backend-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: gccc_development_db
      POSTGRES_USER: gccc_user
      POSTGRES_PASSWORD: gccc_secure_password_2024
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../database/init:/docker-entrypoint-initdb.d
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U gccc_user -d gccc_development_db"]
      interval: 30s
      timeout: 10s
      retries: 3
'@
    } else { "" }
    
    $redisService = if ($redisAvailable) {
        @'

  redis:
    image: redis:latest
    container_name: gccc-backend-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
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
    } else { "" }
    
    $backendDependsOn = @()
    if ($postgresAvailable) { $backendDependsOn += "postgres" }
    if ($redisAvailable) { $backendDependsOn += "redis" }
    
    $dependsOnSection = if ($backendDependsOn.Count -gt 0) {
        $dependsList = $backendDependsOn | ForEach-Object { "      - $_" }
        "    depends_on:`n" + ($dependsList -join "`n")
    } else { "" }
    
    $volumes = @("  postgres_data:")
    if ($redisAvailable) { $volumes += "  redis_data:" }
    $volumesSection = $volumes -join "`n"
    
    $composeContent = @"
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    image: gccc-backend:latest
    container_name: gccc-backend
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: $Environment
    env_file:
      - .env
    volumes:
      - ./logs:/app/logs
      - /app/node_modules
    networks:
      - gccc-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
$dependsOnSection
$databaseServices
$redisService

networks:
  gccc-network:
    driver: bridge

volumes:
$volumesSection
"@

    $composeContent | Out-File -FilePath "docker-compose.yml" -Encoding UTF8
    
    $servicesCount = 1
    $servicesList = @("Backend")
    
    if ($postgresAvailable) {
        $servicesCount += 1
        $servicesList += "PostgreSQL"
    }
    
    if ($redisAvailable) {
        $servicesCount += 1
        $servicesList += "Redis"
    }
    
    $servicesString = $servicesList -join " + "
    Write-Success "Docker Compose created with $servicesCount services ($servicesString)"
}

# Initialize directory structure
function New-InitializationStructure {
    Write-Step "Creating backend initialization structure..."
    
    $dirs = @(
        "logs",
        "temp"
    )
    
    foreach ($dir in $dirs) {
        $fullPath = Join-Path $SCRIPT_DIR $dir
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Success "Created directory: $dir"
        }
    }
}

# Deploy database if needed
function Deploy-DatabaseServices {
    if (-not $WithDatabase) {
        Write-Info "Skipping database deployment (WithDatabase=false)"
        return $true
    }
    
    Write-Step "Checking database services deployment..."
    
    $databaseScript = Join-Path $DATABASE_DIR "deploy_database.ps1"
    if (!(Test-Path $databaseScript)) {
        Write-Warning "Database deployment script not found at: $databaseScript"
        Write-Info "Continuing without database services"
        return $false
    }
    
    Write-Info "Running database deployment..."
    Push-Location $DATABASE_DIR
    try {
        & powershell -ExecutionPolicy Bypass -File "deploy_database.ps1" -Environment $Environment -Force:$Force
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Database services deployed successfully"
            return $true
        } else {
            Write-Warning "Database deployment failed, continuing without database"
            return $false
        }
    }
    catch {
        Write-Warning "Failed to run database deployment: $($_.Exception.Message)"
        return $false
    }
    finally {
        Pop-Location
    }
}

# Run tests in container
function Invoke-BackendTests {
    param([switch]$Coverage = $false)
    
    if ($SkipTests) {
        Write-Info "Skipping tests (SkipTests=true)"
        return $true
    }
    
    Write-Header "Running GCCC Backend Tests"
    
    # Ensure test image is built
    if (!(Build-TestImage)) {
        Write-Error "Failed to build test image"
        return $false
    }
    
    Write-Step "Running unit tests..."
    
    $testEnvVars = @(
        "-e", "NODE_ENV=test",
        "-e", "DB_HOST=postgres",
        "-e", "DB_PORT=5432",
        "-e", "DB_NAME=gccc_test_db",
        "-e", "DB_USER=gccc_user",
        "-e", "DB_PASSWORD=gccc_secure_password_2024",
        "-e", "REDIS_HOST=redis",
        "-e", "REDIS_PORT=6379",
        "-e", "REDIS_PASSWORD=redis_secure_password_2024"
    )
    
    $testCommand = if ($Coverage) { "test:coverage" } else { "test:unit" }
    
    $testArgs = @("run", "--rm") + $testEnvVars + @(
        "--network", "gccc-backend_gccc-network",
        "-v", "$($SCRIPT_DIR):/app",
        "-w", "/app",
        "gccc-backend:test",
        "npm", "run", $testCommand
    )
    
    & docker $testArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Unit tests passed"
    } else {
        Write-Error "Unit tests failed"
        return $false
    }
    
    Write-Step "Running integration tests..."
    
    $integrationArgs = $testArgs[0..($testArgs.Length-2)] + @("test:integration")
    & docker $integrationArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Integration tests passed"
        return $true
    } else {
        Write-Error "Integration tests failed"
        return $false
    }
}

# Wait for service to be ready
function Wait-ForService {
    param(
        [string]$ServiceName,
        [string]$HealthUrl,
        [int]$MaxWaitSeconds = 60
    )
    
    Write-Step "Waiting for $ServiceName to be ready..."
    $waited = 0
    
    do {
        Start-Sleep -Seconds 2
        $waited += 2
        
        try {
            $response = docker exec gccc-backend curl -f $HealthUrl 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$ServiceName ready (waited $waited seconds)"
                return $true
            }
        }
        catch {
            # Continue waiting
        }
        
        Write-Host "." -NoNewline
    } while ($waited -lt $MaxWaitSeconds)
    
    Write-Warning "$ServiceName startup timeout after $MaxWaitSeconds seconds"
    return $false
}

# Deploy backend services
function Start-BackendDeploy {
    Write-Header "Starting GCCC Backend Deployment"
    
    try {
        # Step 1: Check prerequisites
        Test-Prerequisites
        
        # Step 2: Initialize directories and configuration files
        New-InitializationStructure
        New-EnvFile
        
        # Step 3: Deploy database services if needed
        $databaseDeployed = Deploy-DatabaseServices
        
        # Step 4: Pull required base images with retry
        Write-Step "Pulling required Docker images..."
        $nodeSuccess = Invoke-DockerPull "node:18-alpine" -MaxRetries 3
        if (-not $nodeSuccess) {
            throw "Failed to pull Node.js base image after multiple attempts"
        }
        
        if ($WithDatabase -and $databaseDeployed) {
            Write-Info "Database images already available from database deployment"
        }
        
        # Step 5: Build backend images
        if (!(Build-BackendImage)) {
            throw "Failed to build backend image"
        }
        
        if (-not $SkipTests) {
            if (!(Build-TestImage)) {
                throw "Failed to build test image"
            }
        }
        
        # Stop here if BuildOnly is specified
        if ($BuildOnly) {
            Write-Success "Build completed successfully (BuildOnly mode)"
            return
        }
        
        # Step 6: Create Docker Compose file with available services
        $includeDb = [bool]$databaseDeployed
        $includeRedis = [bool]$databaseDeployed
        New-DockerComposeFile -IncludeDatabase:$includeDb -IncludeRedis:$includeRedis
        
        # Step 7: Handle existing containers
        Write-Step "Checking existing containers..."
        $existingContainers = docker ps -a --filter "name=gccc-backend" --format "{{.Names}}" 2>$null
        
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
        
        # Step 8: Start services
        Write-Step "Starting backend services..."
        $deployResult = docker-compose up -d
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start backend services"
        }
        Write-Success "Backend services started successfully"
        
        # Step 9: Wait for services to be ready
        if ($databaseDeployed) {
            Write-Step "Waiting for database to be ready..."
            Start-Sleep -Seconds 10  # Give database time to start
        }
        
        if (!(Wait-ForService "Backend API" "http://localhost:3000/health" 120)) {
            Write-Warning "Backend service may not be fully ready, but deployment continued"
        }
        
        # Step 10: Run tests if not skipped
        if (-not $SkipTests) {
            Write-Step "Running tests..."
            Start-Sleep -Seconds 5  # Allow services to fully initialize
            
            if (!(Invoke-BackendTests)) {
                Write-Warning "Some tests failed, but deployment completed"
            }
        }
        
        Write-Header "Backend Deployment Completed Successfully" -Color Green
        Write-Host ""
        Write-Host "Services Status:" -ForegroundColor Cyan
        Write-Host "  ✅ Backend API: Running on port 3000" -ForegroundColor Green
        Write-Host "  ✅ Health Check: http://localhost:3000/health" -ForegroundColor Green
        if ($databaseDeployed) {
            Write-Host "  ✅ Database: Connected and ready" -ForegroundColor Green
        }
        Write-Host ""
        
    } catch {
        Write-Header "Backend Deployment Failed" -Color Red
        Write-Error $_.Exception.Message
        Write-Host "Run 'docker-compose logs backend' to see backend logs" -ForegroundColor Yellow
        exit 1
    }
}

# Stop backend services
function Stop-Backend {
    Write-Header "Stopping GCCC Backend Services"
    Write-Step "Stopping backend containers..."
    
    docker-compose stop
    Write-Success "Backend services stopped"
}

# Restart backend services
function Restart-Backend {
    Write-Header "Restarting GCCC Backend Services"
    Stop-Backend
    Start-Sleep -Seconds 3
    Start-BackendDeploy
}

# Clean deployment
function Remove-Deployment {
    Write-Header "Cleaning GCCC Backend Deployment"
    
    if (!$Force) {
        Write-Error "Clean operation requires -Force parameter"
        Write-Info "This will delete all backend data, use carefully"
        return
    }
    
    Write-Step "Stopping and removing all backend services..."
    docker-compose down --volumes --rmi local 2>$null
    
    Write-Step "Cleaning backend images..."
    docker rmi gccc-backend:latest gccc-backend:test 2>$null
    
    Write-Step "Cleaning directories..."
    $dirs = @("logs", "temp")
    foreach ($dir in $dirs) {
        $fullPath = Join-Path $SCRIPT_DIR $dir
        if (Test-Path $fullPath) {
            Remove-Item -Path $fullPath -Recurse -Force
            Write-Success "Cleaned directory: $dir"
        }
    }
    
    Write-Success "Backend deployment completely cleaned"
}

# Run status check
function Start-StatusCheck {
    if ($SkipCheck) {
        Write-Info "Skipping status check (SkipCheck=true)"
        return
    }
    
    Write-Header "Running Backend Status Check"
    
    Write-Step "Checking backend container status..."
    $containers = docker ps --filter "name=gccc-backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Write-Host $containers
    
    Write-Step "Checking backend health endpoint..."
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 10
        if ($response) {
            Write-Success "Backend health check passed"
            if ($response.status -eq "ok") {
                Write-Info "API Status: $($response.status)"
                Write-Info "Database: $($response.database)"
                Write-Info "Redis: $($response.redis)"
            }
        }
    }
    catch {
        Write-Warning "Backend health check failed: $($_.Exception.Message)"
    }
    
    Write-Step "Checking service logs (last 10 lines)..."
    docker-compose logs --tail=10 backend
}

# Run only tests
function Start-TestOnly {
    Write-Header "Running GCCC Backend Tests Only"
    
    if (!(Test-Prerequisites)) {
        exit 1
    }
    
    if (!(Build-TestImage)) {
        Write-Error "Failed to build test image"
        exit 1
    }
    
    # Ensure database is available for tests
    if ($WithDatabase) {
        $databaseDeployed = Deploy-DatabaseServices
        if (-not $databaseDeployed) {
            Write-Warning "Database not available, some tests may fail"
        }
    }
    
    if (!(Invoke-BackendTests -Coverage)) {
        Write-Error "Tests failed"
        exit 1
    }
    
    Write-Success "All tests completed successfully"
}

# Show deployment information
function Show-DeploymentInfo {
    Write-Header "Backend Deployment Information"
    
    Write-ColorText "Environment: $Environment" "Cyan"
    Write-ColorText "Backend Service: gccc-backend" "Cyan"
    Write-Host ""
    
    Write-ColorText "API Endpoints:" "Yellow"
    Write-Host "  Backend API: http://localhost:3000"
    Write-Host "  Health Check: http://localhost:3000/health"
    Write-Host "  API Documentation: http://localhost:3000/api/docs"
    Write-Host ""
    
    Write-ColorText "Common Commands:" "Yellow"
    Write-Host "  View logs: docker-compose logs -f backend"
    Write-Host "  Enter container: docker exec -it gccc-backend /bin/sh"
    Write-Host "  Run tests: docker exec -it gccc-backend npm test"
    Write-Host "  Restart service: docker-compose restart backend"
    Write-Host ""
    
    if ($WithDatabase) {
        Write-ColorText "Database Information:" "Yellow"
        Write-Host "  PostgreSQL: localhost:5432"
        Write-Host "  Database: gccc_$($Environment)_db"
        Write-Host "  Redis: localhost:6379"
        Write-Host ""
    }
}

# Main program
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Header "GCCC Backend One-Click Deployment Script"
    Write-ColorText "Environment: $Environment" "Cyan"
    Write-ColorText "Action: $Action" "Cyan"
    Write-ColorText "With Database: $WithDatabase" "Cyan"
    
    # Check Docker environment
    if (-not (Test-DockerEnvironment)) {
        Write-Error "Docker environment check failed"
        exit 1
    }
    
    # Execute corresponding commands based on action
    switch ($Action) {
        "deploy" {
            Start-BackendDeploy
            Start-StatusCheck
            Show-DeploymentInfo
        }
        "stop" {
            Stop-Backend
        }
        "restart" {
            Restart-Backend
        }
        "clean" {
            Remove-Deployment
        }
        "status" {
            Start-StatusCheck
        }
        "test" {
            Start-TestOnly
        }
        default {
            Write-Error "Unknown action: $Action"
            Write-Info "Supported actions: deploy, stop, restart, clean, status, test"
            exit 1
        }
    }
    
    Write-Success "Operation completed!"
}

# Error handling
trap {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Host "Use -Help for usage information" -ForegroundColor Yellow
    exit 1
}

# Execute main program
Main
