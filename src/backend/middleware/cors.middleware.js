/**
 * CORS中间件配置
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const cors = require('cors');
const config = require('../config');
const logger = require('../utils/logger');

/**
 * CORS配置选项
 */
const corsOptions = {
  // 允许的源
  origin: (origin, callback) => {
    // 在开发环境中允许所有源
    if (config.isDevelopment) {
      return callback(null, true);
    }

    // 生产环境中只允许配置的源
    const allowedOrigins = config.api.cors.allowedOrigins || [];

    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      logger.warn('CORS blocked origin:', origin);
      callback(new Error('Not allowed by CORS'), false);
    }
  },

  // 允许的HTTP方法
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],

  // 允许的请求头
  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Content-Type',
    'Accept',
    'Authorization',
    'X-API-Key',
    'X-Client-Version',
    'X-Request-ID',
  ],

  // 暴露的响应头
  exposedHeaders: [
    'X-RateLimit-Limit',
    'X-RateLimit-Remaining',
    'X-RateLimit-Reset',
    'X-Response-Time',
  ],

  // 是否允许发送cookies
  credentials: true,

  // 预检请求缓存时间（秒）
  maxAge: 86400, // 24小时

  // 是否允许预检请求
  preflightContinue: false,

  // 预检请求成功状态码
  optionsSuccessStatus: 200,
};

/**
 * 创建CORS中间件
 */
const corsMiddleware = cors(corsOptions);

module.exports = corsMiddleware;
