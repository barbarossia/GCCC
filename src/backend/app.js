/**
 * GCCC 后端服务主应用文件
 * 
 * 本文件是Express应用的核心配置，包含：
 * - 中间件配置
 * - 路由设置
 * - 错误处理
 * - 安全配置
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');

// 导入配置
const config = require('./config');

// 导入中间件
const authMiddleware = require('./middleware/auth.middleware');
const permissionMiddleware = require('./middleware/permission.middleware');
const validationMiddleware = require('./middleware/validation.middleware');
const rateLimitMiddleware = require('./middleware/rateLimit.middleware');
const errorMiddleware = require('./middleware/error.middleware');
const loggingMiddleware = require('./middleware/logging.middleware');
const corsMiddleware = require('./middleware/cors.middleware');

// 导入工具
const logger = require('./utils/logger');
const { APIError } = require('./utils/errors');

// 导入API路由
const apiRoutes = require('./api');

/**
 * 创建Express应用实例
 */
const app = express();

/**
 * 信任代理设置（用于生产环境的负载均衡器）
 */
app.set('trust proxy', 1);

/**
 * 视图引擎设置（如果需要服务端渲染）
 */
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

/**
 * ============================================
 * 全局中间件配置
 * ============================================
 */

/**
 * 安全中间件 - 必须在其他中间件之前
 */
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https:"],
      scriptSrc: ["'self'", "https:"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https:", "wss:"],
      fontSrc: ["'self'", "https:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"]
    }
  },
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

/**
 * CORS跨域配置
 */
app.use(corsMiddleware);

/**
 * 请求日志中间件
 */
if (config.server.nodeEnv !== 'test') {
  app.use(morgan('combined', {
    stream: {
      write: (message) => logger.info(message.trim())
    }
  }));
}

/**
 * 请求体解析中间件
 */
app.use(express.json({ 
  limit: config.api.maxRequestSize,
  strict: true
}));
app.use(express.urlencoded({ 
  extended: true, 
  limit: config.api.maxRequestSize 
}));

/**
 * Gzip压缩中间件
 */
app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  },
  level: 6,
  threshold: 1024
}));

/**
 * 静态文件服务
 */
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/public', express.static(path.join(__dirname, 'public')));

/**
 * 请求日志和追踪中间件
 */
app.use(loggingMiddleware);

/**
 * 频率限制中间件
 */
app.use(rateLimitMiddleware.global);

/**
 * ============================================
 * 健康检查和监控端点
 * ============================================
 */

/**
 * 健康检查端点
 */
app.get('/health', async (req, res) => {
  try {
    const healthData = await require('./services/health.service').getHealthStatus();
    res.json({
      success: true,
      data: healthData,
      message: 'Service is healthy'
    });
  } catch (error) {
    logger.error('Health check failed:', error);
    res.status(503).json({
      success: false,
      error: {
        code: 'HEALTH_CHECK_FAILED',
        message: 'Service is unhealthy'
      }
    });
  }
});

/**
 * 服务信息端点
 */
app.get('/info', (req, res) => {
  res.json({
    success: true,
    data: {
      name: 'GCCC Backend Service',
      version: process.env.npm_package_version || '1.0.0',
      environment: config.server.nodeEnv,
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      node_version: process.version,
      platform: process.platform,
      arch: process.arch
    },
    message: 'Service information'
  });
});

/**
 * 指标端点（用于监控）
 */
if (config.monitoring.metricsEnabled) {
  app.get('/metrics', require('./middleware/metrics.middleware'));
}

/**
 * ============================================
 * API路由配置
 * ============================================
 */

/**
 * API版本路由
 */
app.use(`${config.api.prefix}/${config.api.version}`, apiRoutes);

/**
 * API文档路由（开发和预发布环境）
 */
if (config.server.nodeEnv !== 'production') {
  const swaggerUi = require('swagger-ui-express');
  const swaggerSpec = require('./docs/swagger.config');
  
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    explorer: true,
    swaggerOptions: {
      persistAuthorization: true,
      displayRequestDuration: true
    },
    customCss: '.swagger-ui .topbar { display: none }'
  }));
  
  // API文档重定向
  app.get('/docs', (req, res) => {
    res.redirect('/api-docs');
  });
}

/**
 * 根路径处理
 */
app.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      service: 'GCCC Backend API',
      version: process.env.npm_package_version || '1.0.0',
      documentation: config.server.nodeEnv !== 'production' ? '/api-docs' : null,
      health: '/health',
      info: '/info'
    },
    message: 'Welcome to GCCC Backend Service'
  });
});

/**
 * ============================================
 * 错误处理
 * ============================================
 */

/**
 * 404错误处理 - 必须在所有路由之后
 */
app.use('*', (req, res, next) => {
  const error = new APIError(
    `Route ${req.method} ${req.originalUrl} not found`,
    404,
    'ROUTE_NOT_FOUND'
  );
  next(error);
});

/**
 * 全局错误处理中间件 - 必须在最后
 */
app.use(errorMiddleware);

/**
 * ============================================
 * 优雅关闭处理
 * ============================================
 */

/**
 * 处理未捕获的Promise拒绝
 */
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', {
    promise,
    reason: reason.stack || reason
  });
  // 在生产环境中，应该优雅地关闭应用
  if (config.server.nodeEnv === 'production') {
    process.exit(1);
  }
});

/**
 * 处理未捕获的异常
 */
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', {
    error: error.message,
    stack: error.stack
  });
  // 在生产环境中，应该优雅地关闭应用
  if (config.server.nodeEnv === 'production') {
    process.exit(1);
  }
});

/**
 * 优雅关闭信号处理
 */
const gracefulShutdown = (signal) => {
  logger.info(`Received ${signal}. Starting graceful shutdown...`);
  
  // 停止接受新连接
  server.close((err) => {
    if (err) {
      logger.error('Error during graceful shutdown:', err);
      process.exit(1);
    }
    
    logger.info('Server closed successfully');
    
    // 关闭数据库连接
    const dbService = require('./services/database');
    dbService.close();
    
    // 关闭Redis连接
    const redisService = require('./services/cache/redis.service');
    redisService.close();
    
    logger.info('Graceful shutdown completed');
    process.exit(0);
  });
  
  // 强制关闭超时
  setTimeout(() => {
    logger.error('Graceful shutdown timeout, forcing exit');
    process.exit(1);
  }, config.server.gracefulShutdownTimeout || 30000);
};

// 注册信号处理器
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

/**
 * ============================================
 * 启动信息
 * ============================================
 */

/**
 * 应用启动时的信息输出
 */
app.on('ready', () => {
  logger.info('GCCC Backend Service initialized', {
    environment: config.server.nodeEnv,
    version: process.env.npm_package_version || '1.0.0',
    nodeVersion: process.version,
    platform: process.platform,
    pid: process.pid
  });
});

module.exports = app;
