-- ================================================================
-- GCCC 数据库迁移管理脚本
-- 用于版本控制和升级管理
-- ================================================================

-- 创建迁移管理表
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(20) NOT NULL UNIQUE,
    filename VARCHAR(255) NOT NULL,
    description TEXT,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INTEGER,
    checksum VARCHAR(64),
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_schema_migrations_version ON schema_migrations(version);
CREATE INDEX IF NOT EXISTS idx_schema_migrations_executed_at ON schema_migrations(executed_at);

-- 迁移管理函数
CREATE OR REPLACE FUNCTION apply_migration(
    p_version VARCHAR(20),
    p_filename VARCHAR(255),
    p_description TEXT,
    p_sql_content TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time INTEGER;
    migration_exists BOOLEAN;
    error_msg TEXT;
BEGIN
    -- 检查迁移是否已执行
    SELECT EXISTS(
        SELECT 1 FROM schema_migrations 
        WHERE version = p_version AND success = TRUE
    ) INTO migration_exists;
    
    IF migration_exists THEN
        RAISE NOTICE 'Migration % already applied, skipping...', p_version;
        RETURN TRUE;
    END IF;
    
    -- 记录开始时间
    start_time := clock_timestamp();
    
    -- 执行迁移SQL
    BEGIN
        EXECUTE p_sql_content;
        
        -- 计算执行时间
        end_time := clock_timestamp();
        execution_time := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
        
        -- 记录成功的迁移
        INSERT INTO schema_migrations (
            version, filename, description, execution_time_ms, success
        ) VALUES (
            p_version, p_filename, p_description, execution_time, TRUE
        );
        
        RAISE NOTICE 'Migration % applied successfully in %ms', p_version, execution_time;
        RETURN TRUE;
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        
        -- 记录失败的迁移
        INSERT INTO schema_migrations (
            version, filename, description, success, error_message
        ) VALUES (
            p_version, p_filename, p_description, FALSE, error_msg
        );
        
        RAISE EXCEPTION 'Migration % failed: %', p_version, error_msg;
        RETURN FALSE;
    END;
END;
$$ LANGUAGE plpgsql;

-- 查看迁移状态函数
CREATE OR REPLACE FUNCTION get_migration_status()
RETURNS TABLE(
    version VARCHAR(20),
    filename VARCHAR(255),
    description TEXT,
    executed_at TIMESTAMP WITH TIME ZONE,
    execution_time_ms INTEGER,
    success BOOLEAN,
    error_message TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sm.version,
        sm.filename,
        sm.description,
        sm.executed_at,
        sm.execution_time_ms,
        sm.success,
        sm.error_message
    FROM schema_migrations sm
    ORDER BY sm.executed_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 回滚迁移函数（谨慎使用）
CREATE OR REPLACE FUNCTION rollback_migration(p_version VARCHAR(20))
RETURNS BOOLEAN AS $$
BEGIN
    -- 简单的回滚方法：标记为未执行
    -- 注意：这不会实际撤销SQL更改，需要手动处理
    UPDATE schema_migrations 
    SET success = FALSE, 
        error_message = 'Manually rolled back on ' || CURRENT_TIMESTAMP
    WHERE version = p_version;
    
    IF FOUND THEN
        RAISE NOTICE 'Migration % marked as rolled back', p_version;
        RETURN TRUE;
    ELSE
        RAISE NOTICE 'Migration % not found', p_version;
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 数据库健康检查函数
CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE(
    check_name VARCHAR(50),
    status VARCHAR(20),
    details TEXT
) AS $$
BEGIN
    -- 检查表数量
    RETURN QUERY
    SELECT 
        'Table Count'::VARCHAR(50),
        CASE WHEN COUNT(*) >= 20 THEN 'PASS' ELSE 'WARN' END::VARCHAR(20),
        'Found ' || COUNT(*)::TEXT || ' tables'::TEXT
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    
    -- 检查函数数量
    RETURN QUERY
    SELECT 
        'Function Count'::VARCHAR(50),
        CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'WARN' END::VARCHAR(20),
        'Found ' || COUNT(*)::TEXT || ' functions'::TEXT
    FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
    
    -- 检查扩展
    RETURN QUERY
    SELECT 
        'Extensions'::VARCHAR(50),
        CASE WHEN COUNT(*) >= 4 THEN 'PASS' ELSE 'FAIL' END::VARCHAR(20),
        'Installed: ' || STRING_AGG(extname, ', ')::TEXT
    FROM pg_extension 
    WHERE extname IN ('uuid-ossp', 'pgcrypto', 'btree_gin', 'pg_trgm');
    
    -- 检查连接数
    RETURN QUERY
    SELECT 
        'Active Connections'::VARCHAR(50),
        'INFO'::VARCHAR(20),
        COUNT(*)::TEXT || ' active connections'::TEXT
    FROM pg_stat_activity 
    WHERE state = 'active';
    
    -- 检查数据库大小
    RETURN QUERY
    SELECT 
        'Database Size'::VARCHAR(50),
        'INFO'::VARCHAR(20),
        pg_size_pretty(pg_database_size(current_database()))::TEXT
    FROM pg_database_size(current_database());
END;
$$ LANGUAGE plpgsql;

-- 创建备份函数
CREATE OR REPLACE FUNCTION create_backup_metadata(backup_name VARCHAR(255))
RETURNS VOID AS $$
BEGIN
    -- 创建备份元数据表（如果不存在）
    CREATE TABLE IF NOT EXISTS backup_metadata (
        id SERIAL PRIMARY KEY,
        backup_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        database_size BIGINT,
        table_count INTEGER,
        function_count INTEGER,
        migration_version VARCHAR(20),
        notes TEXT
    );
    
    -- 插入备份记录
    INSERT INTO backup_metadata (
        backup_name,
        database_size,
        table_count,
        function_count,
        migration_version,
        notes
    ) VALUES (
        backup_name,
        pg_database_size(current_database()),
        (SELECT COUNT(*) FROM information_schema.tables 
         WHERE table_schema = 'public' AND table_type = 'BASE TABLE'),
        (SELECT COUNT(*) FROM information_schema.routines 
         WHERE routine_schema = 'public' AND routine_type = 'FUNCTION'),
        (SELECT version FROM schema_migrations 
         WHERE success = TRUE ORDER BY executed_at DESC LIMIT 1),
        'Auto backup created by migration system'
    );
    
    RAISE NOTICE 'Backup metadata for % created successfully', backup_name;
END;
$$ LANGUAGE plpgsql;

-- 示例迁移记录（标记初始版本）
INSERT INTO schema_migrations (
    version, filename, description, success
) VALUES 
('1.0.0', 'deploy.sql', 'Initial database schema deployment', TRUE),
('1.0.1', '05-initial-data.sql', 'Initial data population', TRUE);

-- 显示当前迁移状态
SELECT * FROM get_migration_status();

-- 执行健康检查
SELECT * FROM database_health_check();
