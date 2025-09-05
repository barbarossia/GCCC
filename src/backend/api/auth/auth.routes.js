/**
 * GCCC 认证授权路由
 * 
 * 提供用户认证、授权、会话管理等功能
 * 支持钱包连接认证和邮箱密码认证
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const express = require('express');
const router = express.Router();

// 导入控制器
const authController = require('./auth.controller');

// 导入中间件
const authMiddleware = require('../../middleware/auth.middleware');
const validationMiddleware = require('../../middleware/validation.middleware');
const rateLimitMiddleware = require('../../middleware/rateLimit.middleware');

// 导入验证规则
const authValidation = require('./auth.validation');

/**
 * ============================================
 * 钱包连接认证
 * ============================================
 */

/**
 * 请求钱包连接挑战
 * @route POST /api/v1/auth/wallet/challenge
 * @access Public
 */
router.post(
  '/wallet/challenge',
  rateLimitMiddleware.challenge,
  validationMiddleware.validate(authValidation.walletChallenge),
  authController.createWalletChallenge
);

/**
 * 验证钱包签名并登录
 * @route POST /api/v1/auth/wallet/verify
 * @access Public
 */
router.post(
  '/wallet/verify',
  rateLimitMiddleware.signatureVerify,
  validationMiddleware.validate(authValidation.walletVerify),
  authController.verifyWalletSignature
);

/**
 * ============================================
 * 邮箱密码认证
 * ============================================
 */

/**
 * 用户注册
 * @route POST /api/v1/auth/register
 * @access Public
 */
router.post(
  '/register',
  rateLimitMiddleware.register,
  validationMiddleware.validate(authValidation.register),
  authController.register
);

/**
 * 用户登录
 * @route POST /api/v1/auth/login
 * @access Public
 */
router.post(
  '/login',
  rateLimitMiddleware.login,
  validationMiddleware.validate(authValidation.login),
  authController.login
);

/**
 * 忘记密码
 * @route POST /api/v1/auth/forgot-password
 * @access Public
 */
router.post(
  '/forgot-password',
  rateLimitMiddleware.forgotPassword,
  validationMiddleware.validate(authValidation.forgotPassword),
  authController.forgotPassword
);

/**
 * 重置密码
 * @route POST /api/v1/auth/reset-password
 * @access Public
 */
router.post(
  '/reset-password',
  rateLimitMiddleware.resetPassword,
  validationMiddleware.validate(authValidation.resetPassword),
  authController.resetPassword
);

/**
 * ============================================
 * 令牌管理
 * ============================================
 */

/**
 * 刷新访问令牌
 * @route POST /api/v1/auth/refresh
 * @access Public (需要有效的refresh token)
 */
router.post(
  '/refresh',
  rateLimitMiddleware.tokenRefresh,
  validationMiddleware.validate(authValidation.refreshToken),
  authController.refreshToken
);

/**
 * 验证令牌有效性
 * @route POST /api/v1/auth/verify
 * @access Private
 */
router.post(
  '/verify',
  authMiddleware.verifyToken,
  authController.verifyToken
);

/**
 * 登出
 * @route POST /api/v1/auth/logout
 * @access Private
 */
router.post(
  '/logout',
  authMiddleware.verifyToken,
  validationMiddleware.validate(authValidation.logout),
  authController.logout
);

/**
 * ============================================
 * 密码管理 (需要认证)
 * ============================================
 */

/**
 * 修改密码
 * @route PUT /api/v1/auth/password
 * @access Private
 */
router.put(
  '/password',
  authMiddleware.verifyToken,
  rateLimitMiddleware.changePassword,
  validationMiddleware.validate(authValidation.changePassword),
  authController.changePassword
);

/**
 * ============================================
 * 权限管理 (需要认证)
 * ============================================
 */

/**
 * 获取当前用户权限
 * @route GET /api/v1/auth/permissions
 * @access Private
 */
router.get(
  '/permissions',
  authMiddleware.verifyToken,
  authController.getUserPermissions
);

/**
 * 检查特定权限
 * @route POST /api/v1/auth/check-permission
 * @access Private
 */
router.post(
  '/check-permission',
  authMiddleware.verifyToken,
  validationMiddleware.validate(authValidation.checkPermission),
  authController.checkPermissions
);

/**
 * ============================================
 * 会话管理 (需要认证)
 * ============================================
 */

/**
 * 获取活跃会话列表
 * @route GET /api/v1/auth/sessions
 * @access Private
 */
router.get(
  '/sessions',
  authMiddleware.verifyToken,
  authController.getUserSessions
);

/**
 * 撤销指定会话
 * @route DELETE /api/v1/auth/sessions/:sessionId
 * @access Private
 */
router.delete(
  '/sessions/:sessionId',
  authMiddleware.verifyToken,
  rateLimitMiddleware.sessionRevoke,
  validationMiddleware.validate(authValidation.revokeSession),
  authController.revokeSession
);

/**
 * 撤销所有其他会话
 * @route DELETE /api/v1/auth/sessions/others
 * @access Private
 */
router.delete(
  '/sessions/others',
  authMiddleware.verifyToken,
  rateLimitMiddleware.sessionRevokeAll,
  authController.revokeOtherSessions
);

/**
 * ============================================
 * 健康检查和监控
 * ============================================
 */

/**
 * 认证服务健康检查
 * @route GET /api/v1/auth/health
 * @access Public
 */
router.get('/health', authController.healthCheck);

module.exports = router;
