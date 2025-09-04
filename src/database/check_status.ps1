# ================================================================
# GCCC 数据库状态检查脚本 (PowerShell 版本)
# 用于Windows环境的数据库部署状态验证
# ================================================================

param(
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432", 
    [string]$DbName = "gccc_db",
    [string]$DbUser = "postgres"
)

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "GCCC 数据库状态检查" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "连接参数:" -ForegroundColor Yellow
Write-Host "  主机: $DbHost"
Write-Host "  端口: $DbPort"
Write-Host "  数据库: $DbName"
Write-Host "  用户: $DbUser"
Write-Host ""

# 检查psql是否可用
try {
    $null = Get-Command psql -ErrorAction Stop
} catch {
    Write-Host "✗ psql 命令未找到，请确保 PostgreSQL 客户端已安装并在 PATH 中" -ForegroundColor Red
    exit 1
}

# 检查数据库连接
Write-Host "1. 检查数据库连接..." -ForegroundColor Yellow
try {
    $env:PGPASSWORD = Read-Host "请输入数据库密码" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($env:PGPASSWORD))
    $env:PGPASSWORD = $password
    
    $result = psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ 数据库连接正常" -ForegroundColor Green
    } else {
        Write-Host "   ✗ 数据库连接失败" -ForegroundColor Red
        Write-Host "请检查数据库是否运行，连接参数是否正确" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ✗ 连接测试失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 检查表数量
Write-Host "2. 检查表结构..." -ForegroundColor Yellow
$tableCountQuery = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';"
$tableCount = (psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c $tableCountQuery 2>$null).Trim()

Write-Host "   表数量: $tableCount"
if ([int]$tableCount -ge 20) {
    Write-Host "   ✓ 表结构完整" -ForegroundColor Green
} else {
    Write-Host "   ✗ 表结构不完整，期望至少20个表" -ForegroundColor Red
}

Write-Host ""

# 检查函数
Write-Host "3. 检查存储函数..." -ForegroundColor Yellow
$functionCountQuery = "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';"
$functionCount = (psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c $functionCountQuery 2>$null).Trim()

Write-Host "   函数数量: $functionCount"
if ([int]$functionCount -ge 10) {
    Write-Host "   ✓ 函数完整" -ForegroundColor Green
} else {
    Write-Host "   ✗ 函数不完整，期望至少10个函数" -ForegroundColor Red
}

Write-Host ""

# 检查扩展
Write-Host "4. 检查数据库扩展..." -ForegroundColor Yellow
$extensionQuery = @"
SELECT 
    extname as "扩展名",
    extversion as "版本"
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin', 'pg_trgm')
ORDER BY extname;
"@

psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c $extensionQuery 2>$null

Write-Host ""

# 检查初始数据
Write-Host "5. 检查初始数据..." -ForegroundColor Yellow
$configCount = (psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c "SELECT COUNT(*) FROM system_configs;" 2>$null).Trim()
$userCount = (psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c "SELECT COUNT(*) FROM users;" 2>$null).Trim()
$poolCount = (psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -t -c "SELECT COUNT(*) FROM staking_pools;" 2>$null).Trim()

Write-Host "   系统配置: $configCount 条"
Write-Host "   用户数据: $userCount 个"
Write-Host "   质押池: $poolCount 个"

if ([int]$configCount -ge 40) {
    Write-Host "   ✓ 初始数据完整" -ForegroundColor Green
} else {
    Write-Host "   ✗ 初始数据不完整" -ForegroundColor Red
}

Write-Host ""

# 执行数据库健康检查
Write-Host "6. 数据库健康检查..." -ForegroundColor Yellow
$healthCheckQuery = "SELECT * FROM database_health_check();"
psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c $healthCheckQuery 2>$null

Write-Host ""

# 显示数据库大小
Write-Host "7. 数据库信息..." -ForegroundColor Yellow
$dbInfoQuery = @"
SELECT 
    'Database Size' as "信息类型",
    pg_size_pretty(pg_database_size(current_database())) as "值"
UNION ALL
SELECT 
    'Active Connections',
    COUNT(*)::text
FROM pg_stat_activity 
WHERE state = 'active' AND datname = current_database();
"@

psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c $dbInfoQuery 2>$null

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "数据库状态检查完成" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# 检查迁移状态
Write-Host ""
Write-Host "8. 迁移状态..." -ForegroundColor Yellow
$migrationQuery = @"
SELECT 
    version as "版本",
    description as "描述",
    executed_at as "执行时间",
    success as "成功"
FROM get_migration_status() 
ORDER BY executed_at DESC;
"@

psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -c $migrationQuery 2>$null

Write-Host ""
Write-Host "检查完成！如有问题，请查看具体错误信息。" -ForegroundColor Green

# 清理环境变量
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
