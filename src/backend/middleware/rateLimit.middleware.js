/**
 * 限流中间件
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const logger = require('../utils/logger');

/**
 * 创建限流中间件
 * @param {Object} options - 限流配置选项
 * @returns {Function} Express中间件函数
 */
const createRateLimit = (options = {}) => {
  const defaultOptions = {
    windowMs: 15 * 60 * 1000, // 15分钟
    max: 100, // 最大请求数
    message: '请求过于频繁，请稍后再试',
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => {
      // 跳过健康检查端点
      return req.path === '/health' || req.path === '/api/health';
    },
    onLimitReached: (req, res, options) => {
      logger.warn('请求限制触发:', {
        ip: req.ip,
        path: req.path,
        method: req.method,
        userAgent: req.get('User-Agent'),
      });
    },
  };

  return rateLimit({ ...defaultOptions, ...options });
};

/**
 * 创建慢响应中间件
 * @param {Object} options - 慢响应配置选项
 * @returns {Function} Express中间件函数
 */
const createSlowDown = (options = {}) => {
  const defaultOptions = {
    windowMs: 15 * 60 * 1000, // 15分钟
    delayAfter: 50, // 超过50个请求后开始延迟
    delayMs: () => 500, // 每个请求延迟500ms
    maxDelayMs: 5000, // 最大延迟5秒
    skip: (req) => {
      // 跳过健康检查端点
      return req.path === '/health' || req.path === '/api/health';
    },
  };

  return slowDown({ ...defaultOptions, ...options });
};

// 预定义的限流中间件
const generalLimiter = createRateLimit({
  max: 100, // 每15分钟100个请求
});

const strictLimiter = createRateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20, // 每15分钟20个请求（用于敏感操作）
});

const authLimiter = createRateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 每15分钟5次登录尝试
  message: '登录尝试次数过多，请稍后再试',
  skipSuccessfulRequests: true,
});

module.exports = {
  createRateLimit,
  createSlowDown,
  generalLimiter,
  strictLimiter,
  authLimiter,
};
