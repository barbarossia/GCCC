/**
 * GCCC 后端服务启动文件
 * 
 * 本文件负责：
 * - 加载环境变量
 * - 初始化数据库连接
 * - 启动HTTP服务器
 * - 初始化定时任务
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

require('dotenv').config();

const http = require('http');
const cluster = require('cluster');
const os = require('os');

// 导入应用和配置
const app = require('./app');
const config = require('./config');
const logger = require('./utils/logger');

// 导入服务
const databaseService = require('./services/database');
const redisService = require('./services/cache/redis.service');
const cronService = require('./services/cron.service');

/**
 * ============================================
 * 环境变量验证
 * ============================================
 */

const requiredEnvVars = [
  'NODE_ENV',
  'PORT',
  'JWT_SECRET',
  'DB_HOST',
  'DB_PORT',
  'DB_NAME',
  'DB_USER',
  'DB_PASSWORD'
];

const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  logger.error('Missing required environment variables:', missingEnvVars);
  process.exit(1);
}

/**
 * ============================================
 * 集群模式配置
 * ============================================
 */

const shouldUseCluster = config.server.clusterMode && config.server.nodeEnv === 'production';
const numCPUs = config.server.clusterWorkers === 'auto' ? os.cpus().length : config.server.clusterWorkers;

if (shouldUseCluster && cluster.isMaster) {
  logger.info(`Master ${process.pid} is running`);
  logger.info(`Starting ${numCPUs} worker processes`);

  // 创建工作进程
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  // 监听工作进程事件
  cluster.on('online', (worker) => {
    logger.info(`Worker ${worker.process.pid} is online`);
  });

  cluster.on('exit', (worker, code, signal) => {
    logger.error(`Worker ${worker.process.pid} died with code ${code} and signal ${signal}`);
    logger.info('Starting a new worker');
    cluster.fork();
  });

  // 优雅关闭主进程
  process.on('SIGTERM', () => {
    logger.info('Master received SIGTERM, shutting down workers');
    for (const id in cluster.workers) {
      cluster.workers[id].kill();
    }
  });

} else {
  // 单进程模式或工作进程
  startServer();
}

/**
 * ============================================
 * 服务器启动函数
 * ============================================
 */

async function startServer() {
  try {
    // 初始化服务
    await initializeServices();

    // 创建HTTP服务器
    const server = createHttpServer();

    // 启动服务器
    await startHttpServer(server);

    // 初始化定时任务
    initializeCronJobs();

    // 发送就绪信号
    app.emit('ready');

    // 保存服务器实例到全局（用于优雅关闭）
    global.server = server;

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

/**
 * ============================================
 * 服务初始化
 * ============================================
 */

async function initializeServices() {
  logger.info('Initializing services...');

  try {
    // 初始化数据库连接
    logger.info('Connecting to database...');
    await databaseService.initialize();
    logger.info('Database connected successfully');

    // 初始化Redis连接
    logger.info('Connecting to Redis...');
    await redisService.initialize();
    logger.info('Redis connected successfully');

    // 初始化区块链服务
    if (config.blockchain.enabled) {
      logger.info('Initializing blockchain service...');
      const blockchainService = require('./services/blockchain');
      await blockchainService.initialize();
      logger.info('Blockchain service initialized');
    }

    // 初始化外部服务
    logger.info('Initializing external services...');
    await initializeExternalServices();
    logger.info('External services initialized');

    // 运行数据库迁移（如果需要）
    if (config.database.autoMigrate) {
      logger.info('Running database migrations...');
      await databaseService.runMigrations();
      logger.info('Database migrations completed');
    }

    logger.info('All services initialized successfully');

  } catch (error) {
    logger.error('Service initialization failed:', error);
    throw error;
  }
}

/**
 * 初始化外部服务
 */
async function initializeExternalServices() {
  const promises = [];

  // 初始化邮件服务
  if (config.email.enabled) {
    const emailService = require('./services/external/email.service');
    promises.push(emailService.initialize());
  }

  // 初始化IPFS服务
  if (config.ipfs.enabled) {
    const ipfsService = require('./services/external/ipfs.service');
    promises.push(ipfsService.initialize());
  }

  // 初始化监控服务
  if (config.monitoring.sentryEnabled) {
    const Sentry = require('@sentry/node');
    Sentry.init({
      dsn: config.monitoring.sentryDsn,
      environment: config.server.nodeEnv,
      sampleRate: config.monitoring.sentrySampleRate,
      tracesSampleRate: config.monitoring.sentryTracesSampleRate
    });
  }

  await Promise.all(promises);
}

/**
 * ============================================
 * HTTP服务器创建和配置
 * ============================================
 */

function createHttpServer() {
  // 创建HTTP服务器
  const server = http.createServer(app);

  // 设置服务器超时
  server.keepAliveTimeout = config.server.keepAliveTimeout || 65000;
  server.headersTimeout = config.server.headersTimeout || 66000;

  // 服务器事件监听
  server.on('error', onError);
  server.on('listening', onListening);

  // 连接事件
  server.on('connection', (socket) => {
    socket.on('error', (err) => {
      logger.error('Socket error:', err);
    });
  });

  return server;
}

/**
 * 启动HTTP服务器
 */
function startHttpServer(server) {
  return new Promise((resolve, reject) => {
    const port = normalizePort(config.server.port);
    const host = config.server.host;

    app.set('port', port);

    server.listen(port, host, (error) => {
      if (error) {
        reject(error);
      } else {
        resolve();
      }
    });
  });
}

/**
 * ============================================
 * 定时任务初始化
 * ============================================
 */

function initializeCronJobs() {
  if (!config.cron.enabled) {
    logger.info('Cron jobs are disabled');
    return;
  }

  logger.info('Initializing cron jobs...');

  try {
    cronService.initialize();
    logger.info('Cron jobs initialized successfully');
  } catch (error) {
    logger.error('Failed to initialize cron jobs:', error);
  }
}

/**
 * ============================================
 * 工具函数
 * ============================================
 */

/**
 * 规范化端口号
 */
function normalizePort(val) {
  const port = parseInt(val, 10);

  if (isNaN(port)) {
    return val;
  }

  if (port >= 0) {
    return port;
  }

  return false;
}

/**
 * HTTP服务器错误处理
 */
function onError(error) {
  if (error.syscall !== 'listen') {
    throw error;
  }

  const port = config.server.port;
  const bind = typeof port === 'string' ? 'Pipe ' + port : 'Port ' + port;

  switch (error.code) {
    case 'EACCES':
      logger.error(`${bind} requires elevated privileges`);
      process.exit(1);
      break;
    case 'EADDRINUSE':
      logger.error(`${bind} is already in use`);
      process.exit(1);
      break;
    default:
      throw error;
  }
}

/**
 * HTTP服务器监听事件处理
 */
function onListening() {
  const server = global.server || this;
  const addr = server.address();
  const bind = typeof addr === 'string' ? 'pipe ' + addr : 'port ' + addr.port;
  
  logger.info('Server listening on ' + bind, {
    environment: config.server.nodeEnv,
    pid: process.pid,
    clustered: shouldUseCluster,
    workerId: cluster.worker ? cluster.worker.id : 'master'
  });

  // 在开发环境显示有用的信息
  if (config.server.nodeEnv === 'development') {
    const baseUrl = `http://${config.server.host}:${config.server.port}`;
    
    console.log('\n='.repeat(50));
    console.log('🚀 GCCC Backend Service Started Successfully!');
    console.log('='.repeat(50));
    console.log(`🌐 Server URL: ${baseUrl}`);
    console.log(`📚 API Docs: ${baseUrl}/api-docs`);
    console.log(`❤️  Health Check: ${baseUrl}/health`);
    console.log(`ℹ️  Service Info: ${baseUrl}/info`);
    console.log(`📝 Environment: ${config.server.nodeEnv}`);
    console.log(`🆔 Process ID: ${process.pid}`);
    console.log('='.repeat(50));
    console.log('Ready to accept connections! 🎉\n');
  }
}

/**
 * ============================================
 * 进程信号处理
 * ============================================
 */

// 处理PM2的优雅重启信号
process.on('message', (msg) => {
  if (msg === 'shutdown') {
    logger.info('Received shutdown message from PM2');
    gracefulShutdown();
  }
});

// 优雅关闭函数
function gracefulShutdown() {
  logger.info('Starting graceful shutdown...');

  const server = global.server;
  if (!server) {
    process.exit(0);
    return;
  }

  // 停止接受新连接
  server.close(async (err) => {
    if (err) {
      logger.error('Error during server close:', err);
      process.exit(1);
      return;
    }

    try {
      // 停止定时任务
      if (config.cron.enabled) {
        cronService.stop();
        logger.info('Cron jobs stopped');
      }

      // 关闭数据库连接
      await databaseService.close();
      logger.info('Database connections closed');

      // 关闭Redis连接
      await redisService.close();
      logger.info('Redis connections closed');

      logger.info('Graceful shutdown completed successfully');
      process.exit(0);

    } catch (shutdownError) {
      logger.error('Error during graceful shutdown:', shutdownError);
      process.exit(1);
    }
  });

  // 强制退出超时
  setTimeout(() => {
    logger.error('Graceful shutdown timeout, forcing exit');
    process.exit(1);
  }, config.server.gracefulShutdownTimeout || 30000);
}

// 在非集群模式下导出服务器启动函数
if (!shouldUseCluster || !cluster.isMaster) {
  module.exports = {
    startServer,
    gracefulShutdown
  };
}
