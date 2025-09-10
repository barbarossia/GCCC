# ========================================
# GCCC数据库优化部署脚本
# 功能：本地镜像检查、网络超时处理、智能重试
# ========================================

param(
    [string]$Environment = "development",
    [int]$Timeout = 300,
    [int]$Retries = 3,
    [switch]$ForceRebuild,
    [switch]$PullLatest,
    [switch]$Verbose
)

# 颜色输出函数
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

# 检查本地镜像是否存在
function Test-LocalImage {
    param([string]$ImageName)
    
    Write-ColorOutput "🔍 检查本地镜像: $ImageName" "Blue"
    
    $imageExists = docker images --format "table {{.Repository}}:{{.Tag}}" | Select-String $ImageName
    
    if ($imageExists) {
        Write-ColorOutput "✅ 本地镜像存在: $ImageName" "Green"
        
        # 检查镜像创建时间
        $imageInfo = docker inspect $ImageName --format '{{.Created}}' 2>$null
        if ($imageInfo) {
            $createDate = [DateTime]::Parse($imageInfo).ToString("yyyy-MM-dd HH:mm:ss")
            Write-ColorOutput "📅 镜像创建时间: $createDate" "Cyan"
        }
        
        return $true
    } else {
        Write-ColorOutput "❌ 本地镜像不存在: $ImageName" "Yellow"
        return $false
    }
}

# 智能拉取镜像
function Get-DockerImage {
    param(
        [string]$ImageName,
        [int]$TimeoutSeconds = $Timeout,
        [int]$MaxRetries = $Retries
    )
    
    # 如果不强制拉取且本地存在镜像，则跳过
    if (-not $PullLatest -and (Test-LocalImage $ImageName)) {
        Write-ColorOutput "⏩ 跳过拉取，使用本地镜像: $ImageName" "Green"
        return $true
    }
    
    Write-ColorOutput "🚀 开始拉取镜像: $ImageName" "Blue"
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        Write-ColorOutput "📥 尝试拉取镜像 ($attempt/$MaxRetries): $ImageName" "Yellow"
        
        $pullProcess = Start-Process -FilePath "docker" -ArgumentList "pull", $ImageName -NoNewWindow -PassThru -RedirectStandardOutput "pull_output.log" -RedirectStandardError "pull_error.log"
        
        # 等待拉取完成或超时
        $completed = $pullProcess.WaitForExit($TimeoutSeconds * 1000)
        
        if ($completed -and $pullProcess.ExitCode -eq 0) {
            Write-ColorOutput "✅ 镜像拉取成功: $ImageName" "Green"
            return $true
        } elseif (-not $completed) {
            Write-ColorOutput "⏱️ 镜像拉取超时 ($TimeoutSeconds 秒): $ImageName" "Red"
            $pullProcess.Kill()
        } else {
            Write-ColorOutput "❌ 镜像拉取失败 (退出码: $($pullProcess.ExitCode)): $ImageName" "Red"
            
            if (Test-Path "pull_error.log") {
                $errorContent = Get-Content "pull_error.log" -Raw
                Write-ColorOutput "错误信息: $errorContent" "Red"
            }
        }
        
        if ($attempt -lt $MaxRetries) {
            $waitTime = [Math]::Pow(2, $attempt) * 5  # 指数退避：5s, 10s, 20s
            Write-ColorOutput "⏳ 等待 $waitTime 秒后重试..." "Yellow"
            Start-Sleep -Seconds $waitTime
        }
    }
    
    # 所有尝试都失败，检查是否有本地镜像可用
    if (Test-LocalImage $ImageName) {
        Write-ColorOutput "⚠️ 拉取失败但本地镜像存在，继续使用本地镜像" "Yellow"
        return $true
    }
    
    Write-ColorOutput "💥 镜像拉取完全失败: $ImageName" "Red"
    return $false
}

# 主程序开始
Write-ColorOutput "🎯 GCCC数据库优化部署开始" "Blue"
Write-ColorOutput "环境: $Environment" "Cyan"
Write-ColorOutput "超时设置: $Timeout 秒" "Cyan"
Write-ColorOutput "重试次数: $Retries 次" "Cyan"

# 设置环境变量文件
$envFile = ".env.$Environment"
if (-not (Test-Path $envFile)) {
    $envFile = ".env"
}

if (Test-Path $envFile) {
    Write-ColorOutput "📝 使用环境配置文件: $envFile" "Green"
} else {
    Write-ColorOutput "❌ 环境配置文件未找到: $envFile" "Red"
    exit 1
}

# 清理之前的日志文件
@("pull_output.log", "pull_error.log") | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_ -Force }
}

# 设置Docker环境变量以优化网络超时
$env:DOCKER_CLIENT_TIMEOUT = $Timeout
$env:COMPOSE_HTTP_TIMEOUT = $Timeout
$env:BUILDKIT_PROGRESS = "plain"

# 定义要使用的镜像
$images = @(
    "postgres:15.4-alpine3.18",
    "redis:7-alpine"
)

# 智能拉取所需镜像
$allImagesReady = $true
foreach ($image in $images) {
    if (-not (Get-DockerImage -ImageName $image)) {
        $allImagesReady = $false
        Write-ColorOutput "💥 关键镜像获取失败: $image" "Red"
    }
}

if (-not $allImagesReady) {
    Write-ColorOutput "💥 部分镜像获取失败，但尝试继续部署..." "Yellow"
}

# 停止现有容器（如果存在）
Write-ColorOutput "🛑 停止现有容器..." "Yellow"
docker-compose --env-file $envFile down --remove-orphans --timeout 30

# 创建必要的数据目录
Write-ColorOutput "📁 创建数据目录..." "Blue"
@("data", "data/postgres", "data/redis") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-ColorOutput "✅ 创建目录: $_" "Green"
    }
}

# 构建并启动容器
Write-ColorOutput "🚀 启动数据库服务..." "Blue"

$composeArgs = @(
    "--env-file", $envFile,
    "up", "-d",
    "--build",
    "--remove-orphans",
    "--timeout", "60"
)

if ($ForceRebuild) {
    $composeArgs += "--force-recreate"
}

if ($Verbose) {
    $composeArgs += "--verbose"
}

$startProcess = Start-Process -FilePath "docker-compose" -ArgumentList $composeArgs -NoNewWindow -PassThru -Wait

if ($startProcess.ExitCode -ne 0) {
    Write-ColorOutput "❌ 容器启动失败 (退出码: $($startProcess.ExitCode))" "Red"
    
    # 显示容器日志以帮助调试
    Write-ColorOutput "📋 容器状态和日志:" "Yellow"
    docker-compose --env-file $envFile ps
    docker-compose --env-file $envFile logs --tail=50
    
    exit 1
}

# 等待服务就绪
Write-ColorOutput "⏳ 等待数据库服务就绪..." "Blue"

$maxWaitTime = 120
$waitedTime = 0
$healthyServices = 0

while ($waitedTime -lt $maxWaitTime -and $healthyServices -lt 2) {
    Start-Sleep -Seconds 5
    $waitedTime += 5
    
    $healthyServices = 0
    
    # 检查 PostgreSQL
    $pgHealth = docker exec "${env:COMPOSE_PROJECT_NAME}-postgres" pg_isready -U ${env:POSTGRES_USER} 2>$null
    if ($LASTEXITCODE -eq 0) {
        $healthyServices++
    }
    
    # 检查 Redis
    $redisHealth = docker exec "${env:COMPOSE_PROJECT_NAME}-redis" redis-cli ping 2>$null
    if ($LASTEXITCODE -eq 0) {
        $healthyServices++
    }
    
    Write-ColorOutput "⏱️ 等待中... ($waitedTime/$maxWaitTime 秒) - 就绪服务: $healthyServices/2" "Yellow"
}

# 清理临时文件
@("pull_output.log", "pull_error.log") | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_ -Force }
}

if ($healthyServices -eq 2) {
    Write-ColorOutput "🎉 数据库服务部署成功！" "Green"
    Write-ColorOutput "📊 服务状态:" "Blue"
    docker-compose --env-file $envFile ps
    
    Write-ColorOutput "🔗 连接信息:" "Blue"
    Write-ColorOutput "  PostgreSQL: localhost:${env:POSTGRES_PORT}" "Cyan"
    Write-ColorOutput "  Redis: localhost:${env:REDIS_PORT}" "Cyan"
    
} else {
    Write-ColorOutput "⚠️ 部分服务未能在 $maxWaitTime 秒内就绪" "Yellow"
    Write-ColorOutput "📋 当前状态:" "Yellow"
    docker-compose --env-file $envFile ps
    docker-compose --env-file $envFile logs --tail=20
}

Write-ColorOutput "✅ 部署脚本执行完成" "Blue"
