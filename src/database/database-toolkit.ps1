# ================================================================
# GCCC Database Management Toolkit
# Complete solution for database deployment, monitoring and maintenance
# ================================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("deploy", "stop", "restart", "clean", "status", "logs", "backup", "restore", "shell")]
    [string]$Action,
    
    [string]$Environment = "development",
    [string]$BackupName,
    [string]$RestoreFrom,
    [int]$Timeout = 120,
    [switch]$Follow,
    [switch]$Force,
    [switch]$Verbose
)

# Script variables
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $SCRIPT_DIR ".env.$Environment"

# Initialize logging
$LOG_FILE = Join-Path $SCRIPT_DIR "logs\database-management.log"
$LOG_DIR = Split-Path $LOG_FILE -Parent
if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}

# Color output and logging functions
function Write-LogOutput {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console output with color
    $colors = @{
        "Red" = "Red"; "Green" = "Green"; "Yellow" = "Yellow"
        "Blue" = "Blue"; "Cyan" = "Cyan"; "Magenta" = "Magenta"
        "White" = "White"
    }
    Write-Host $logEntry -ForegroundColor $colors[$Color]
    
    # File logging
    Add-Content -Path $LOG_FILE -Value $logEntry
}

# Get project name from environment
function Get-ProjectName {
    if (Test-Path $ENV_FILE) {
        $envContent = Get-Content $ENV_FILE -Raw
        $projectNameMatch = $envContent | Select-String "COMPOSE_PROJECT_NAME=(.+)" 
        if ($projectNameMatch) {
            return $projectNameMatch.Matches[0].Groups[1].Value.Trim()
        }
    }
    return "gccc-$Environment"
}

# Check service health
function Test-ServiceHealth {
    param([string]$Service, [string]$ProjectName)
    
    try {
        switch ($Service) {
            "postgres" {
                $health = docker exec "${ProjectName}-postgres" pg_isready -U gccc_user 2>$null
                return ($LASTEXITCODE -eq 0)
            }
            "redis" {
                $health = docker exec "${ProjectName}-redis" redis-cli ping 2>$null
                return ($health -eq "PONG")
            }
            default {
                return $false
            }
        }
    } catch {
        return $false
    }
}

# Deploy action
function Invoke-Deploy {
    Write-LogOutput "Starting database deployment..." "INFO" "Blue"
    
    # Validate environment file
    if (-not (Test-Path $ENV_FILE)) {
        if (Test-Path ".env") {
            $script:ENV_FILE = ".env"
            Write-LogOutput "Using default .env file" "WARN" "Yellow"
        } else {
            Write-LogOutput "Environment file not found: $ENV_FILE" "ERROR" "Red"
            exit 1
        }
    }
    
    Write-LogOutput "Using environment file: $ENV_FILE" "INFO" "Green"
    
    # Create necessary directories
    Write-LogOutput "Creating data directories..." "INFO" "Blue"
    @("data", "data/postgres", "data/redis", "init", "backups", "logs") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-LogOutput "Created directory: $_" "INFO" "Green"
        }
    }
    
    # Pull latest images
    Write-LogOutput "Pulling latest Docker images..." "INFO" "Blue"
    docker-compose --env-file $ENV_FILE pull
    
    # Start services
    Write-LogOutput "Starting database services..." "INFO" "Blue"
    docker-compose --env-file $ENV_FILE up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-LogOutput "Database services started successfully!" "INFO" "Green"
        
        # Wait for services to be ready
        $projectName = Get-ProjectName
        $maxWait = 120
        $waited = 0
        
        Write-LogOutput "Waiting for services to be ready..." "INFO" "Blue"
        
        while ($waited -lt $maxWait) {
            $pgReady = Test-ServiceHealth "postgres" $projectName
            $redisReady = Test-ServiceHealth "redis" $projectName
            
            if ($pgReady -and $redisReady) {
                Write-LogOutput "All services are ready!" "INFO" "Green"
                break
            }
            
            Start-Sleep -Seconds 5
            $waited += 5
            Write-LogOutput "Waiting... ($waited/$maxWait seconds)" "INFO" "Yellow"
        }
        
        if ($waited -ge $maxWait) {
            Write-LogOutput "Services startup timeout, but containers are running" "WARN" "Yellow"
        }
        
        # Show deployment summary
        Write-LogOutput "=== Deployment Summary ===" "INFO" "Blue"
        docker-compose --env-file $ENV_FILE ps
        
    } else {
        Write-LogOutput "Failed to start database services" "ERROR" "Red"
        docker-compose --env-file $ENV_FILE logs
        exit 1
    }
}

# Stop action
function Invoke-Stop {
    Write-LogOutput "Stopping database services..." "INFO" "Yellow"
    docker-compose --env-file $ENV_FILE stop
    
    if ($LASTEXITCODE -eq 0) {
        Write-LogOutput "Database services stopped successfully" "INFO" "Green"
    } else {
        Write-LogOutput "Failed to stop some services" "WARN" "Yellow"
    }
}

# Restart action
function Invoke-Restart {
    Write-LogOutput "Restarting database services..." "INFO" "Blue"
    Invoke-Stop
    Start-Sleep -Seconds 3
    Invoke-Deploy
}

# Clean action
function Invoke-Clean {
    if (-not $Force) {
        $confirmation = Read-Host "This will remove all containers, networks, and volumes. Continue? (y/N)"
        if ($confirmation -ne "y" -and $confirmation -ne "Y") {
            Write-LogOutput "Clean operation cancelled" "INFO" "Yellow"
            return
        }
    }
    
    Write-LogOutput "Cleaning up database environment..." "INFO" "Red"
    
    # Stop and remove everything
    docker-compose --env-file $ENV_FILE down --volumes --remove-orphans --timeout 30
    
    # Remove dangling images
    $danglingImages = docker images -q -f dangling=true
    if ($danglingImages) {
        Write-LogOutput "Removing dangling images..." "INFO" "Yellow"
        docker rmi $danglingImages 2>$null
    }
    
    Write-LogOutput "Cleanup completed" "INFO" "Green"
}

# Status action
function Invoke-Status {
    Write-LogOutput "=== Database Services Status ===" "INFO" "Blue"
    
    $projectName = Get-ProjectName
    Write-LogOutput "Project: $projectName" "INFO" "Cyan"
    
    # Container status
    Write-LogOutput "`nContainer Status:" "INFO" "Cyan"
    docker-compose --env-file $ENV_FILE ps
    
    # Health checks
    Write-LogOutput "`nService Health:" "INFO" "Cyan"
    $pgHealth = if (Test-ServiceHealth "postgres" $projectName) { "✓ Healthy" } else { "✗ Unhealthy" }
    $redisHealth = if (Test-ServiceHealth "redis" $projectName) { "✓ Healthy" } else { "✗ Unhealthy" }
    
    Write-LogOutput "  PostgreSQL: $pgHealth" "INFO" $(if ($pgHealth -like "*Healthy*") { "Green" } else { "Red" })
    Write-LogOutput "  Redis: $redisHealth" "INFO" $(if ($redisHealth -like "*Healthy*") { "Green" } else { "Red" })
    
    # Resource usage
    Write-LogOutput "`nResource Usage:" "INFO" "Cyan"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    # Connection info
    Write-LogOutput "`nConnection Information:" "INFO" "Cyan"
    Write-LogOutput "  PostgreSQL: localhost:5432 (User: gccc_user, DB: gccc_db)" "INFO" "White"
    Write-LogOutput "  Redis: localhost:6379" "INFO" "White"
}

# Logs action
function Invoke-Logs {
    Write-LogOutput "Displaying database service logs..." "INFO" "Blue"
    
    $logArgs = @("--env-file", $ENV_FILE, "logs")
    
    if ($Follow) {
        $logArgs += "--follow"
    }
    
    if ($Verbose) {
        $logArgs += "--timestamps"
    }
    
    & docker-compose $logArgs
}

# Backup action
function Invoke-Backup {
    $projectName = Get-ProjectName
    $backupName = if ($BackupName) { $BackupName } else { "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" }
    $backupDir = Join-Path $SCRIPT_DIR "backups"
    $backupFile = Join-Path $backupDir "$backupName.sql"
    
    Write-LogOutput "Creating database backup: $backupName" "INFO" "Blue"
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    # Create PostgreSQL backup
    try {
        docker exec "${projectName}-postgres" pg_dump -U gccc_user gccc_db > $backupFile
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $backupFile)) {
            $backupSize = (Get-Item $backupFile).Length
            Write-LogOutput "Backup completed successfully: $backupFile ($backupSize bytes)" "INFO" "Green"
        } else {
            Write-LogOutput "Backup failed" "ERROR" "Red"
        }
    } catch {
        Write-LogOutput "Backup error: $($_.Exception.Message)" "ERROR" "Red"
    }
}

# Restore action
function Invoke-Restore {
    if (-not $RestoreFrom) {
        Write-LogOutput "Please specify backup file with -RestoreFrom parameter" "ERROR" "Red"
        return
    }
    
    $projectName = Get-ProjectName
    $backupPath = Join-Path $SCRIPT_DIR "backups\$RestoreFrom"
    
    if (-not (Test-Path $backupPath)) {
        $backupPath = $RestoreFrom  # Try as absolute path
        if (-not (Test-Path $backupPath)) {
            Write-LogOutput "Backup file not found: $RestoreFrom" "ERROR" "Red"
            return
        }
    }
    
    Write-LogOutput "Restoring database from: $backupPath" "INFO" "Blue"
    
    try {
        # Copy backup file to container and restore
        docker cp $backupPath "${projectName}-postgres:/tmp/restore.sql"
        docker exec "${projectName}-postgres" psql -U gccc_user -d gccc_db -f /tmp/restore.sql
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogOutput "Database restored successfully" "INFO" "Green"
        } else {
            Write-LogOutput "Database restore failed" "ERROR" "Red"
        }
    } catch {
        Write-LogOutput "Restore error: $($_.Exception.Message)" "ERROR" "Red"
    }
}

# Shell action
function Invoke-Shell {
    $projectName = Get-ProjectName
    
    Write-LogOutput "Available database shells:" "INFO" "Cyan"
    Write-LogOutput "1. PostgreSQL (psql)" "INFO" "White"
    Write-LogOutput "2. Redis (redis-cli)" "INFO" "White"
    
    $choice = Read-Host "Select shell (1-2)"
    
    switch ($choice) {
        "1" {
            Write-LogOutput "Connecting to PostgreSQL..." "INFO" "Green"
            docker exec -it "${projectName}-postgres" psql -U gccc_user -d gccc_db
        }
        "2" {
            Write-LogOutput "Connecting to Redis..." "INFO" "Green"
            docker exec -it "${projectName}-redis" redis-cli
        }
        default {
            Write-LogOutput "Invalid choice" "ERROR" "Red"
        }
    }
}

# Main execution
Write-LogOutput "GCCC Database Management Toolkit - Action: $Action" "INFO" "Blue"

# Validate environment file for most actions
if ($Action -ne "clean" -and -not (Test-Path $ENV_FILE) -and -not (Test-Path ".env")) {
    Write-LogOutput "Environment file not found: $ENV_FILE" "ERROR" "Red"
    exit 1
}

# Execute action
switch ($Action) {
    "deploy"  { Invoke-Deploy }
    "stop"    { Invoke-Stop }
    "restart" { Invoke-Restart }
    "clean"   { Invoke-Clean }
    "status"  { Invoke-Status }
    "logs"    { Invoke-Logs }
    "backup"  { Invoke-Backup }
    "restore" { Invoke-Restore }
    "shell"   { Invoke-Shell }
    default   { 
        Write-LogOutput "Unknown action: $Action" "ERROR" "Red"
        exit 1
    }
}

Write-LogOutput "Action '$Action' completed" "INFO" "Green"
