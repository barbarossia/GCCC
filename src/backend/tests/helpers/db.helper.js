/**
 * GCCC 数据库测试辅助工具
 * 
 * 为单元测试和集成测试提供数据库设置和清理功能
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const { Pool } = require('pg');
const Redis = require('ioredis');
const path = require('path');
const fs = require('fs').promises;

/**
 * ============================================
 * 测试数据库配置
 * ============================================
 */

const TEST_DB_CONFIG = {
  user: process.env.TEST_DB_USER || 'gccc_test',
  password: process.env.TEST_DB_PASSWORD || 'gccc_test_password',
  host: process.env.TEST_DB_HOST || 'localhost',
  port: process.env.TEST_DB_PORT || 5432,
  database: process.env.TEST_DB_NAME || 'gccc_test_db',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
};

const TEST_REDIS_CONFIG = {
  host: process.env.TEST_REDIS_HOST || 'localhost',
  port: process.env.TEST_REDIS_PORT || 6379,
  db: process.env.TEST_REDIS_DB || 1, // 使用独立的测试数据库
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
  enableReadyCheck: false,
  lazyConnect: true
};

let testDbPool = null;
let testRedisClient = null;

/**
 * ============================================
 * 数据库连接管理
 * ============================================
 */

/**
 * 创建测试数据库连接池
 */
const createTestDbPool = async () => {
  if (testDbPool) {
    return testDbPool;
  }
  
  try {
    testDbPool = new Pool(TEST_DB_CONFIG);
    
    // 测试连接
    const client = await testDbPool.connect();
    await client.query('SELECT NOW()');
    client.release();
    
    console.log('✅ Test database connection established');
    return testDbPool;
  } catch (error) {
    console.error('❌ Failed to connect to test database:', error.message);
    throw error;
  }
};

/**
 * 创建测试Redis连接
 */
const createTestRedisClient = async () => {
  if (testRedisClient) {
    return testRedisClient;
  }
  
  try {
    testRedisClient = new Redis(TEST_REDIS_CONFIG);
    
    // 测试连接
    await testRedisClient.ping();
    
    console.log('✅ Test Redis connection established');
    return testRedisClient;
  } catch (error) {
    console.error('❌ Failed to connect to test Redis:', error.message);
    throw error;
  }
};

/**
 * ============================================
 * 数据库初始化
 * ============================================
 */

/**
 * 执行SQL脚本
 */
const executeSqlScript = async (scriptPath) => {
  try {
    const sql = await fs.readFile(scriptPath, 'utf8');
    const pool = await createTestDbPool();
    
    // 分割SQL语句（简单分割，假设每个语句以分号结尾）
    const statements = sql
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0);
    
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      for (const statement of statements) {
        if (statement.trim()) {
          await client.query(statement);
        }
      }
      
      await client.query('COMMIT');
      console.log(`✅ Executed SQL script: ${path.basename(scriptPath)}`);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error(`❌ Failed to execute SQL script ${scriptPath}:`, error.message);
    throw error;
  }
};

/**
 * 初始化测试数据库架构
 */
const initializeTestDatabase = async () => {
  const schemaPath = path.join(__dirname, '../../../docs/design/backend/schema.sql');
  
  try {
    // 检查架构文件是否存在
    await fs.access(schemaPath);
    await executeSqlScript(schemaPath);
  } catch (error) {
    console.warn(`⚠️  Schema file not found: ${schemaPath}`);
    // 如果没有架构文件，创建基本表结构
    await createBasicTables();
  }
};

/**
 * 创建基本表结构（用于测试）
 */
const createBasicTables = async () => {
  const pool = await createTestDbPool();
  
  const createTablesSQL = `
    -- 用户表
    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      username VARCHAR(50) UNIQUE NOT NULL,
      email VARCHAR(255) UNIQUE,
      password VARCHAR(255),
      wallet_address VARCHAR(255) UNIQUE,
      wallet_type VARCHAR(20),
      role VARCHAR(20) DEFAULT 'user',
      status VARCHAR(20) DEFAULT 'active',
      kyc_status VARCHAR(20) DEFAULT 'pending',
      level INTEGER DEFAULT 1,
      experience INTEGER DEFAULT 0,
      avatar_url VARCHAR(500),
      referral_code VARCHAR(20) UNIQUE,
      referred_by UUID REFERENCES users(id),
      terms_accepted BOOLEAN DEFAULT FALSE,
      privacy_accepted BOOLEAN DEFAULT FALSE,
      email_verified_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_login_at TIMESTAMP
    );
    
    -- 用户会话表
    CREATE TABLE IF NOT EXISTS user_sessions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      device_id VARCHAR(255),
      device_name VARCHAR(255),
      platform VARCHAR(50),
      browser VARCHAR(100),
      app_version VARCHAR(20),
      ip_address INET,
      location VARCHAR(255),
      user_agent TEXT,
      status VARCHAR(20) DEFAULT 'active',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP
    );
    
    -- 权限表
    CREATE TABLE IF NOT EXISTS permissions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(100) UNIQUE NOT NULL,
      description TEXT,
      category VARCHAR(50),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 角色表
    CREATE TABLE IF NOT EXISTS roles (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(50) UNIQUE NOT NULL,
      description TEXT,
      level INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 角色权限关联表
    CREATE TABLE IF NOT EXISTS role_permissions (
      role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
      permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
      PRIMARY KEY (role_id, permission_id)
    );
    
    -- 用户权限表（直接授予的权限）
    CREATE TABLE IF NOT EXISTS user_permissions (
      user_id UUID REFERENCES users(id) ON DELETE CASCADE,
      permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
      granted_by UUID REFERENCES users(id),
      granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP,
      PRIMARY KEY (user_id, permission_id)
    );
    
    -- 登录失败记录表
    CREATE TABLE IF NOT EXISTS login_attempts (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES users(id) ON DELETE CASCADE,
      ip_address INET,
      user_agent TEXT,
      success BOOLEAN,
      failure_reason VARCHAR(100),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 索引
    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_users_wallet_address ON users(wallet_address);
    CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);
    CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_sessions_status ON user_sessions(status);
    CREATE INDEX IF NOT EXISTS idx_login_attempts_user_id ON login_attempts(user_id);
    CREATE INDEX IF NOT EXISTS idx_login_attempts_ip ON login_attempts(ip_address);
    CREATE INDEX IF NOT EXISTS idx_login_attempts_created_at ON login_attempts(created_at);
  `;
  
  const client = await pool.connect();
  
  try {
    await client.query(createTablesSQL);
    console.log('✅ Basic test tables created');
  } catch (error) {
    console.error('❌ Failed to create basic tables:', error.message);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * ============================================
 * 测试数据管理
 * ============================================
 */

/**
 * 清理所有测试数据
 */
const cleanupTestData = async () => {
  const pool = await createTestDbPool();
  const redis = await createTestRedisClient();
  
  try {
    // 清理PostgreSQL数据
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // 按依赖顺序删除数据
      const tableOrder = [
        'login_attempts',
        'user_permissions',
        'role_permissions',
        'user_sessions',
        'users',
        'permissions',
        'roles'
      ];
      
      for (const table of tableOrder) {
        await client.query(`TRUNCATE TABLE ${table} RESTART IDENTITY CASCADE`);
      }
      
      await client.query('COMMIT');
      console.log('✅ Test database cleaned');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    
    // 清理Redis数据
    await redis.flushdb();
    console.log('✅ Test Redis cleaned');
    
  } catch (error) {
    console.error('❌ Failed to cleanup test data:', error.message);
    throw error;
  }
};

/**
 * 插入测试数据
 */
const insertTestData = async (data) => {
  const pool = await createTestDbPool();
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    // 插入角色数据
    if (data.roles) {
      for (const role of data.roles) {
        await client.query(
          'INSERT INTO roles (id, name, description, level) VALUES ($1, $2, $3, $4)',
          [role.id, role.name, role.description, role.level]
        );
      }
    }
    
    // 插入权限数据
    if (data.permissions) {
      for (const permission of data.permissions) {
        await client.query(
          'INSERT INTO permissions (id, name, description, category) VALUES ($1, $2, $3, $4)',
          [permission.id, permission.name, permission.description, permission.category]
        );
      }
    }
    
    // 插入角色权限关联
    if (data.rolePermissions) {
      for (const rp of data.rolePermissions) {
        await client.query(
          'INSERT INTO role_permissions (role_id, permission_id) VALUES ($1, $2)',
          [rp.role_id, rp.permission_id]
        );
      }
    }
    
    // 插入用户数据
    if (data.users) {
      for (const user of data.users) {
        await client.query(`
          INSERT INTO users (
            id, username, email, password, wallet_address, wallet_type, 
            role, status, kyc_status, level, experience, avatar_url,
            referral_code, referred_by, terms_accepted, privacy_accepted,
            email_verified_at, created_at, updated_at, last_login_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
        `, [
          user.id, user.username, user.email, user.password, 
          user.wallet_address, user.wallet_type, user.role, user.status,
          user.kyc_status, user.level, user.experience, user.avatar_url,
          user.referral_code, user.referred_by, user.terms_accepted, user.privacy_accepted,
          user.email_verified_at, user.created_at, user.updated_at, user.last_login_at
        ]);
      }
    }
    
    // 插入会话数据
    if (data.sessions) {
      for (const session of data.sessions) {
        await client.query(`
          INSERT INTO user_sessions (
            id, user_id, device_id, device_name, platform, browser,
            app_version, ip_address, location, user_agent, status,
            created_at, updated_at, last_active_at, expires_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        `, [
          session.id, session.user_id, session.device_id, session.device_name,
          session.platform, session.browser, session.app_version, session.ip_address,
          session.location, session.user_agent, session.status, session.created_at,
          session.updated_at, session.last_active_at, session.expires_at
        ]);
      }
    }
    
    await client.query('COMMIT');
    console.log('✅ Test data inserted');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Failed to insert test data:', error.message);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * ============================================
 * 测试套件管理
 * ============================================
 */

/**
 * 设置测试数据库
 */
const setupTestDB = async () => {
  try {
    console.log('🚀 Setting up test database...');
    
    // 创建连接
    await createTestDbPool();
    await createTestRedisClient();
    
    // 清理现有数据
    await cleanupTestData();
    
    // 初始化数据库架构
    await initializeTestDatabase();
    
    // 插入基础测试数据
    await insertBasicTestData();
    
    console.log('✅ Test database setup completed');
    
  } catch (error) {
    console.error('❌ Test database setup failed:', error.message);
    throw error;
  }
};

/**
 * 清理测试数据库
 */
const cleanupTestDB = async () => {
  try {
    console.log('🧹 Cleaning up test database...');
    
    // 清理数据
    await cleanupTestData();
    
    // 关闭连接
    if (testDbPool) {
      await testDbPool.end();
      testDbPool = null;
    }
    
    if (testRedisClient) {
      await testRedisClient.quit();
      testRedisClient = null;
    }
    
    console.log('✅ Test database cleanup completed');
    
  } catch (error) {
    console.error('❌ Test database cleanup failed:', error.message);
    throw error;
  }
};

/**
 * 插入基础测试数据
 */
const insertBasicTestData = async () => {
  const basicData = {
    roles: [
      {
        id: 'role-user',
        name: 'user',
        description: '普通用户',
        level: 1
      },
      {
        id: 'role-admin',
        name: 'admin',
        description: '管理员',
        level: 5
      }
    ],
    permissions: [
      {
        id: 'perm-user-read',
        name: 'user:read',
        description: '读取用户信息',
        category: 'user'
      },
      {
        id: 'perm-user-write',
        name: 'user:write',
        description: '修改用户信息',
        category: 'user'
      },
      {
        id: 'perm-admin-all',
        name: 'admin:*',
        description: '所有管理员权限',
        category: 'admin'
      }
    ],
    rolePermissions: [
      {
        role_id: 'role-user',
        permission_id: 'perm-user-read'
      },
      {
        role_id: 'role-admin',
        permission_id: 'perm-user-read'
      },
      {
        role_id: 'role-admin',
        permission_id: 'perm-user-write'
      },
      {
        role_id: 'role-admin',
        permission_id: 'perm-admin-all'
      }
    ]
  };
  
  await insertTestData(basicData);
};

/**
 * ============================================
 * 数据库查询助手
 * ============================================
 */

/**
 * 执行测试查询
 */
const executeTestQuery = async (query, params = []) => {
  const pool = await createTestDbPool();
  const client = await pool.connect();
  
  try {
    const result = await client.query(query, params);
    return result;
  } finally {
    client.release();
  }
};

/**
 * 获取表中的记录数
 */
const getTableCount = async (tableName) => {
  const result = await executeTestQuery(`SELECT COUNT(*) FROM ${tableName}`);
  return parseInt(result.rows[0].count);
};

/**
 * 检查记录是否存在
 */
const recordExists = async (tableName, conditions) => {
  const whereClause = Object.keys(conditions)
    .map((key, index) => `${key} = $${index + 1}`)
    .join(' AND ');
  
  const query = `SELECT EXISTS(SELECT 1 FROM ${tableName} WHERE ${whereClause})`;
  const params = Object.values(conditions);
  
  const result = await executeTestQuery(query, params);
  return result.rows[0].exists;
};

/**
 * ============================================
 * Redis助手
 * ============================================
 */

/**
 * 设置测试缓存数据
 */
const setTestCache = async (key, value, ttl = 3600) => {
  const redis = await createTestRedisClient();
  
  if (typeof value === 'object') {
    value = JSON.stringify(value);
  }
  
  if (ttl) {
    await redis.setex(key, ttl, value);
  } else {
    await redis.set(key, value);
  }
};

/**
 * 获取测试缓存数据
 */
const getTestCache = async (key) => {
  const redis = await createTestRedisClient();
  const value = await redis.get(key);
  
  if (!value) {
    return null;
  }
  
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
};

/**
 * 删除测试缓存数据
 */
const deleteTestCache = async (key) => {
  const redis = await createTestRedisClient();
  await redis.del(key);
};

module.exports = {
  // 数据库管理
  setupTestDB,
  cleanupTestDB,
  createTestDbPool,
  createTestRedisClient,
  
  // 数据管理
  cleanupTestData,
  insertTestData,
  insertBasicTestData,
  
  // 查询助手
  executeTestQuery,
  getTableCount,
  recordExists,
  
  // 缓存助手
  setTestCache,
  getTestCache,
  deleteTestCache,
  
  // 配置导出
  TEST_DB_CONFIG,
  TEST_REDIS_CONFIG
};
