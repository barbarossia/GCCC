# ========================================
# GCCC 数据库服务健康检查脚本（PowerShell优化版）
# 功能：网络连通性、服务可用性、性能检查
# ========================================

param(
    [string]$Service = "all",  # all, postgres, redis, network, resources
    [int]$Timeout = 10,
    [int]$Retries = 3,
    [switch]$Detailed,
    [switch]$Performance
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    switch ($Color) {
        "Red"    { Write-Host $Message -ForegroundColor Red }
        "Green"  { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue"   { Write-Host $Message -ForegroundColor Blue }
        "Cyan"   { Write-Host $Message -ForegroundColor Cyan }
        default  { Write-Host $Message }
    }
}

function Test-NetworkConnectivity {
    Write-ColorOutput "🌐 检查网络连通性..." "Blue"
    
    # 检查Docker网络
    $networks = docker network ls --format "{{.Name}}" | Where-Object { $_ -match "gccc" }
    if ($networks) {
        Write-ColorOutput "✅ Docker网络存在: $($networks -join ', ')" "Green"
    } else {
        Write-ColorOutput "❌ Docker网络不存在" "Red"
        return $false
    }
    
    # 检查运行的容器
    $containers = docker ps --format "{{.Names}}" | Where-Object { $_ -match "(postgres|redis)" }
    $containerCount = ($containers | Measure-Object).Count
    
    if ($containerCount -ge 2) {
        Write-ColorOutput "✅ 数据库容器运行中 ($containerCount/2)" "Green"
    } else {
        Write-ColorOutput "⚠️ 部分容器未运行 ($containerCount/2)" "Yellow"
    }
    
    return $true
}

function Test-PostgreSQL {
    Write-ColorOutput "🐘 检查 PostgreSQL..." "Blue"
    
    $containerName = "${env:COMPOSE_PROJECT_NAME}-postgres"
    if (-not $env:COMPOSE_PROJECT_NAME) {
        $containerName = "gccc-postgres"
    }
    
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        Write-ColorOutput "   尝试 $attempt/$Retries" "Cyan"
        
        try {
            # 基础连接检查
            $result = docker exec $containerName pg_isready -U $env:POSTGRES_USER -d $env:POSTGRES_DB 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ PostgreSQL 连接正常" "Green"
                
                if ($Detailed) {
                    # 获取版本信息
                    $version = docker exec $containerName psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -tAc "SELECT version();" 2>$null
                    if ($version) {
                        $shortVersion = $version.Substring(0, [Math]::Min(50, $version.Length))
                        Write-ColorOutput "   版本: $shortVersion..." "Cyan"
                    }
                    
                    # 获取数据库大小
                    $dbSize = docker exec $containerName psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -tAc "SELECT pg_size_pretty(pg_database_size('$($env:POSTGRES_DB)'));" 2>$null
                    if ($dbSize) {
                        Write-ColorOutput "   数据库大小: $dbSize" "Cyan"
                    }
                    
                    # 获取连接数
                    $connections = docker exec $containerName psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -tAc "SELECT count(*) FROM pg_stat_activity;" 2>$null
                    if ($connections) {
                        Write-ColorOutput "   活跃连接: $connections" "Cyan"
                    }
                }
                
                if ($Performance) {
                    # 性能测试
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    docker exec $containerName psql -U $env:POSTGRES_USER -d $env:POSTGRES_DB -c "SELECT 1;" >$null 2>&1
                    $stopwatch.Stop()
                    Write-ColorOutput "   查询响应时间: $($stopwatch.ElapsedMilliseconds)ms" "Cyan"
                }
                
                return $true
            }
        } catch {
            Write-ColorOutput "⚠️ PostgreSQL 连接异常: $($_.Exception.Message)" "Yellow"
        }
        
        Write-ColorOutput "⚠️ PostgreSQL 连接失败 (尝试 $attempt/$Retries)" "Yellow"
        if ($attempt -lt $Retries) {
            Start-Sleep -Seconds 2
        }
    }
    
    Write-ColorOutput "❌ PostgreSQL 健康检查失败" "Red"
    return $false
}

function Test-Redis {
    Write-ColorOutput "🔴 检查 Redis..." "Blue"
    
    $containerName = "${env:COMPOSE_PROJECT_NAME}-redis"
    if (-not $env:COMPOSE_PROJECT_NAME) {
        $containerName = "gccc-redis"
    }
    
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        Write-ColorOutput "   尝试 $attempt/$Retries" "Cyan"
        
        try {
            # 基础连接检查
            $result = docker exec $containerName redis-cli ping 2>$null
            if ($result -match "PONG") {
                Write-ColorOutput "✅ Redis 连接正常" "Green"
                
                if ($Detailed) {
                    # 获取Redis版本
                    $version = docker exec $containerName redis-cli info server 2>$null | Select-String "redis_version" | ForEach-Object { $_.ToString().Split(':')[1].Trim() }
                    if ($version) {
                        Write-ColorOutput "   Redis版本: $version" "Cyan"
                    }
                    
                    # 获取内存使用
                    $memory = docker exec $containerName redis-cli info memory 2>$null | Select-String "used_memory_human" | ForEach-Object { $_.ToString().Split(':')[1].Trim() }
                    if ($memory) {
                        Write-ColorOutput "   内存使用: $memory" "Cyan"
                    }
                    
                    # 获取键数量
                    $keyCount = docker exec $containerName redis-cli dbsize 2>$null
                    if ($keyCount) {
                        Write-ColorOutput "   键数量: $keyCount" "Cyan"
                    }
                }
                
                if ($Performance) {
                    # 性能测试
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    docker exec $containerName redis-cli set test_key "test_value" >$null 2>&1
                    docker exec $containerName redis-cli get test_key >$null 2>&1
                    docker exec $containerName redis-cli del test_key >$null 2>&1
                    $stopwatch.Stop()
                    Write-ColorOutput "   读写响应时间: $($stopwatch.ElapsedMilliseconds)ms" "Cyan"
                }
                
                return $true
            }
        } catch {
            Write-ColorOutput "⚠️ Redis 连接异常: $($_.Exception.Message)" "Yellow"
        }
        
        Write-ColorOutput "⚠️ Redis 连接失败 (尝试 $attempt/$Retries)" "Yellow"
        if ($attempt -lt $Retries) {
            Start-Sleep -Seconds 2
        }
    }
    
    Write-ColorOutput "❌ Redis 健康检查失败" "Red"
    return $false
}

function Get-ResourceUsage {
    Write-ColorOutput "📊 检查容器资源使用..." "Blue"
    
    $containers = @("${env:COMPOSE_PROJECT_NAME}-postgres", "${env:COMPOSE_PROJECT_NAME}-redis")
    if (-not $env:COMPOSE_PROJECT_NAME) {
        $containers = @("gccc-postgres", "gccc-redis")
    }
    
    foreach ($container in $containers) {
        $containerExists = docker ps --format "{{.Names}}" | Where-Object { $_ -eq $container }
        if ($containerExists) {
            Write-ColorOutput "   容器: $container" "Cyan"
            
            try {
                # 获取资源使用统计
                $stats = docker stats $container --no-stream --format "{{.CPUPerc}}`t{{.MemUsage}}`t{{.MemPerc}}" 2>$null
                if ($stats) {
                    $statsParts = $stats.Split("`t")
                    Write-ColorOutput "     CPU: $($statsParts[0])" "Cyan"
                    Write-ColorOutput "     内存: $($statsParts[1]) ($($statsParts[2]))" "Cyan"
                }
                
                # 获取磁盘使用
                $diskUsage = docker exec $container df -h / 2>$null | Select-Object -Last 1
                if ($diskUsage) {
                    $diskParts = $diskUsage.Split([char[]]@(' ', "`t"), [System.StringSplitOptions]::RemoveEmptyEntries)
                    if ($diskParts.Length -ge 5) {
                        Write-ColorOutput "     磁盘: $($diskParts[2])/$($diskParts[1]) ($($diskParts[4]))" "Cyan"
                    }
                }
            } catch {
                Write-ColorOutput "     资源信息获取失败: $($_.Exception.Message)" "Yellow"
            }
        } else {
            Write-ColorOutput "❌ 容器未运行: $container" "Red"
        }
    }
}

# 主程序
function Start-HealthCheck {
    Write-ColorOutput "🏥 GCCC 数据库健康检查开始" "Blue"
    Write-ColorOutput ("=" * 50) "Blue"
    
    $overallStatus = $true
    
    switch ($Service.ToLower()) {
        "network" {
            $overallStatus = Test-NetworkConnectivity
        }
        "postgres" {
            $overallStatus = Test-PostgreSQL
        }
        "redis" {
            $overallStatus = Test-Redis
        }
        "resources" {
            Get-ResourceUsage
        }
        default {
            # 全面检查
            if (-not (Test-NetworkConnectivity)) {
                $overallStatus = $false
            }
            
            Write-Host ""
            
            if (-not (Test-PostgreSQL)) {
                $overallStatus = $false
            }
            
            Write-Host ""
            
            if (-not (Test-Redis)) {
                $overallStatus = $false
            }
            
            Write-Host ""
            
            Get-ResourceUsage
        }
    }
    
    Write-Host ""
    Write-ColorOutput ("=" * 50) "Blue"
    
    if ($overallStatus) {
        Write-ColorOutput "🎉 所有服务健康检查通过！" "Green"
    } else {
        Write-ColorOutput "⚠️ 部分服务存在问题，请检查上述输出" "Red"
    }
    
    return $overallStatus
}

# 执行健康检查
Start-HealthCheck
