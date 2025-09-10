/**
 * 日志记录中间件
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const logger = require('../utils/logger');

/**
 * 请求日志中间件
 * @param {Object} req - Express request对象
 * @param {Object} res - Express response对象
 * @param {Function} next - Next函数
 */
const requestLogger = (req, res, next) => {
  const startTime = Date.now();

  // 记录请求信息
  logger.info('请求开始:', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    contentType: req.get('Content-Type'),
    contentLength: req.get('Content-Length'),
  });

  // 拦截响应结束事件
  const originalEnd = res.end;
  res.end = function (chunk, encoding) {
    const duration = Date.now() - startTime;

    // 记录响应信息
    logger.info('请求完成:', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      contentLength: res.get('Content-Length') || 0,
    });

    // 调用原始的end方法
    originalEnd.call(this, chunk, encoding);
  };

  next();
};

/**
 * 安全日志中间件（记录敏感操作）
 * @param {Object} req - Express request对象
 * @param {Object} res - Express response对象
 * @param {Function} next - Next函数
 */
const securityLogger = (req, res, next) => {
  // 记录敏感操作
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    logger.warn('敏感操作记录:', {
      method: req.method,
      path: req.path,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      userId: req.user ? req.user.id : 'anonymous',
      timestamp: new Date().toISOString(),
    });
  }

  next();
};

module.exports = {
  requestLogger,
  securityLogger,
};
