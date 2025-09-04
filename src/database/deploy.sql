-- ================================================================
-- GCCC 数据库完整部署脚本
-- 按正确顺序执行所有数据库初始化操作
-- ================================================================

\echo '开始部署GCCC数据库...'

-- 设置客户端编码
SET client_encoding = 'UTF8';

-- 第一步：创建数据库和基础配置
\echo '第1步：创建数据库和基础配置...'
\i '01-database-init-config.sql'

-- 连接到新创建的数据库
\c gccc_db

-- 第二步：创建核心数据表
\echo '第2步：创建核心数据表...'
\i '02-core-tables.sql'

-- 第三步：创建业务模块表
\echo '第3步：创建业务模块表...'
\i '03-business-tables.sql'

-- 第四步：创建数据库函数
\echo '第4步：创建数据库函数...'
\i '04-database-functions.sql'

-- 第五步：插入初始数据
\echo '第5步：插入初始数据...'
\i '05-initial-data.sql'

-- 验证部署结果
\echo '验证数据库部署结果...'

-- 显示数据库信息
SELECT 
    'Database Version' as info_type,
    version() as info_value
UNION ALL
SELECT 
    'Current Database',
    current_database()
UNION ALL
SELECT 
    'Current User',
    current_user
UNION ALL
SELECT 
    'Deploy Timestamp',
    NOW()::text;

-- 显示表统计信息
SELECT 
    schemaname,
    tablename,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_schema = schemaname 
       AND table_name = tablename) as column_count,
    COALESCE((
        SELECT n_tup_ins 
        FROM pg_stat_user_tables 
        WHERE schemaname = pg_stat_user_tables.schemaname 
          AND tablename = pg_stat_user_tables.relname
    ), 0) as row_count
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 显示函数列表
SELECT 
    routine_name as function_name,
    routine_type as type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- 显示扩展列表
SELECT 
    extname as extension_name,
    extversion as version
FROM pg_extension
WHERE extname != 'plpgsql';

\echo '数据库部署完成！'
\echo '可以开始使用GCCC DApp数据库了。'
