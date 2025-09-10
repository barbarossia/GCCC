/**
 * 错误处理中间件
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const logger = require('../utils/logger');
const { createErrorResponse } = require('../utils/response');

/**
 * 全局错误处理中间件
 * @param {Error} err - 错误对象
 * @param {Object} req - Express request对象
 * @param {Object} res - Express response对象
 * @param {Function} next - Next函数
 */
const errorHandler = (err, req, res, next) => {
  // 记录错误
  logger.error('服务器错误:', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    body: req.body,
    params: req.params,
    query: req.query,
  });

  // 处理不同类型的错误
  let status = 500;
  let message = '服务器内部错误';
  let code = 'INTERNAL_ERROR';

  // 数据库错误
  if (err.code === '23505') {
    status = 409;
    message = '数据已存在';
    code = 'DUPLICATE_ERROR';
  } else if (err.code === '23503') {
    status = 400;
    message = '外键约束错误';
    code = 'FOREIGN_KEY_ERROR';
  } else if (err.code === '23502') {
    status = 400;
    message = '必填字段缺失';
    code = 'NOT_NULL_ERROR';
  }

  // JWT错误
  else if (err.name === 'JsonWebTokenError') {
    status = 401;
    message = '无效的访问令牌';
    code = 'INVALID_TOKEN';
  } else if (err.name === 'TokenExpiredError') {
    status = 401;
    message = '访问令牌已过期';
    code = 'TOKEN_EXPIRED';
  }

  // 验证错误
  else if (err.name === 'ValidationError') {
    status = 400;
    message = '数据验证失败';
    code = 'VALIDATION_ERROR';
  }

  // 语法错误
  else if (err instanceof SyntaxError) {
    status = 400;
    message = '请求格式错误';
    code = 'SYNTAX_ERROR';
  }

  // 返回错误响应
  return res.status(status).json(createErrorResponse(message, code));
};

/**
 * 404错误处理中间件
 * @param {Object} req - Express request对象
 * @param {Object} res - Express response对象
 * @param {Function} next - Next函数
 */
const notFoundHandler = (req, res, next) => {
  logger.warn('404 - 资源未找到:', {
    path: req.path,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
  });

  return res.status(404).json(createErrorResponse('资源未找到', 'NOT_FOUND'));
};

/**
 * 异步错误处理包装器
 * @param {Function} fn - 异步函数
 * @returns {Function} Express中间件函数
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = {
  errorHandler,
  notFoundHandler,
  asyncHandler,
};
