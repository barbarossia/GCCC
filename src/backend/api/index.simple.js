/**
 * 简化版 API路由入口文件 - 用于调试
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const express = require('express');
const router = express.Router();

// 导入工具
const logger = require('../utils/logger');

/**
 * API根路由
 */
router.get('/', (req, res) => {
  res.json({
    message: 'GCCC API Server',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

/**
 * 健康检查路由
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

/**
 * 认证相关路由 - 基础版
 */
router.post('/auth/login', (req, res) => {
  res.json({
    message: '登录功能待实现',
    status: 'not_implemented',
  });
});

router.post('/auth/register', (req, res) => {
  res.json({
    message: '注册功能待实现',
    status: 'not_implemented',
  });
});

/**
 * 用户相关路由 - 基础版
 */
router.get('/users/profile', (req, res) => {
  res.json({
    message: '用户资料功能待实现',
    status: 'not_implemented',
  });
});

logger.info('API routes initialized (simplified version)');

module.exports = router;
