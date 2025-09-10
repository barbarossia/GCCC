# ================================================================
# GCCC Backend Health Check Script
# Verify backend services status and connectivity
# ================================================================

param(
    [string]$BackendUrl = "http://localhost:3000",
    [string]$Environment = "development",
    [switch]$Detailed = $false,
    [switch]$Quiet = $false
)

# Color output functions
function Write-ColorText {
    param([string]$Text, [string]$Color)
    if ($Quiet) { return }
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
    param([string]$Message, [string]$Color = "Cyan") 
    if ($Quiet) { return }
    Write-Host ""
    Write-ColorText "===================================" $Color
    Write-ColorText $Message $Color
    Write-ColorText "===================================" $Color
    Write-Host ""
}

# Check container status
function Test-ContainerStatus {
    Write-Step "Checking container status..."
    
    $containers = docker ps --filter "name=gccc-backend" --format "{{.Names}}\t{{.Status}}"
    if (-not $containers) {
        Write-Warning "No GCCC backend containers found"
        return $false
    }
    
    $runningContainers = $containers | Where-Object { $_ -match "Up" }
    if ($runningContainers) {
        Write-Success "Backend containers are running"
        if ($Detailed) {
            Write-Host "Container Details:"
            docker ps --filter "name=gccc-backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
        }
        return $true
    } else {
        Write-Error "Backend containers are not running properly"
        return $false
    }
}

# Check API health endpoint
function Test-ApiHealth {
    Write-Step "Checking API health endpoint..."
    
    try {
        $response = Invoke-RestMethod -Uri "$BackendUrl/health" -Method GET -TimeoutSec 10
        
        if ($response -and $response.status -eq "ok") {
            Write-Success "API health check passed"
            
            if ($Detailed) {
                Write-Host "Health Details:" -ForegroundColor Cyan
                Write-Host "  Status: $($response.status)" -ForegroundColor White
                Write-Host "  Timestamp: $($response.timestamp)" -ForegroundColor White
                Write-Host "  Uptime: $($response.uptime)" -ForegroundColor White
                Write-Host "  Version: $($response.version)" -ForegroundColor White
                Write-Host "  Environment: $($response.environment)" -ForegroundColor White
                
                if ($response.database) {
                    Write-Host "  Database: $($response.database.status)" -ForegroundColor $(
                        if ($response.database.status -eq "connected") { "Green" } else { "Red" }
                    )
                }
                
                if ($response.redis) {
                    Write-Host "  Redis: $($response.redis.status)" -ForegroundColor $(
                        if ($response.redis.status -eq "connected") { "Green" } else { "Red" }
                    )
                }
                
                if ($response.memory) {
                    $memUsagePercent = [math]::Round(($response.memory.used / $response.memory.total) * 100, 2)
                    Write-Host "  Memory Usage: $memUsagePercent% ($($response.memory.used)MB / $($response.memory.total)MB)" -ForegroundColor White
                }
            }
            
            return $true
        } else {
            Write-Error "API health check failed - invalid response"
            return $false
        }
    }
    catch {
        Write-Error "API health check failed: $($_.Exception.Message)"
        return $false
    }
}

# Check database connectivity
function Test-DatabaseConnectivity {
    Write-Step "Checking database connectivity..."
    
    try {
        $response = Invoke-RestMethod -Uri "$BackendUrl/api/v1/health/database" -Method GET -TimeoutSec 10
        
        if ($response -and $response.status -eq "ok") {
            Write-Success "Database connectivity check passed"
            
            if ($Detailed) {
                Write-Host "Database Details:" -ForegroundColor Cyan
                Write-Host "  Connection: $($response.connection)" -ForegroundColor White
                Write-Host "  Pool Size: $($response.pool.total)" -ForegroundColor White
                Write-Host "  Active Connections: $($response.pool.active)" -ForegroundColor White
                Write-Host "  Idle Connections: $($response.pool.idle)" -ForegroundColor White
                Write-Host "  Response Time: $($response.responseTime)ms" -ForegroundColor White
            }
            
            return $true
        } else {
            Write-Warning "Database connectivity check failed"
            return $false
        }
    }
    catch {
        Write-Warning "Database connectivity check failed: $($_.Exception.Message)"
        return $false
    }
}

# Check Redis connectivity
function Test-RedisConnectivity {
    Write-Step "Checking Redis connectivity..."
    
    try {
        $response = Invoke-RestMethod -Uri "$BackendUrl/api/v1/health/redis" -Method GET -TimeoutSec 10
        
        if ($response -and $response.status -eq "ok") {
            Write-Success "Redis connectivity check passed"
            
            if ($Detailed) {
                Write-Host "Redis Details:" -ForegroundColor Cyan
                Write-Host "  Connection: $($response.connection)" -ForegroundColor White
                Write-Host "  Memory Usage: $($response.memory.used)" -ForegroundColor White
                Write-Host "  Response Time: $($response.responseTime)ms" -ForegroundColor White
                Write-Host "  Keys Count: $($response.keys)" -ForegroundColor White
            }
            
            return $true
        } else {
            Write-Warning "Redis connectivity check failed"
            return $false
        }
    }
    catch {
        Write-Warning "Redis connectivity check failed: $($_.Exception.Message)"
        return $false
    }
}

# Check API endpoints
function Test-ApiEndpoints {
    Write-Step "Checking critical API endpoints..."
    
    $endpoints = @(
        @{ Path = "/api/v1/auth/status"; Name = "Auth Status" },
        @{ Path = "/api/v1/users/me"; Name = "User Profile"; RequiresAuth = $true },
        @{ Path = "/api/v1/health/metrics"; Name = "Metrics" }
    )
    
    $passedCount = 0
    $totalCount = 0
    
    foreach ($endpoint in $endpoints) {
        $totalCount++
        
        if ($endpoint.RequiresAuth) {
            Write-Info "Skipping $($endpoint.Name) (requires authentication)"
            continue
        }
        
        try {
            $response = Invoke-RestMethod -Uri "$BackendUrl$($endpoint.Path)" -Method GET -TimeoutSec 5
            Write-Success "$($endpoint.Name) endpoint accessible"
            $passedCount++
        }
        catch {
            Write-Warning "$($endpoint.Name) endpoint failed: $($_.Exception.Message)"
        }
    }
    
    Write-Info "API Endpoints: $passedCount/$totalCount accessible"
    return $passedCount -gt 0
}

# Main health check function
function Start-HealthCheck {
    Write-Header "GCCC Backend Health Check"
    Write-Info "Target: $BackendUrl"
    Write-Info "Environment: $Environment"
    
    $checks = @()
    
    # Container status check
    $containerCheck = Test-ContainerStatus
    $checks += @{ Name = "Container Status"; Passed = $containerCheck }
    
    # API health check
    $apiCheck = Test-ApiHealth
    $checks += @{ Name = "API Health"; Passed = $apiCheck }
    
    # Database connectivity check
    if ($apiCheck) {
        $dbCheck = Test-DatabaseConnectivity
        $checks += @{ Name = "Database Connectivity"; Passed = $dbCheck }
        
        # Redis connectivity check
        $redisCheck = Test-RedisConnectivity
        $checks += @{ Name = "Redis Connectivity"; Passed = $redisCheck }
        
        # API endpoints check
        if ($Detailed) {
            $endpointsCheck = Test-ApiEndpoints
            $checks += @{ Name = "API Endpoints"; Passed = $endpointsCheck }
        }
    }
    
    # Summary
    Write-Header "Health Check Summary"
    
    $passedChecks = ($checks | Where-Object { $_.Passed }).Count
    $totalChecks = $checks.Count
    
    foreach ($check in $checks) {
        $status = if ($check.Passed) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($check.Passed) { "Green" } else { "Red" }
        Write-ColorText "  $status $($check.Name)" $color
    }
    
    Write-Host ""
    Write-ColorText "Overall Status: $passedChecks/$totalChecks checks passed" $(
        if ($passedChecks -eq $totalChecks) { "Green" } 
        elseif ($passedChecks -gt 0) { "Yellow" } 
        else { "Red" }
    )
    
    # Return exit code based on results
    if ($passedChecks -eq $totalChecks) {
        Write-Success "All health checks passed!"
        return 0
    } elseif ($passedChecks -gt 0) {
        Write-Warning "Some health checks failed"
        return 1
    } else {
        Write-Error "All health checks failed"
        return 2
    }
}

# Execute health check
$exitCode = Start-HealthCheck
exit $exitCode
