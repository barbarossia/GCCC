/**
 * GCCC 日志工具类
 * 
 * 基于Winston的统一日志记录系统，支持多种输出格式和传输方式
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const winston = require('winston');
const path = require('path');
const fs = require('fs');

/**
 * ============================================
 * 日志配置
 * ============================================
 */

// 确保日志目录存在
const LOG_DIR = process.env.LOG_DIR || path.join(process.cwd(), 'logs');
if (!fs.existsSync(LOG_DIR)) {
  fs.mkdirSync(LOG_DIR, { recursive: true });
}

// 日志级别配置
const LOG_LEVELS = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  verbose: 4,
  debug: 5,
  silly: 6
};

// 日志颜色配置
const LOG_COLORS = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  verbose: 'cyan',
  debug: 'blue',
  silly: 'grey'
};

winston.addColors(LOG_COLORS);

/**
 * ============================================
 * 自定义格式化器
 * ============================================
 */

/**
 * 开发环境格式化器
 */
const developmentFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.colorize({ all: true }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let log = `${timestamp} [${level}]: ${message}`;
    
    // 添加元数据
    if (Object.keys(meta).length > 0) {
      log += `\n${JSON.stringify(meta, null, 2)}`;
    }
    
    return log;
  })
);

/**
 * 生产环境格式化器
 */
const productionFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf((info) => {
    // 确保敏感信息不被记录
    const sanitized = sanitizeLogData(info);
    return JSON.stringify(sanitized);
  })
);

/**
 * 文件格式化器
 */
const fileFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

/**
 * ============================================
 * 传输配置
 * ============================================
 */

/**
 * 控制台传输配置
 */
const consoleTransport = new winston.transports.Console({
  level: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'development' ? 'debug' : 'info'),
  format: process.env.NODE_ENV === 'development' ? developmentFormat : productionFormat,
  handleExceptions: true,
  handleRejections: true
});

/**
 * 文件传输配置
 */
const fileTransports = [
  // 应用程序日志
  new winston.transports.File({
    filename: path.join(LOG_DIR, 'app.log'),
    level: 'info',
    format: fileFormat,
    maxsize: 10 * 1024 * 1024, // 10MB
    maxFiles: 10,
    tailable: true
  }),
  
  // 错误日志
  new winston.transports.File({
    filename: path.join(LOG_DIR, 'error.log'),
    level: 'error',
    format: fileFormat,
    maxsize: 10 * 1024 * 1024, // 10MB
    maxFiles: 5,
    tailable: true
  }),
  
  // HTTP请求日志
  new winston.transports.File({
    filename: path.join(LOG_DIR, 'access.log'),
    level: 'http',
    format: fileFormat,
    maxsize: 20 * 1024 * 1024, // 20MB
    maxFiles: 15,
    tailable: true
  }),
  
  // 调试日志（仅开发环境）
  ...(process.env.NODE_ENV === 'development' ? [
    new winston.transports.File({
      filename: path.join(LOG_DIR, 'debug.log'),
      level: 'debug',
      format: fileFormat,
      maxsize: 50 * 1024 * 1024, // 50MB
      maxFiles: 3,
      tailable: true
    })
  ] : [])
];

/**
 * ============================================
 * Logger实例创建
 * ============================================
 */

/**
 * 主Logger实例
 */
const logger = winston.createLogger({
  levels: LOG_LEVELS,
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.metadata({ fillExcept: ['message', 'level', 'timestamp'] })
  ),
  defaultMeta: {
    service: 'gccc-backend',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    instance: process.env.INSTANCE_ID || 'default'
  },
  transports: [consoleTransport, ...fileTransports],
  exitOnError: false
});

/**
 * ============================================
 * 敏感数据清理
 * ============================================
 */

/**
 * 敏感字段列表
 */
const SENSITIVE_FIELDS = [
  'password',
  'token',
  'secret',
  'key',
  'authorization',
  'cookie',
  'session',
  'private_key',
  'mnemonic',
  'seed',
  'signature',
  'access_token',
  'refresh_token',
  'api_key',
  'auth_token',
  'jwt',
  'bearer'
];

/**
 * 清理敏感数据
 * @param {any} data 要清理的数据
 * @returns {any} 清理后的数据
 */
const sanitizeLogData = (data) => {
  if (!data || typeof data !== 'object') {
    return data;
  }
  
  if (Array.isArray(data)) {
    return data.map(item => sanitizeLogData(item));
  }
  
  const sanitized = {};
  
  for (const [key, value] of Object.entries(data)) {
    const lowerKey = key.toLowerCase();
    
    // 检查是否为敏感字段
    if (SENSITIVE_FIELDS.some(field => lowerKey.includes(field))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitizeLogData(value);
    } else {
      sanitized[key] = value;
    }
  }
  
  return sanitized;
};

/**
 * ============================================
 * 特殊用途Logger
 * ============================================
 */

/**
 * 审计日志Logger
 */
const auditLogger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'gccc-audit',
    type: 'audit'
  },
  transports: [
    new winston.transports.File({
      filename: path.join(LOG_DIR, 'audit.log'),
      maxsize: 50 * 1024 * 1024, // 50MB
      maxFiles: 30,
      tailable: true
    })
  ]
});

/**
 * 安全日志Logger
 */
const securityLogger = winston.createLogger({
  level: 'warn',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'gccc-security',
    type: 'security'
  },
  transports: [
    new winston.transports.File({
      filename: path.join(LOG_DIR, 'security.log'),
      maxsize: 20 * 1024 * 1024, // 20MB
      maxFiles: 20,
      tailable: true
    }),
    // 安全事件也输出到控制台
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

/**
 * 性能日志Logger
 */
const performanceLogger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'gccc-performance',
    type: 'performance'
  },
  transports: [
    new winston.transports.File({
      filename: path.join(LOG_DIR, 'performance.log'),
      maxsize: 30 * 1024 * 1024, // 30MB
      maxFiles: 10,
      tailable: true
    })
  ]
});

/**
 * ============================================
 * 增强功能
 * ============================================
 */

/**
 * 记录API请求
 * @param {Object} req Express请求对象
 * @param {Object} res Express响应对象
 * @param {number} duration 请求处理时间（毫秒）
 */
const logRequest = (req, res, duration) => {
  const logData = {
    method: req.method,
    url: req.url,
    path: req.path,
    status: res.statusCode,
    duration: `${duration}ms`,
    user_agent: req.get('User-Agent'),
    ip: req.ip,
    user_id: req.user?.id,
    session_id: req.session?.id,
    request_id: req.id
  };
  
  // 根据状态码选择日志级别
  if (res.statusCode >= 500) {
    logger.error('API Request', logData);
  } else if (res.statusCode >= 400) {
    logger.warn('API Request', logData);
  } else {
    logger.http('API Request', logData);
  }
};

/**
 * 记录错误详情
 * @param {Error} error 错误对象
 * @param {Object} context 错误上下文
 */
const logError = (error, context = {}) => {
  const errorData = {
    error_name: error.name,
    error_message: error.message,
    error_code: error.code,
    error_stack: error.stack,
    ...sanitizeLogData(context)
  };
  
  logger.error('Application Error', errorData);
};

/**
 * 记录审计事件
 * @param {string} action 操作类型
 * @param {Object} details 操作详情
 * @param {Object} actor 操作者信息
 */
const logAudit = (action, details = {}, actor = {}) => {
  const auditData = {
    action,
    details: sanitizeLogData(details),
    actor: {
      user_id: actor.user_id,
      username: actor.username,
      ip: actor.ip,
      user_agent: actor.user_agent
    },
    timestamp: new Date().toISOString()
  };
  
  auditLogger.info('Audit Event', auditData);
};

/**
 * 记录安全事件
 * @param {string} event 安全事件类型
 * @param {Object} details 事件详情
 * @param {string} severity 严重程度
 */
const logSecurity = (event, details = {}, severity = 'warn') => {
  const securityData = {
    event,
    severity,
    details: sanitizeLogData(details),
    timestamp: new Date().toISOString()
  };
  
  securityLogger[severity]('Security Event', securityData);
};

/**
 * 记录性能数据
 * @param {string} operation 操作名称
 * @param {number} duration 执行时间
 * @param {Object} metadata 额外元数据
 */
const logPerformance = (operation, duration, metadata = {}) => {
  const performanceData = {
    operation,
    duration: `${duration}ms`,
    metadata,
    timestamp: new Date().toISOString()
  };
  
  performanceLogger.info('Performance Metric', performanceData);
};

/**
 * ============================================
 * 中间件支持
 * ============================================
 */

/**
 * 请求日志中间件
 */
const requestLogger = (req, res, next) => {
  const startTime = Date.now();
  
  // 生成请求ID
  req.id = req.get('X-Request-ID') || require('crypto').randomUUID();
  
  // 监听响应结束事件
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    logRequest(req, res, duration);
  });
  
  next();
};

/**
 * 错误日志中间件
 */
const errorLogger = (error, req, res, next) => {
  const context = {
    method: req.method,
    url: req.url,
    user_id: req.user?.id,
    session_id: req.session?.id,
    request_id: req.id,
    ip: req.ip,
    user_agent: req.get('User-Agent'),
    body: req.body,
    params: req.params,
    query: req.query
  };
  
  logError(error, context);
  next(error);
};

/**
 * ============================================
 * 工具函数
 * ============================================
 */

/**
 * 创建子Logger
 * @param {string} module 模块名称
 * @param {Object} defaultMeta 默认元数据
 * @returns {winston.Logger} 子Logger实例
 */
const createChildLogger = (module, defaultMeta = {}) => {
  return logger.child({
    module,
    ...defaultMeta
  });
};

/**
 * 设置日志级别
 * @param {string} level 日志级别
 */
const setLogLevel = (level) => {
  logger.level = level;
  logger.info('Log level changed', { new_level: level });
};

/**
 * 获取当前日志级别
 * @returns {string} 当前日志级别
 */
const getLogLevel = () => {
  return logger.level;
};

/**
 * 清理旧日志文件
 * @param {number} daysToKeep 保留天数
 */
const cleanupOldLogs = (daysToKeep = 30) => {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
  
  try {
    const files = fs.readdirSync(LOG_DIR);
    
    files.forEach(file => {
      const filePath = path.join(LOG_DIR, file);
      const stats = fs.statSync(filePath);
      
      if (stats.mtime < cutoffDate && file.endsWith('.log')) {
        fs.unlinkSync(filePath);
        logger.info('Old log file deleted', { file });
      }
    });
  } catch (error) {
    logger.error('Failed to cleanup old logs', { error: error.message });
  }
};

module.exports = {
  // 主Logger
  logger,
  
  // 特殊用途Logger
  auditLogger,
  securityLogger,
  performanceLogger,
  
  // 日志记录函数
  logRequest,
  logError,
  logAudit,
  logSecurity,
  logPerformance,
  
  // 中间件
  requestLogger,
  errorLogger,
  
  // 工具函数
  createChildLogger,
  setLogLevel,
  getLogLevel,
  cleanupOldLogs,
  sanitizeLogData,
  
  // 导出默认logger的方法以便直接使用
  info: logger.info.bind(logger),
  warn: logger.warn.bind(logger),
  error: logger.error.bind(logger),
  debug: logger.debug.bind(logger),
  verbose: logger.verbose.bind(logger),
  silly: logger.silly.bind(logger)
};
