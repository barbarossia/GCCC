/**
 * 数据库连接服务
 *
 * 本模块负责：
 * - PostgreSQL数据库连接管理
 * - 连接池配置
 * - 数据库健康检查
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const { Pool } = require('pg');
const logger = require('../utils/logger');

// 数据库连接配置
const config = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'gccc_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',

  // 连接池配置
  max: parseInt(process.env.DB_MAX_CONNECTIONS) || 20,
  idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT) || 30000,
  connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT) || 2000,

  // SSL 配置
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
};

// 创建连接池
const pool = new Pool(config);

// 错误处理
pool.on('error', (err) => {
  logger.error('Unexpected error on idle client', err);
  process.exit(-1);
});

/**
 * 测试数据库连接
 * @returns {Promise<boolean>}
 */
async function testConnection() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();

    logger.info('Database connection successful');
    logger.info('Server time:', result.rows[0].now);
    return true;
  } catch (error) {
    logger.error('Database connection failed:', error.message);
    return false;
  }
}

/**
 * 关闭数据库连接池
 * @returns {Promise<void>}
 */
async function closeConnection() {
  try {
    await pool.end();
    logger.info('Database connection pool closed');
  } catch (error) {
    logger.error('Error closing database connection pool:', error.message);
  }
}

/**
 * 获取数据库客户端
 * @returns {Promise<Object>}
 */
async function getClient() {
  try {
    return await pool.connect();
  } catch (error) {
    logger.error('Error getting database client:', error.message);
    throw error;
  }
}

/**
 * 执行查询
 * @param {string} text - SQL查询语句
 * @param {Array} params - 查询参数
 * @returns {Promise<Object>}
 */
async function query(text, params = []) {
  try {
    const result = await pool.query(text, params);
    return result;
  } catch (error) {
    logger.error('Database query error:', error.message);
    logger.error('Query:', text);
    logger.error('Params:', params);
    throw error;
  }
}

/**
 * 开启事务
 * @param {Function} callback - 事务回调函数
 * @returns {Promise<any>}
 */
async function transaction(callback) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error('Transaction error:', error.message);
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  pool,
  testConnection,
  closeConnection,
  getClient,
  query,
  transaction,
};
