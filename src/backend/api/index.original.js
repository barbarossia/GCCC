/**
 * GCCC API路由入口文件
 * 
 * 统一管理所有API模块的路由
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const express = require('express');
const router = express.Router();

// 导入中间件
const authMiddleware = require('../middleware/auth.middleware');
const permissionMiddleware = require('../middleware/permission.middleware');
const rateLimitMiddleware = require('../middleware/rateLimit.middleware');

// 导入各模块路由
const authRoutes = require('./auth/auth.routes');
const userRoutes = require('./user/user.routes');
const adminRoutes = require('./admin/admin.routes');
const pointsRoutes = require('./points/points.routes');
const proposalsRoutes = require('./proposals/proposals.routes');
const stakingRoutes = require('./staking/staking.routes');
const lotteryRoutes = require('./lottery/lottery.routes');
const nftRoutes = require('./nft/nft.routes');

// 导入工具
const logger = require('../utils/logger');

/**
 * ============================================
 * 公开路由（无需认证）
 * ============================================
 */

// 认证路由
router.use('/auth', rateLimitMiddleware.auth, authRoutes);

/**
 * ============================================
 * 受保护路由（需要认证）
 * ============================================
 */

// 应用认证中间件到所有后续路由
router.use(authMiddleware.verifyToken);

// 用户相关路由
router.use('/user', rateLimitMiddleware.user, userRoutes);

// 积分系统路由
router.use('/points', rateLimitMiddleware.points, pointsRoutes);

// 提案投票路由
router.use('/proposals', rateLimitMiddleware.proposals, proposalsRoutes);

// 质押系统路由
router.use('/staking', rateLimitMiddleware.staking, stakingRoutes);

// 抽奖系统路由
router.use('/lottery', rateLimitMiddleware.lottery, lotteryRoutes);

// NFT系统路由
router.use('/nft', rateLimitMiddleware.nft, nftRoutes);

/**
 * ============================================
 * 管理员路由（需要管理员权限）
 * ============================================
 */

// 管理员路由需要额外的权限检查
router.use('/admin', 
  rateLimitMiddleware.admin,
  permissionMiddleware.requireRole(['admin', 'super_admin']),
  adminRoutes
);

/**
 * ============================================
 * 系统统计和监控路由
 * ============================================
 */

// 系统统计
router.get('/stats', async (req, res, next) => {
  try {
    const statsService = require('../services/stats.service');
    const stats = await statsService.getSystemStats();
    
    res.json({
      success: true,
      data: stats,
      message: 'System statistics retrieved successfully'
    });
  } catch (error) {
    next(error);
  }
});

// API状态
router.get('/status', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'operational',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      pid: process.pid
    },
    message: 'API is operational'
  });
});

/**
 * ============================================
 * 错误处理和日志
 * ============================================
 */

// 记录所有API请求
router.use((req, res, next) => {
  const startTime = Date.now();
  
  // 在响应结束时记录日志
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const logData = {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user ? req.user.id : null
    };

    if (res.statusCode >= 400) {
      logger.warn('API Request completed with error', logData);
    } else {
      logger.info('API Request completed', logData);
    }
  });

  next();
});

/**
 * ============================================
 * 路由未找到处理
 * ============================================
 */

router.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'API_ENDPOINT_NOT_FOUND',
      message: `API endpoint ${req.method} ${req.originalUrl} not found`,
      timestamp: new Date().toISOString(),
      path: req.originalUrl,
      method: req.method
    }
  });
});

module.exports = router;
