# ========================================
# Docker镜像缓存管理工具
# 功能：本地镜像检查、缓存清理、预拉取
# ========================================

param(
    [switch]$CheckImages,
    [switch]$PrePull,
    [switch]$CleanCache,
    [switch]$ShowSize,
    [string[]]$Images = @("postgres:15.4-alpine3.18", "redis:7-alpine")
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

function Get-ImageInfo {
    param([string]$ImageName)
    
    $info = docker inspect $ImageName --format '{{json .}}' 2>$null
    if ($info) {
        $jsonInfo = $info | ConvertFrom-Json
        return @{
            Id = $jsonInfo.Id.Substring(0, 12)
            Created = [DateTime]::Parse($jsonInfo.Created).ToString("yyyy-MM-dd HH:mm:ss")
            Size = [math]::Round($jsonInfo.Size / 1MB, 2)
            VirtualSize = [math]::Round($jsonInfo.VirtualSize / 1MB, 2)
        }
    }
    return $null
}

function Test-ImageExists {
    param([string]$ImageName)
    
    $exists = docker images --format "table {{.Repository}}:{{.Tag}}" | Select-String "^$([regex]::Escape($ImageName))$"
    return $exists -ne $null
}

if ($CheckImages) {
    Write-ColorOutput "🔍 检查本地镜像状态" "Blue"
    Write-ColorOutput "=" * 60 "Blue"
    
    foreach ($image in $Images) {
        if (Test-ImageExists $image) {
            $info = Get-ImageInfo $image
            Write-ColorOutput "✅ $image" "Green"
            if ($info) {
                Write-ColorOutput "   ID: $($info.Id)" "Cyan"
                Write-ColorOutput "   创建时间: $($info.Created)" "Cyan"
                if ($ShowSize) {
                    Write-ColorOutput "   大小: $($info.Size) MB" "Cyan"
                }
            }
        } else {
            Write-ColorOutput "❌ $image (本地不存在)" "Red"
        }
        Write-Host ""
    }
}

if ($PrePull) {
    Write-ColorOutput "📥 预拉取镜像" "Blue"
    Write-ColorOutput "=" * 60 "Blue"
    
    foreach ($image in $Images) {
        if (Test-ImageExists $image) {
            Write-ColorOutput "⏩ 跳过已存在的镜像: $image" "Yellow"
            continue
        }
        
        Write-ColorOutput "🚀 拉取镜像: $image" "Blue"
        $pullResult = docker pull $image
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ 拉取成功: $image" "Green"
        } else {
            Write-ColorOutput "❌ 拉取失败: $image" "Red"
        }
        Write-Host ""
    }
}

if ($CleanCache) {
    Write-ColorOutput "🧹 清理Docker缓存" "Blue"
    Write-ColorOutput "=" * 60 "Blue"
    
    # 显示清理前的空间使用情况
    Write-ColorOutput "清理前的空间使用:" "Cyan"
    docker system df
    Write-Host ""
    
    # 清理未使用的镜像、容器、网络和构建缓存
    Write-ColorOutput "清理未使用的资源..." "Yellow"
    docker system prune -f
    
    Write-ColorOutput "清理未使用的镜像..." "Yellow"
    docker image prune -f
    
    Write-ColorOutput "清理构建缓存..." "Yellow"
    docker builder prune -f
    
    # 显示清理后的空间使用情况
    Write-Host ""
    Write-ColorOutput "清理后的空间使用:" "Green"
    docker system df
}

if ($ShowSize) {
    Write-ColorOutput "💾 Docker存储使用情况" "Blue"
    Write-ColorOutput "=" * 60 "Blue"
    docker system df
    
    Write-Host ""
    Write-ColorOutput "📊 镜像详细信息" "Blue"
    Write-ColorOutput "=" * 60 "Blue"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | Sort-Object
}

if (-not ($CheckImages -or $PrePull -or $CleanCache -or $ShowSize)) {
    Write-ColorOutput "Docker镜像缓存管理工具" "Blue"
    Write-ColorOutput "=" * 60 "Blue"
    Write-ColorOutput "使用方法:" "Yellow"
    Write-ColorOutput "  -CheckImages    检查本地镜像状态" "White"
    Write-ColorOutput "  -PrePull        预拉取所需镜像" "White"  
    Write-ColorOutput "  -CleanCache     清理Docker缓存" "White"
    Write-ColorOutput "  -ShowSize       显示存储使用情况" "White"
    Write-ColorOutput "  -Images         指定镜像列表 (默认: postgres, redis)" "White"
    Write-Host ""
    Write-ColorOutput "示例:" "Green"
    Write-ColorOutput "  .\manage_images.ps1 -CheckImages -ShowSize" "White"
    Write-ColorOutput "  .\manage_images.ps1 -PrePull" "White"
    Write-ColorOutput "  .\manage_images.ps1 -CleanCache" "White"
}
