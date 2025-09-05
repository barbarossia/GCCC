# ================================================================
# GCCC Database Status Check Script (PowerShell Version)
# Check PostgreSQL and Redis database health status
# ================================================================

param(
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432", 
    [string]$DbName = "gccc_development_db",
    [string]$DbUser = "gccc_user",
    [string]$DbPassword = "gccc_secure_password_2024",
    [string]$RedisHost = "localhost",
    [string]$RedisPort = "6379",
    [string]$RedisPassword = "redis_secure_password_2024",
    [switch]$Verbose = $false,
    [switch]$Help = $false
)

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
GCCC Database Status Check Script

Usage: .\check_status.ps1 [Options]

Options:
  -DbHost HOST               Database host (default: localhost)
  -DbPort PORT               Database port (default: 5432)
  -DbName DATABASE           Database name (default: gccc_development_db)
  -DbUser USER               Database user (default: gccc_user)
  -DbPassword PASSWORD       Database password
  -RedisHost HOST            Redis host (default: localhost)
  -RedisPort PORT            Redis port (default: 6379)
  -RedisPassword PASSWORD    Redis password
  -Verbose                   Verbose output
  -Help                      Show help information

Examples:
  .\check_status.ps1                                    # Check with defaults
  .\check_status.ps1 -DbHost localhost -DbPort 5432    # Specify parameters
  .\check_status.ps1 -Verbose                          # Verbose mode

"@
}

# Check PostgreSQL connection
function Test-PostgreSQLConnection {
    Write-Step "Checking PostgreSQL connection..."
    
    $connectionString = "Host=$DbHost;Port=$DbPort;Database=$DbName;Username=$DbUser"
    if ($DbPassword) {
        $connectionString += ";Password=$DbPassword"
    }
    
    # Try direct psql connection first
    if (Get-Command "psql" -ErrorAction SilentlyContinue) {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c "SELECT 1;" 2>$null
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PostgreSQL connection OK"
            return $true
        }
    }
    
    # Try Docker container connection
    $containers = docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" 2>$null
    if ($containers) {
        $container = $containers | Select-Object -First 1
        $result = docker exec $container psql -U $DbUser -d $DbName -c "SELECT 1;" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "PostgreSQL connection OK (via Docker)"
            return $true
        }
    }
    
    Write-Error "PostgreSQL connection failed"
    return $false
}

# Check database information
function Get-DatabaseInfo {
    Write-Step "Getting database information..."
    
    $sql = "SELECT current_database() as database_name, current_user as current_user, version() as version;"
    
    if (Get-Command "psql" -ErrorAction SilentlyContinue) {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c $sql 2>$null
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            Write-Success "Database information retrieved"
            if ($Verbose) {
                Write-Host $result
            }
            return $true
        }
    }
    
    Write-Error "Failed to get database information"
    return $false
}

# Check table count
function Test-TableCount {
    Write-Step "Checking table count..."
    
    $sql = @"
SELECT COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
"@
    
    $tableCount = 0
    
    if (Get-Command "psql" -ErrorAction SilentlyContinue) {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c $sql 2>$null
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $tableCount = [int]($result.Trim())
        }
    } else {
        # Try Docker
        $containers = docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" 2>$null
        if ($containers) {
            $container = $containers | Select-Object -First 1
            $result = docker exec $container psql -U $DbUser -d $DbName -t -c $sql 2>$null
            if ($LASTEXITCODE -eq 0 -and $result) {
                $tableCount = [int]($result.Trim())
            }
        }
    }
    
    if ($tableCount -ge 20) {
        Write-Success "Table count check passed: $tableCount tables"
    } elseif ($tableCount -gt 0) {
        Write-Warning "Table count low: $tableCount tables (recommended: 20+)"
    } else {
        Write-Error "No tables found"
        return $false
    }
    
    return $true
}

# Check function count
function Test-FunctionCount {
    Write-Step "Checking function count..."
    
    $sql = @"
SELECT COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
"@
    
    $functionCount = 0
    
    if (Get-Command "psql" -ErrorAction SilentlyContinue) {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c $sql 2>$null
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $functionCount = [int]($result.Trim())
        }
    } else {
        # Try Docker
        $containers = docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" 2>$null
        if ($containers) {
            $container = $containers | Select-Object -First 1
            $result = docker exec $container psql -U $DbUser -d $DbName -t -c $sql 2>$null
            if ($LASTEXITCODE -eq 0 -and $result) {
                $functionCount = [int]($result.Trim())
            }
        }
    }
    
    if ($functionCount -ge 10) {
        Write-Success "Function count check passed: $functionCount functions"
    } elseif ($functionCount -gt 0) {
        Write-Warning "Function count low: $functionCount functions (recommended: 10+)"
    } else {
        Write-Error "No functions found"
        return $false
    }
    
    return $true
}

# Check extensions
function Test-Extensions {
    Write-Step "Checking database extensions..."
    
    $sql = @"
SELECT extname 
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin', 'pg_trgm')
ORDER BY extname;
"@
    
    $extensions = @()
    
    if (Get-Command "psql" -ErrorAction SilentlyContinue) {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c $sql 2>$null
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $extensions = $result -split "`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
        }
    } else {
        # Try Docker
        $containers = docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" 2>$null
        if ($containers) {
            $container = $containers | Select-Object -First 1
            $result = docker exec $container psql -U $DbUser -d $DbName -t -c $sql 2>$null
            if ($LASTEXITCODE -eq 0 -and $result) {
                $extensions = $result -split "`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
            }
        }
    }
    
    $extensionCount = $extensions.Count
    
    if ($extensionCount -ge 4) {
        Write-Success "Extension check passed: $extensionCount extensions installed"
    } elseif ($extensionCount -gt 0) {
        Write-Warning "Partial extensions installed: $extensionCount/4"
    } else {
        Write-Error "Required extensions not installed"
        return $false
    }
    
    if ($Verbose -and $extensions.Count -gt 0) {
        Write-Host "Installed extensions:"
        foreach ($ext in $extensions) {
            Write-Host "  $ext"
        }
    }
    
    return $true
}

# Check migration status
function Test-Migrations {
    Write-Step "Checking migration status..."
    
    $sql = @"
SELECT 
    COUNT(*) as migration_count,
    COUNT(CASE WHEN success THEN 1 END) as successful_count
FROM schema_migrations;
"@
    
    if (Get-Command "psql" -ErrorAction SilentlyContinue) {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c $sql 2>$null
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0 -and $result -and $result -notmatch "does not exist") {
            $parts = $result.Trim() -split '\s+' | Where-Object { $_ -ne "" }
            if ($parts.Count -ge 2) {
                $migrationCount = [int]$parts[0]
                $successfulCount = [int]$parts[1]
                
                if ($migrationCount -eq $successfulCount -and $migrationCount -gt 0) {
                    Write-Success "Migration status OK: $successfulCount/$migrationCount successful"
                } else {
                    Write-Warning "Migration status abnormal: $successfulCount/$migrationCount successful"
                }
            }
        } else {
            Write-Warning "Migration table does not exist or not accessible"
        }
    }
}

# Check Redis connection
function Test-RedisConnection {
    Write-Step "Checking Redis connection..."
    
    if (Get-Command "redis-cli" -ErrorAction SilentlyContinue) {
        $authArgs = @()
        if ($RedisPassword) {
            $authArgs = @("-a", $RedisPassword)
        }
        
        $result = redis-cli -h $RedisHost -p $RedisPort @authArgs ping 2>$null
        if ($LASTEXITCODE -eq 0 -and $result -eq "PONG") {
            Write-Success "Redis connection OK"
            return $true
        }
    }
    
    # Try Docker connection
    $containers = docker ps --filter "name=gccc-*-redis" --format "{{.Names}}" 2>$null
    if ($containers) {
        $container = $containers | Select-Object -First 1
        $result = docker exec $container redis-cli ping 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result -eq "PONG") {
            Write-Success "Redis connection OK (via Docker)"
            return $true
        }
    }
    
    Write-Warning "Redis client not found or Docker container unavailable"
    return $false
}

# Run health check function
function Invoke-HealthCheck {
    Write-Step "Running database health check function..."
    
    $sql = "SELECT * FROM database_health_check();"
    
    if (Get-Command "psql" -ErrorAction SilentlyContinue) {
        $env:PGPASSWORD = $DbPassword
        $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c $sql 2>$null
        $env:PGPASSWORD = $null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            Write-Success "Health check function executed successfully"
            if ($Verbose) {
                Write-Host $result
            }
        } else {
            Write-Warning "Health check function failed or does not exist"
        }
    } else {
        # Try Docker
        $containers = docker ps --filter "name=gccc-*-postgres" --format "{{.Names}}" 2>$null
        if ($containers) {
            $container = $containers | Select-Object -First 1
            $result = docker exec $container psql -U $DbUser -d $DbName -c $sql 2>$null
            
            if ($LASTEXITCODE -eq 0 -and $result) {
                Write-Success "Health check function executed successfully (via Docker)"
                if ($Verbose) {
                    Write-Host $result
                }
            } else {
                Write-Warning "Health check function failed or does not exist"
            }
        }
    }
}

# Generate status report
function Show-StatusReport {
    Write-Header "Database Status Report"
    
    Write-ColorText "Check Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
    Write-ColorText "PostgreSQL: $DbHost`:$DbPort" "Cyan"
    Write-ColorText "Database: $DbName" "Cyan"
    Write-ColorText "Redis: $RedisHost`:$RedisPort" "Cyan"
    Write-Host ""
}

# Main program
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Header "GCCC Database Status Check"
    
    Show-StatusReport
    
    $exitCode = 0
    
    # PostgreSQL checks
    if (!(Test-PostgreSQLConnection)) { $exitCode = 1 }
    if (!(Get-DatabaseInfo)) { $exitCode = 1 }
    if (!(Test-TableCount)) { $exitCode = 1 }
    if (!(Test-FunctionCount)) { $exitCode = 1 }
    if (!(Test-Extensions)) { $exitCode = 1 }
    
    Test-Migrations  # Don't affect exit status
    
    # Redis check
    if (!(Test-RedisConnection)) { $exitCode = 1 }
    
    # Health check
    Invoke-HealthCheck
    
    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Success "All database status checks passed!"
    } else {
        Write-Error "Database status check found issues, exit code: $exitCode"
    }
    
    exit $exitCode
}

# Error handling
trap {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

# Execute main program
Main
