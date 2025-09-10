/**
 * 权限检查中间件
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const logger = require('../utils/logger');
const { createErrorResponse } = require('../utils/response');

/**
 * 权限检查中间件
 * @param {Array|String} requiredPermissions - 需要的权限
 * @returns {Function} Express中间件函数
 */
const checkPermission = (requiredPermissions) => {
  return (req, res, next) => {
    try {
      // 如果没有用户信息，返回未授权
      if (!req.user) {
        return res
          .status(401)
          .json(createErrorResponse('未授权访问', 'UNAUTHORIZED'));
      }

      // 将单个权限转换为数组
      const permissions = Array.isArray(requiredPermissions)
        ? requiredPermissions
        : [requiredPermissions];

      // 检查用户是否有所需权限
      const hasPermission = permissions.some((permission) => {
        return (
          req.user.permissions && req.user.permissions.includes(permission)
        );
      });

      if (!hasPermission) {
        logger.warn(`用户 ${req.user.id} 尝试访问未授权资源: ${req.path}`, {
          userId: req.user.id,
          requiredPermissions: permissions,
          userPermissions: req.user.permissions,
        });

        return res
          .status(403)
          .json(createErrorResponse('权限不足', 'FORBIDDEN'));
      }

      next();
    } catch (error) {
      logger.error('权限检查中间件错误:', error);
      return res
        .status(500)
        .json(createErrorResponse('服务器内部错误', 'INTERNAL_ERROR'));
    }
  };
};

/**
 * 管理员权限检查
 */
const requireAdmin = checkPermission('admin');

/**
 * 用户权限检查
 */
const requireUser = checkPermission(['admin', 'user']);

module.exports = {
  checkPermission,
  requireAdmin,
  requireUser,
};
