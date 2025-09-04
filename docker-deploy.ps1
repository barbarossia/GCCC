# ========================================
# GCCC Docker 快速启动脚本 (PowerShell版本)
# ========================================

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "cleanup", "backup", "help")]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Option = ""
)

# 颜色函数
function Write-ColorText {
    param($Text, $Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Status {
    param($Message)
    Write-ColorText "[INFO] $Message" "Green"
}

function Write-Warning {
    param($Message)
    Write-ColorText "[WARN] $Message" "Yellow"
}

function Write-Error {
    param($Message)
    Write-ColorText "[ERROR] $Message" "Red"
}

function Write-Header {
    Write-ColorText "========================================" "Blue"
    Write-ColorText " GCCC DApp Docker 部署脚本" "Blue"
    Write-ColorText "========================================" "Blue"
}

# 检查依赖
function Test-Dependencies {
    Write-Status "检查系统依赖..."
    
    try {
        $null = Get-Command docker -ErrorAction Stop
    } catch {
        Write-Error "Docker 未安装，请先安装 Docker Desktop"
        exit 1
    }
    
    try {
        $null = Get-Command docker-compose -ErrorAction Stop
    } catch {
        Write-Error "Docker Compose 未安装，请确保 Docker Desktop 包含 Compose"
        exit 1
    }
    
    Write-Status "依赖检查完成 ✓"
}

# 环境配置
function Initialize-Environment {
    Write-Status "配置环境变量..."
    
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Warning "已从 .env.example 创建 .env 文件"
            Write-Warning "请编辑 .env 文件配置生产环境密码和密钥！"
        } else {
            Write-Error ".env.example 文件不存在"
            exit 1
        }
    } else {
        Write-Status "发现现有 .env 文件"
    }
}

# 构建镜像
function Build-Images {
    Write-Status "构建 Docker 镜像..."
    
    # 构建数据库镜像
    Write-Status "构建数据库镜像..."
    docker-compose build database
    if ($LASTEXITCODE -ne 0) {
        Write-Error "数据库镜像构建失败"
        exit 1
    }
    
    # 构建后端镜像
    Write-Status "构建后端镜像..."
    docker-compose build backend
    if ($LASTEXITCODE -ne 0) {
        Write-Error "后端镜像构建失败"
        exit 1
    }
    
    Write-Status "镜像构建完成 ✓"
}

# 启动服务
function Start-Services {
    param($Mode)
    
    switch ($Mode) {
        "dev" {
            Write-Status "启动开发环境..."
            docker-compose --profile development up -d
        }
        "prod" {
            Write-Status "启动生产环境..."
            docker-compose up -d
        }
        "nginx" {
            Write-Status "启动生产环境 (包含 Nginx)..."
            docker-compose --profile with-nginx up -d
        }
        default {
            Write-Status "启动默认环境..."
            docker-compose up -d
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "服务启动失败"
        exit 1
    }
}

# 等待服务就绪
function Wait-ForServices {
    Write-Status "等待服务启动..."
    
    # 等待数据库
    Write-Status "等待数据库启动..."
    $timeout = 60
    $counter = 0
    
    do {
        Start-Sleep 1
        $counter++
        try {
            $result = docker-compose exec -T database pg_isready -U gccc_user -d gccc_db 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Status "数据库已就绪 ✓"
                break
            }
        } catch {
            # 继续等待
        }
    } while ($counter -lt $timeout)
    
    if ($counter -eq $timeout) {
        Write-Error "数据库启动超时"
        exit 1
    }
    
    # 等待后端API
    Write-Status "等待后端API启动..."
    $counter = 0
    
    do {
        Start-Sleep 1
        $counter++
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Status "后端API已就绪 ✓"
                break
            }
        } catch {
            # 继续等待
        }
    } while ($counter -lt $timeout)
    
    if ($counter -eq $timeout) {
        Write-Warning "后端API启动超时，但可能仍在初始化中"
    }
}

# 验证部署
function Test-Deployment {
    Write-Status "验证部署状态..."
    
    # 检查容器状态
    Write-Status "检查容器状态..."
    docker-compose ps
    
    # 检查数据库健康状态
    Write-Status "检查数据库健康状态..."
    try {
        docker-compose exec -T database /scripts/health_check.sh 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Status "数据库健康检查通过 ✓"
        } else {
            Write-Warning "数据库健康检查失败"
        }
    } catch {
        Write-Warning "无法执行数据库健康检查"
    }
    
    # 检查API健康状态
    Write-Status "检查API健康状态..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Status "API健康检查通过 ✓"
        } else {
            Write-Warning "API健康检查失败"
        }
    } catch {
        Write-Warning "API健康检查失败"
    }
}

# 显示访问信息
function Show-AccessInfo {
    Write-Header
    Write-Status "部署完成！"
    Write-Host ""
    Write-ColorText "访问信息:" "Green"
    Write-ColorText "  API服务器: " "White" -NoNewline; Write-ColorText "http://localhost:3000" "Blue"
    Write-ColorText "  API文档:   " "White" -NoNewline; Write-ColorText "http://localhost:3000/docs" "Blue"
    Write-ColorText "  健康检查: " "White" -NoNewline; Write-ColorText "http://localhost:3000/health" "Blue"
    Write-Host ""
    Write-ColorText "管理命令:" "Green"
    Write-ColorText "  查看日志: " "White" -NoNewline; Write-ColorText "docker-compose logs -f" "Yellow"
    Write-ColorText "  查看状态: " "White" -NoNewline; Write-ColorText "docker-compose ps" "Yellow"
    Write-ColorText "  停止服务: " "White" -NoNewline; Write-ColorText "docker-compose down" "Yellow"
    Write-ColorText "  数据备份: " "White" -NoNewline; Write-ColorText "docker-compose exec database /scripts/backup.sh" "Yellow"
    Write-Host ""
    Write-Warning "注意: 首次启动可能需要几分钟来初始化数据库"
    Write-Header
}

# 清理函数
function Remove-Services {
    param($Option)
    
    Write-Status "停止所有服务..."
    docker-compose down
    
    switch ($Option) {
        "--volumes" {
            Write-Warning "删除所有数据卷..."
            docker-compose down -v
        }
        "--all" {
            Write-Warning "删除所有容器、镜像和数据卷..."
            docker-compose down -v --rmi all
        }
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host "用法: .\docker-deploy.ps1 <命令> [选项]"
    Write-Host ""
    Write-Host "命令:"
    Write-Host "  start [dev|prod|nginx]  启动服务 (默认: 生产模式)"
    Write-Host "  stop                    停止服务"
    Write-Host "  restart                 重启服务"
    Write-Host "  logs [service]          查看日志"
    Write-Host "  status                  查看服务状态"
    Write-Host "  cleanup [--volumes|--all] 清理容器和数据"
    Write-Host "  backup                  创建数据库备份"
    Write-Host "  help                    显示帮助信息"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\docker-deploy.ps1 start          # 启动生产环境"
    Write-Host "  .\docker-deploy.ps1 start dev      # 启动开发环境"
    Write-Host "  .\docker-deploy.ps1 start nginx    # 启动带Nginx的生产环境"
    Write-Host "  .\docker-deploy.ps1 logs backend   # 查看后端日志"
    Write-Host "  .\docker-deploy.ps1 cleanup --volumes # 清理包括数据卷"
}

# 主函数
function Main {
    Write-Header
    
    switch ($Command) {
        "start" {
            Test-Dependencies
            Initialize-Environment
            Build-Images
            Start-Services $Option
            Wait-ForServices
            Test-Deployment
            Show-AccessInfo
        }
        "stop" {
            Write-Status "停止服务..."
            docker-compose down
            Write-Status "服务已停止"
        }
        "restart" {
            Write-Status "重启服务..."
            docker-compose restart
            Wait-ForServices
            Test-Deployment
        }
        "logs" {
            if ($Option) {
                docker-compose logs -f $Option
            } else {
                docker-compose logs -f
            }
        }
        "status" {
            docker-compose ps
        }
        "cleanup" {
            Remove-Services $Option
        }
        "backup" {
            Write-Status "创建数据库备份..."
            docker-compose exec database /scripts/backup.sh
        }
        "help" {
            Show-Help
        }
        default {
            Write-Error "未知命令: $Command"
            Show-Help
            exit 1
        }
    }
}

# 错误处理
trap {
    Write-Error "脚本执行失败: $_"
    exit 1
}

# 执行主函数
Main
