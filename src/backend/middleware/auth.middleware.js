/**
 * GCCC 认证授权中间件
 * 
 * 提供JWT令牌验证、权限检查、限流等中间件功能
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');

// 导入服务
const authService = require('../../services/auth.service');
const userService = require('../../services/user.service');
const cacheService = require('../../services/cache.service');

// 导入工具
const logger = require('../../utils/logger');
const ApiError = require('../../utils/ApiError');
const { createErrorResponse } = require('../../utils/response');
const { verifyAccessToken } = require('../../utils/jwt');

/**
 * ============================================
 * JWT 令牌验证中间件
 * ============================================
 */

/**
 * 验证访问令牌
 */
const authenticateToken = async (req, res, next) => {
  try {
    // 从请求头中获取令牌
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError('AUTH_TOKEN_MISSING', '访问令牌缺失', 401);
    }
    
    const token = authHeader.substring(7); // 移除 "Bearer " 前缀
    if (!token) {
      throw new ApiError('AUTH_TOKEN_MISSING', '访问令牌缺失', 401);
    }
    
    // 验证令牌
    const decoded = await verifyAccessToken(token);
    req.tokenPayload = decoded;
    
    // 检查会话是否仍然有效
    const session = await authService.getSession(decoded.session_id);
    if (!session || session.status !== 'active') {
      throw new ApiError('AUTH_SESSION_INVALID', '会话已失效，请重新登录', 401);
    }
    
    // 检查会话是否过期
    if (session.expires_at && new Date(session.expires_at) < new Date()) {
      throw new ApiError('AUTH_SESSION_EXPIRED', '会话已过期，请重新登录', 401);
    }
    
    // 获取用户信息
    const user = await userService.findById(decoded.sub);
    if (!user) {
      throw new ApiError('AUTH_USER_NOT_FOUND', '用户不存在', 401);
    }
    
    // 检查用户状态
    if (user.status !== 'active') {
      const statusMessages = {
        'inactive': '账户未激活',
        'suspended': '账户已被暂停',
        'banned': '账户已被封禁'
      };
      throw new ApiError('AUTH_ACCOUNT_INVALID', statusMessages[user.status] || '账户状态异常', 423);
    }
    
    // 获取用户权限
    const permissions = await authService.getUserPermissions(user.id);
    user.permissions = permissions;
    
    // 更新会话活跃时间（异步执行，不阻塞请求）
    authService.updateSessionActivity(session.id).catch(error => {
      logger.warn('Failed to update session activity', {
        session_id: session.id,
        error: error.message
      });
    });
    
    // 将用户和会话信息添加到请求对象
    req.user = user;
    req.session = session;
    
    next();
    
  } catch (error) {
    logger.error('Token authentication failed', {
      error: error.message,
      token: req.headers.authorization?.substring(0, 20) + '...',
      ip: req.ip,
      user_agent: req.get('User-Agent')
    });
    
    // 如果是JWT相关错误，转换为统一的认证错误
    if (error.name === 'JsonWebTokenError') {
      error = new ApiError('AUTH_TOKEN_INVALID', '访问令牌无效', 401);
    } else if (error.name === 'TokenExpiredError') {
      error = new ApiError('AUTH_TOKEN_EXPIRED', '访问令牌已过期', 401);
    }
    
    next(error);
  }
};

/**
 * 可选的令牌验证（用户可能已登录或未登录）
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // 没有令牌，继续执行，但不设置用户信息
      return next();
    }
    
    // 有令牌，尝试验证
    await authenticateToken(req, res, next);
    
  } catch (error) {
    // 令牌验证失败时，记录警告但不中断请求
    logger.warn('Optional authentication failed', {
      error: error.message,
      ip: req.ip
    });
    
    // 清除可能设置的用户信息
    req.user = null;
    req.session = null;
    
    next();
  }
};

/**
 * ============================================
 * 权限检查中间件
 * ============================================
 */

/**
 * 检查用户是否具有指定权限
 * @param {string|string[]} requiredPermissions 必需的权限
 * @param {object} options 配置选项
 */
const requirePermissions = (requiredPermissions, options = {}) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        throw new ApiError('AUTH_REQUIRED', '需要登录才能访问此资源', 401);
      }
      
      const userPermissions = req.user.permissions || [];
      const permissions = Array.isArray(requiredPermissions) ? requiredPermissions : [requiredPermissions];
      
      // 检查权限逻辑
      const requireAll = options.requireAll !== false; // 默认需要所有权限
      
      let hasPermission;
      if (requireAll) {
        // 需要所有权限
        hasPermission = permissions.every(permission => 
          authService.hasPermission(userPermissions, permission)
        );
      } else {
        // 只需要其中一个权限
        hasPermission = permissions.some(permission => 
          authService.hasPermission(userPermissions, permission)
        );
      }
      
      if (!hasPermission) {
        logger.warn('Permission denied', {
          user_id: req.user.id,
          user_role: req.user.role,
          required_permissions: permissions,
          user_permissions: userPermissions,
          path: req.path,
          method: req.method
        });
        
        throw new ApiError('AUTH_FORBIDDEN', '权限不足', 403, {
          required_permissions: permissions,
          user_role: req.user.role
        });
      }
      
      next();
      
    } catch (error) {
      next(error);
    }
  };
};

/**
 * 检查用户角色
 * @param {string|string[]} requiredRoles 必需的角色
 * @param {object} options 配置选项
 */
const requireRoles = (requiredRoles, options = {}) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        throw new ApiError('AUTH_REQUIRED', '需要登录才能访问此资源', 401);
      }
      
      const userRole = req.user.role;
      const roles = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
      
      // 角色层级检查
      const roleHierarchy = {
        'super_admin': 6,
        'admin': 5,
        'moderator': 4,
        'vip': 3,
        'premium': 2,
        'user': 1,
        'guest': 0
      };
      
      const userRoleLevel = roleHierarchy[userRole] || 0;
      const requiredLevel = options.exact ? 
        userRoleLevel : // 需要精确角色
        Math.min(...roles.map(role => roleHierarchy[role] || 0)); // 需要最低角色等级
      
      let hasRole;
      if (options.exact) {
        // 精确角色匹配
        hasRole = roles.includes(userRole);
      } else {
        // 角色等级检查
        hasRole = userRoleLevel >= requiredLevel;
      }
      
      if (!hasRole) {
        logger.warn('Role access denied', {
          user_id: req.user.id,
          user_role: userRole,
          required_roles: roles,
          path: req.path,
          method: req.method
        });
        
        throw new ApiError('AUTH_FORBIDDEN', '角色权限不足', 403, {
          required_roles: roles,
          user_role: userRole
        });
      }
      
      next();
      
    } catch (error) {
      next(error);
    }
  };
};

/**
 * 检查资源所有权
 * @param {function} ownershipChecker 所有权检查函数
 */
const requireOwnership = (ownershipChecker) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        throw new ApiError('AUTH_REQUIRED', '需要登录才能访问此资源', 401);
      }
      
      // 管理员可以访问所有资源
      if (['super_admin', 'admin'].includes(req.user.role)) {
        return next();
      }
      
      // 检查资源所有权
      const isOwner = await ownershipChecker(req.user.id, req);
      if (!isOwner) {
        logger.warn('Resource ownership denied', {
          user_id: req.user.id,
          resource: req.path,
          method: req.method,
          params: req.params
        });
        
        throw new ApiError('AUTH_FORBIDDEN', '只能访问自己的资源', 403);
      }
      
      next();
      
    } catch (error) {
      next(error);
    }
  };
};

/**
 * ============================================
 * 限流中间件
 * ============================================
 */

/**
 * 通用限流中间件配置
 */
const createRateLimit = (options = {}) => {
  const defaultOptions = {
    windowMs: 15 * 60 * 1000, // 15分钟
    max: 100, // 最大请求数
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      logger.warn('Rate limit exceeded', {
        ip: req.ip,
        path: req.path,
        user_agent: req.get('User-Agent'),
        user_id: req.user?.id
      });
      
      res.status(429).json(createErrorResponse({
        code: 'RATE_LIMIT_EXCEEDED',
        message: '请求过于频繁，请稍后再试',
        details: {
          limit: options.max || defaultOptions.max,
          window_ms: options.windowMs || defaultOptions.windowMs,
          retry_after: Math.ceil((options.windowMs || defaultOptions.windowMs) / 1000)
        }
      }));
    },
    keyGenerator: (req) => {
      // 优先使用用户ID，否则使用IP
      return req.user?.id || req.ip;
    }
  };
  
  return rateLimit({ ...defaultOptions, ...options });
};

/**
 * 认证相关接口限流
 */
const authRateLimit = createRateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 10, // 最大10次登录尝试
  skipSuccessfulRequests: true // 成功的请求不计入限流
});

/**
 * 密码重置限流
 */
const passwordResetRateLimit = createRateLimit({
  windowMs: 60 * 60 * 1000, // 1小时
  max: 3, // 最大3次密码重置请求
  skipSuccessfulRequests: false
});

/**
 * 邮件发送限流
 */
const emailRateLimit = createRateLimit({
  windowMs: 60 * 60 * 1000, // 1小时
  max: 5, // 最大5封邮件
  skipSuccessfulRequests: false
});

/**
 * 钱包验证限流
 */
const walletRateLimit = createRateLimit({
  windowMs: 5 * 60 * 1000, // 5分钟
  max: 20, // 最大20次钱包验证尝试
  skipSuccessfulRequests: true
});

/**
 * ============================================
 * KYC 状态检查中间件
 * ============================================
 */

/**
 * 检查KYC状态
 * @param {string[]} requiredStatus 必需的KYC状态
 */
const requireKYC = (requiredStatus = ['verified']) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        throw new ApiError('AUTH_REQUIRED', '需要登录才能访问此资源', 401);
      }
      
      const userKycStatus = req.user.kyc_status || 'pending';
      const allowedStatus = Array.isArray(requiredStatus) ? requiredStatus : [requiredStatus];
      
      if (!allowedStatus.includes(userKycStatus)) {
        logger.warn('KYC status check failed', {
          user_id: req.user.id,
          current_status: userKycStatus,
          required_status: allowedStatus,
          path: req.path
        });
        
        const statusMessages = {
          'pending': '等待KYC验证',
          'reviewing': 'KYC审核中',
          'rejected': 'KYC验证被拒绝',
          'verified': 'KYC已验证'
        };
        
        throw new ApiError('KYC_REQUIRED', `需要KYC验证才能访问此功能，当前状态：${statusMessages[userKycStatus]}`, 403, {
          current_kyc_status: userKycStatus,
          required_kyc_status: allowedStatus
        });
      }
      
      next();
      
    } catch (error) {
      next(error);
    }
  };
};

/**
 * ============================================
 * 设备验证中间件
 * ============================================
 */

/**
 * 设备指纹验证
 */
const deviceVerification = async (req, res, next) => {
  try {
    if (!req.user || !req.session) {
      return next();
    }
    
    // 获取设备信息
    const currentDevice = {
      ip: req.ip,
      user_agent: req.get('User-Agent'),
      accept_language: req.get('Accept-Language')
    };
    
    // 检查设备是否可疑
    const isSuspiciousDevice = await authService.checkSuspiciousDevice(
      req.user.id,
      currentDevice
    );
    
    if (isSuspiciousDevice) {
      logger.warn('Suspicious device detected', {
        user_id: req.user.id,
        session_id: req.session.id,
        device: currentDevice,
        path: req.path
      });
      
      // 可以选择要求额外验证或直接拒绝
      req.requireAdditionalAuth = true;
    }
    
    next();
    
  } catch (error) {
    logger.error('Device verification failed', {
      error: error.message,
      user_id: req.user?.id,
      ip: req.ip
    });
    next();
  }
};

/**
 * ============================================
 * 错误处理中间件
 * ============================================
 */

/**
 * 认证错误处理中间件
 */
const authErrorHandler = (error, req, res, next) => {
  // 只处理认证相关错误
  if (!error.isOperational && !error.code?.startsWith('AUTH_')) {
    return next(error);
  }
  
  logger.error('Authentication error', {
    error: error.message,
    code: error.code,
    status: error.statusCode,
    user_id: req.user?.id,
    path: req.path,
    method: req.method,
    ip: req.ip
  });
  
  res.status(error.statusCode || 401).json(createErrorResponse(error));
};

/**
 * ============================================
 * 实用工具中间件
 * ============================================
 */

/**
 * 请求日志中间件
 */
const requestLogger = (req, res, next) => {
  const startTime = Date.now();
  
  // 响应结束时记录日志
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    
    logger.info('API Request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration,
      ip: req.ip,
      user_agent: req.get('User-Agent'),
      user_id: req.user?.id,
      session_id: req.session?.id
    });
  });
  
  next();
};

/**
 * CORS 配置
 */
const corsConfig = {
  origin: (origin, callback) => {
    // 允许的域名列表
    const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
      'http://localhost:3000',
      'http://localhost:3001',
      'https://gccc.games'
    ];
    
    // 允许没有origin的请求（如移动应用）
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('CORS policy violation'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

module.exports = {
  // 认证中间件
  authenticateToken,
  optionalAuth,
  
  // 权限检查
  requirePermissions,
  requireRoles,
  requireOwnership,
  
  // 限流中间件
  createRateLimit,
  authRateLimit,
  passwordResetRateLimit,
  emailRateLimit,
  walletRateLimit,
  
  // KYC检查
  requireKYC,
  
  // 设备验证
  deviceVerification,
  
  // 错误处理
  authErrorHandler,
  
  // 实用工具
  requestLogger,
  corsConfig
};
