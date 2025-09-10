# ================================================================
# GCCC Backend Test Runner Script
# Run unit and integration tests in Docker containers
# ================================================================

param(
    [ValidateSet("unit", "integration", "all", "coverage")]
    [string]$TestType = "all",
    
    [ValidateSet("development", "test", "production")]
    [string]$Environment = "test",
    
    [switch]$Watch = $false,
    [switch]$Verbose = $false,
    [switch]$Coverage = $false,
    [switch]$CleanUp = $true,
    [switch]$KeepContainers = $false,
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
GCCC Backend Test Runner Script

Usage: .\run_tests.ps1 [Options]

Options:
  -TestType <TYPE>           Test type: unit, integration, all, coverage (default: all)
  -Environment <ENV>         Environment: development, test, production (default: test)
  -Watch                     Run tests in watch mode
  -Verbose                   Enable verbose test output
  -Coverage                  Generate test coverage report
  -CleanUp                   Clean up containers after tests (default: true)
  -KeepContainers           Keep test containers running after tests
  -Help                      Show help information

Examples:
  .\run_tests.ps1                                    # Run all tests
  .\run_tests.ps1 -TestType unit                     # Run unit tests only
  .\run_tests.ps1 -TestType integration -Verbose     # Run integration tests with verbose output
  .\run_tests.ps1 -Coverage                          # Run tests with coverage report
  .\run_tests.ps1 -Watch                            # Run tests in watch mode
  .\run_tests.ps1 -KeepContainers                   # Keep containers for debugging

"@
}

# Check prerequisites
function Test-Prerequisites {
    Write-Step "Testing prerequisites..."
    
    # Check if Docker is available
    if (!(Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not available in PATH"
        return $false
    }
    
    # Check if Docker Compose is available
    if (!(Get-Command "docker-compose" -ErrorAction SilentlyContinue)) {
        Write-Error "Docker Compose is not installed or not available in PATH"
        return $false
    }
    
    # Check if we're in the backend directory
    if (!(Test-Path "package.json")) {
        Write-Error "package.json not found. Please run from backend directory."
        return $false
    }
    
    # Check if test compose file exists
    if (!(Test-Path "docker-compose.test.yml")) {
        Write-Error "docker-compose.test.yml not found. Please ensure test configuration is available."
        return $false
    }
    
    Write-Success "All prerequisites met"
    return $true
}

# Setup test environment
function Initialize-TestEnvironment {
    Write-Step "Setting up test environment..."
    
    # Create test environment file
    $testEnvContent = @"
# GCCC Backend Test Configuration
NODE_ENV=test
PORT=3001

# Test Database Configuration
DB_HOST=test-postgres
DB_PORT=5432
DB_NAME=gccc_test_db
DB_USER=gccc_user
DB_PASSWORD=gccc_secure_password_2024
DB_SSL=false

# Test Redis Configuration
REDIS_HOST=test-redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_password_2024
REDIS_DB=1

# Test JWT Configuration
JWT_SECRET=test_jwt_secret_key_for_testing_purposes_only
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=test_refresh_token_secret_for_testing
JWT_REFRESH_EXPIRES_IN=1d

# Test Solana Configuration
SOLANA_RPC_URL=https://api.devnet.solana.com

# Test Timeouts
TEST_TIMEOUT=30000
JEST_TIMEOUT=30000

# Logging
LOG_LEVEL=error
"@

    $testEnvContent | Out-File -FilePath ".env.test" -Encoding UTF8
    Write-Success "Test environment configuration created"
}

# Build test images
function Build-TestImages {
    Write-Step "Building test images..."
    
    $buildArgs = @(
        "build",
        "-f", "Dockerfile",
        "--target", "dev-dependencies",
        "-t", "gccc-backend:test",
        "."
    )
    
    & docker $buildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Test images built successfully"
        return $true
    } else {
        Write-Error "Failed to build test images"
        return $false
    }
}

# Start test infrastructure
function Start-TestInfrastructure {
    Write-Step "Starting test infrastructure..."
    
    # Start test database and Redis
    $infraArgs = @(
        "-f", "docker-compose.test.yml",
        "up", "-d",
        "test-postgres",
        "test-redis"
    )
    
    & docker-compose $infraArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Test infrastructure started"
        
        # Wait for services to be healthy
        Write-Step "Waiting for test services to be ready..."
        $maxWait = 60
        $waited = 0
        
        do {
            Start-Sleep -Seconds 2
            $waited += 2
            
            $postgresHealth = docker inspect gccc-test-postgres --format='{{.State.Health.Status}}' 2>$null
            $redisHealth = docker inspect gccc-test-redis --format='{{.State.Health.Status}}' 2>$null
            
            if ($postgresHealth -eq "healthy" -and $redisHealth -eq "healthy") {
                Write-Success "Test services are ready (waited $waited seconds)"
                return $true
            }
            
            Write-Host "." -NoNewline
        } while ($waited -lt $maxWait)
        
        Write-Warning "Test services startup timeout, continuing anyway"
        return $true
    } else {
        Write-Error "Failed to start test infrastructure"
        return $false
    }
}

# Run specific test type
function Invoke-Tests {
    param([string]$Type, [switch]$WatchMode = $false)
    
    Write-Step "Running $Type tests..."
    
    # Determine the npm script to run
    $testScript = switch ($Type) {
        "unit" { "test:unit" }
        "integration" { "test:integration" }
        "coverage" { "test:coverage" }
        "all" { "test" }
        default { "test" }
    }
    
    if ($WatchMode) {
        $testScript = "test:watch"
    }
    
    # Build docker run command
    $runArgs = @(
        "run",
        "--rm",
        "--network", "gccc-backend-test_gccc-test-network",
        "-v", "${PWD}:/app",
        "-v", "/app/node_modules",
        "-w", "/app",
        "--env-file", ".env.test"
    )
    
    if ($Coverage -or $Type -eq "coverage") {
        $runArgs += @("-v", "gccc-backend-test_test_coverage:/app/coverage")
    }
    
    if ($Verbose) {
        $runArgs += @("-e", "VERBOSE=true")
    }
    
    $runArgs += @(
        "gccc-backend:test",
        "npm", "run", $testScript
    )
    
    if ($WatchMode) {
        Write-Info "Running in watch mode (press Ctrl+C to stop)"
    }
    
    & docker $runArgs
    
    $testExitCode = $LASTEXITCODE
    
    if ($testExitCode -eq 0) {
        Write-Success "$Type tests passed"
        return $true
    } else {
        Write-Error "$Type tests failed (exit code: $testExitCode)"
        return $false
    }
}

# Generate test reports
function New-TestReports {
    Write-Step "Generating test reports..."
    
    # Check if coverage data exists
    $coverageExists = docker run --rm -v "gccc-backend-test_test_coverage:/coverage" alpine test -d /coverage 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Info "Extracting coverage report..."
        
        # Copy coverage report to host
        if (!(Test-Path "coverage")) {
            New-Item -ItemType Directory -Path "coverage" -Force | Out-Null
        }
        
        docker run --rm -v "gccc-backend-test_test_coverage:/coverage" -v "${PWD}/coverage:/output" alpine cp -r /coverage/. /output/
        
        if (Test-Path "coverage/lcov-report/index.html") {
            Write-Success "Coverage report generated: coverage/lcov-report/index.html"
        }
    }
    
    # Generate test results summary
    $summaryPath = "test-results-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
    $summary = @"
GCCC Backend Test Results Summary
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Test Type: $TestType
Environment: $Environment
Coverage: $($Coverage -or $TestType -eq "coverage")

Test Infrastructure:
- PostgreSQL: gccc-test-postgres
- Redis: gccc-test-redis

Coverage Report: $(if (Test-Path "coverage/lcov-report/index.html") { "Available at coverage/lcov-report/index.html" } else { "Not generated" })
"@
    
    $summary | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Info "Test summary saved to: $summaryPath"
}

# Clean up test environment
function Remove-TestEnvironment {
    if (-not $CleanUp) {
        Write-Info "Skipping cleanup (CleanUp=false)"
        return
    }
    
    if ($KeepContainers) {
        Write-Info "Keeping containers for debugging (KeepContainers=true)"
        Write-Info "To clean up manually later, run: docker-compose -f docker-compose.test.yml down -v"
        return
    }
    
    Write-Step "Cleaning up test environment..."
    
    # Stop and remove test containers
    docker-compose -f docker-compose.test.yml down -v 2>$null
    
    # Remove test environment file
    if (Test-Path ".env.test") {
        Remove-Item ".env.test" -Force
    }
    
    Write-Success "Test environment cleaned up"
}

# Main test execution function
function Start-TestExecution {
    Write-Header "GCCC Backend Test Execution"
    Write-Info "Test Type: $TestType"
    Write-Info "Environment: $Environment"
    Write-Info "Watch Mode: $Watch"
    Write-Info "Coverage: $($Coverage -or $TestType -eq 'coverage')"
    
    $allTestsPassed = $true
    
    try {
        # Prerequisites check
        if (!(Test-Prerequisites)) {
            throw "Prerequisites check failed"
        }
        
        # Initialize test environment
        Initialize-TestEnvironment
        
        # Build test images
        if (!(Build-TestImages)) {
            throw "Failed to build test images"
        }
        
        # Start test infrastructure
        if (!(Start-TestInfrastructure)) {
            throw "Failed to start test infrastructure"
        }
        
        # Wait a bit for services to be fully ready
        Write-Info "Allowing services to fully initialize..."
        Start-Sleep -Seconds 5
        
        # Run tests based on type
        switch ($TestType) {
            "unit" {
                $allTestsPassed = Invoke-Tests -Type "unit" -WatchMode:$Watch
            }
            "integration" {
                $allTestsPassed = Invoke-Tests -Type "integration" -WatchMode:$Watch
            }
            "coverage" {
                $allTestsPassed = Invoke-Tests -Type "coverage"
            }
            "all" {
                Write-Info "Running all test suites..."
                $unitPassed = Invoke-Tests -Type "unit"
                $integrationPassed = Invoke-Tests -Type "integration"
                
                if ($Coverage) {
                    $coveragePassed = Invoke-Tests -Type "coverage"
                    $allTestsPassed = $unitPassed -and $integrationPassed -and $coveragePassed
                } else {
                    $allTestsPassed = $unitPassed -and $integrationPassed
                }
            }
        }
        
        # Generate reports
        if ($Coverage -or $TestType -eq "coverage") {
            New-TestReports
        }
        
        # Display results
        Write-Header "Test Execution Summary" -Color $(if ($allTestsPassed) { "Green" } else { "Red" })
        
        if ($allTestsPassed) {
            Write-Success "All tests completed successfully! ✅"
        } else {
            Write-Error "Some tests failed! ❌"
        }
        
    }
    catch {
        Write-Header "Test Execution Failed" -Color Red
        Write-Error $_.Exception.Message
        $allTestsPassed = $false
    }
    finally {
        # Clean up
        Remove-TestEnvironment
    }
    
    # Exit with appropriate code
    exit $(if ($allTestsPassed) { 0 } else { 1 })
}

# Main program
function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    # Handle coverage flag
    if ($Coverage) {
        $script:TestType = "coverage"
    }
    
    Start-TestExecution
}

# Error handling
trap {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    Remove-TestEnvironment
    exit 1
}

# Execute main program
Main
