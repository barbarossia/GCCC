/**
 * GCCC JWT 工具类
 * 
 * 提供JWT令牌的生成、验证、刷新等功能
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// 导入配置
const logger = require('./logger');
const ApiError = require('./ApiError');

/**
 * JWT配置
 */
const JWT_CONFIG = {
  // 访问令牌配置
  ACCESS_TOKEN: {
    SECRET: process.env.JWT_ACCESS_SECRET || 'gccc-access-secret-key-2024',
    EXPIRES_IN: process.env.JWT_ACCESS_EXPIRES_IN || '15m', // 15分钟
    ALGORITHM: 'HS256'
  },
  
  // 刷新令牌配置
  REFRESH_TOKEN: {
    SECRET: process.env.JWT_REFRESH_SECRET || 'gccc-refresh-secret-key-2024',
    EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN || '7d', // 7天
    REMEMBER_EXPIRES_IN: process.env.JWT_REFRESH_REMEMBER_EXPIRES_IN || '30d', // 记住我：30天
    ALGORITHM: 'HS256'
  },
  
  // 邮箱验证令牌配置
  EMAIL_VERIFICATION: {
    SECRET: process.env.JWT_EMAIL_SECRET || 'gccc-email-verification-secret-2024',
    EXPIRES_IN: '24h', // 24小时
    ALGORITHM: 'HS256'
  },
  
  // 密码重置令牌配置
  PASSWORD_RESET: {
    SECRET: process.env.JWT_PASSWORD_SECRET || 'gccc-password-reset-secret-2024',
    EXPIRES_IN: '1h', // 1小时
    ALGORITHM: 'HS256'
  },
  
  // 发行者
  ISSUER: process.env.JWT_ISSUER || 'gccc.games',
  
  // 默认受众
  AUDIENCE: process.env.JWT_AUDIENCE || 'gccc-users'
};

/**
 * ============================================
 * 令牌生成函数
 * ============================================
 */

/**
 * 生成访问令牌
 * @param {Object} user 用户对象
 * @param {string} sessionId 会话ID
 * @param {Object} options 额外选项
 * @returns {string} JWT访问令牌
 */
const generateAccessToken = (user, sessionId, options = {}) => {
  try {
    const payload = {
      sub: user.id, // 主题（用户ID）
      username: user.username,
      email: user.email,
      role: user.role,
      session_id: sessionId,
      kyc_status: user.kyc_status,
      wallet_address: user.wallet_address,
      
      // 令牌标识
      jti: crypto.randomUUID(), // JWT ID
      
      // 时间戳
      iat: Math.floor(Date.now() / 1000), // 签发时间
      
      // 自定义声明
      ...options.customClaims
    };
    
    const signOptions = {
      algorithm: JWT_CONFIG.ACCESS_TOKEN.ALGORITHM,
      expiresIn: options.expiresIn || JWT_CONFIG.ACCESS_TOKEN.EXPIRES_IN,
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE
    };
    
    const token = jwt.sign(payload, JWT_CONFIG.ACCESS_TOKEN.SECRET, signOptions);
    
    logger.debug('Access token generated', {
      user_id: user.id,
      session_id: sessionId,
      expires_in: signOptions.expiresIn
    });
    
    return token;
    
  } catch (error) {
    logger.error('Error generating access token', {
      error: error.message,
      user_id: user?.id,
      session_id: sessionId
    });
    throw new ApiError('TOKEN_GENERATION_FAILED', '访问令牌生成失败', 500);
  }
};

/**
 * 生成刷新令牌
 * @param {Object} user 用户对象
 * @param {string} sessionId 会话ID
 * @param {boolean} rememberMe 是否记住登录
 * @param {Object} options 额外选项
 * @returns {string} JWT刷新令牌
 */
const generateRefreshToken = (user, sessionId, rememberMe = false, options = {}) => {
  try {
    const payload = {
      sub: user.id,
      session_id: sessionId,
      type: 'refresh',
      
      // 令牌标识
      jti: crypto.randomUUID(),
      
      // 时间戳
      iat: Math.floor(Date.now() / 1000),
      
      // 设备信息（如果提供）
      device_id: options.deviceId,
      
      // 自定义声明
      ...options.customClaims
    };
    
    const expiresIn = rememberMe ? 
      JWT_CONFIG.REFRESH_TOKEN.REMEMBER_EXPIRES_IN : 
      JWT_CONFIG.REFRESH_TOKEN.EXPIRES_IN;
    
    const signOptions = {
      algorithm: JWT_CONFIG.REFRESH_TOKEN.ALGORITHM,
      expiresIn,
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE
    };
    
    const token = jwt.sign(payload, JWT_CONFIG.REFRESH_TOKEN.SECRET, signOptions);
    
    logger.debug('Refresh token generated', {
      user_id: user.id,
      session_id: sessionId,
      remember_me: rememberMe,
      expires_in: expiresIn
    });
    
    return token;
    
  } catch (error) {
    logger.error('Error generating refresh token', {
      error: error.message,
      user_id: user?.id,
      session_id: sessionId
    });
    throw new ApiError('TOKEN_GENERATION_FAILED', '刷新令牌生成失败', 500);
  }
};

/**
 * 生成令牌对
 * @param {Object} user 用户对象
 * @param {string} sessionId 会话ID
 * @param {boolean} rememberMe 是否记住登录
 * @param {Object} options 额外选项
 * @returns {Object} 包含访问令牌和刷新令牌的对象
 */
const generateTokens = (user, sessionId, rememberMe = false, options = {}) => {
  try {
    const accessToken = generateAccessToken(user, sessionId, options);
    const refreshToken = generateRefreshToken(user, sessionId, rememberMe, options);
    
    // 计算过期时间（秒）
    const accessExpiresIn = parseExpirationTime(JWT_CONFIG.ACCESS_TOKEN.EXPIRES_IN);
    const refreshExpiresIn = parseExpirationTime(
      rememberMe ? 
        JWT_CONFIG.REFRESH_TOKEN.REMEMBER_EXPIRES_IN : 
        JWT_CONFIG.REFRESH_TOKEN.EXPIRES_IN
    );
    
    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: accessExpiresIn,
      refreshExpiresIn
    };
    
  } catch (error) {
    logger.error('Error generating token pair', {
      error: error.message,
      user_id: user?.id,
      session_id: sessionId
    });
    throw error;
  }
};

/**
 * ============================================
 * 令牌验证函数
 * ============================================
 */

/**
 * 验证访问令牌
 * @param {string} token JWT令牌
 * @param {Object} options 验证选项
 * @returns {Object} 解码后的载荷
 */
const verifyAccessToken = (token, options = {}) => {
  try {
    const verifyOptions = {
      algorithms: [JWT_CONFIG.ACCESS_TOKEN.ALGORITHM],
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE,
      clockTolerance: 30, // 30秒时钟偏差容忍
      ...options
    };
    
    const decoded = jwt.verify(token, JWT_CONFIG.ACCESS_TOKEN.SECRET, verifyOptions);
    
    logger.debug('Access token verified', {
      user_id: decoded.sub,
      session_id: decoded.session_id,
      expires_at: new Date(decoded.exp * 1000).toISOString()
    });
    
    return decoded;
    
  } catch (error) {
    logger.warn('Access token verification failed', {
      error: error.message,
      token: token.substring(0, 20) + '...'
    });
    
    // 转换JWT错误为自定义错误
    if (error.name === 'TokenExpiredError') {
      throw new ApiError('AUTH_TOKEN_EXPIRED', '访问令牌已过期', 401);
    } else if (error.name === 'JsonWebTokenError') {
      throw new ApiError('AUTH_TOKEN_INVALID', '访问令牌无效', 401);
    } else if (error.name === 'NotBeforeError') {
      throw new ApiError('AUTH_TOKEN_NOT_ACTIVE', '访问令牌尚未生效', 401);
    }
    
    throw new ApiError('AUTH_TOKEN_VERIFICATION_FAILED', '访问令牌验证失败', 401);
  }
};

/**
 * 验证刷新令牌
 * @param {string} token JWT令牌
 * @param {Object} options 验证选项
 * @returns {Object} 解码后的载荷
 */
const verifyRefreshToken = (token, options = {}) => {
  try {
    const verifyOptions = {
      algorithms: [JWT_CONFIG.REFRESH_TOKEN.ALGORITHM],
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE,
      clockTolerance: 30,
      ...options
    };
    
    const decoded = jwt.verify(token, JWT_CONFIG.REFRESH_TOKEN.SECRET, verifyOptions);
    
    // 验证令牌类型
    if (decoded.type !== 'refresh') {
      throw new ApiError('AUTH_TOKEN_INVALID', '令牌类型错误', 401);
    }
    
    logger.debug('Refresh token verified', {
      user_id: decoded.sub,
      session_id: decoded.session_id,
      expires_at: new Date(decoded.exp * 1000).toISOString()
    });
    
    return decoded;
    
  } catch (error) {
    logger.warn('Refresh token verification failed', {
      error: error.message,
      token: token.substring(0, 20) + '...'
    });
    
    if (error.name === 'TokenExpiredError') {
      throw new ApiError('AUTH_REFRESH_TOKEN_EXPIRED', '刷新令牌已过期，请重新登录', 401);
    } else if (error.name === 'JsonWebTokenError') {
      throw new ApiError('AUTH_REFRESH_TOKEN_INVALID', '刷新令牌无效', 401);
    }
    
    throw new ApiError('AUTH_REFRESH_TOKEN_VERIFICATION_FAILED', '刷新令牌验证失败', 401);
  }
};

/**
 * ============================================
 * 特殊用途令牌
 * ============================================
 */

/**
 * 生成邮箱验证令牌
 * @param {string} userId 用户ID
 * @param {string} email 邮箱地址
 * @param {Object} options 额外选项
 * @returns {string} 邮箱验证令牌
 */
const generateEmailVerificationToken = (userId, email, options = {}) => {
  try {
    const payload = {
      sub: userId,
      email,
      type: 'email_verification',
      jti: crypto.randomUUID(),
      iat: Math.floor(Date.now() / 1000)
    };
    
    const signOptions = {
      algorithm: JWT_CONFIG.EMAIL_VERIFICATION.ALGORITHM,
      expiresIn: JWT_CONFIG.EMAIL_VERIFICATION.EXPIRES_IN,
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE
    };
    
    const token = jwt.sign(payload, JWT_CONFIG.EMAIL_VERIFICATION.SECRET, signOptions);
    
    logger.debug('Email verification token generated', {
      user_id: userId,
      email
    });
    
    return token;
    
  } catch (error) {
    logger.error('Error generating email verification token', {
      error: error.message,
      user_id: userId,
      email
    });
    throw new ApiError('TOKEN_GENERATION_FAILED', '邮箱验证令牌生成失败', 500);
  }
};

/**
 * 验证邮箱验证令牌
 * @param {string} token 邮箱验证令牌
 * @returns {Object} 解码后的载荷
 */
const verifyEmailVerificationToken = (token) => {
  try {
    const verifyOptions = {
      algorithms: [JWT_CONFIG.EMAIL_VERIFICATION.ALGORITHM],
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE
    };
    
    const decoded = jwt.verify(token, JWT_CONFIG.EMAIL_VERIFICATION.SECRET, verifyOptions);
    
    if (decoded.type !== 'email_verification') {
      throw new ApiError('AUTH_TOKEN_INVALID', '令牌类型错误', 400);
    }
    
    return decoded;
    
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new ApiError('EMAIL_VERIFICATION_TOKEN_EXPIRED', '邮箱验证链接已过期', 400);
    } else if (error.name === 'JsonWebTokenError') {
      throw new ApiError('EMAIL_VERIFICATION_TOKEN_INVALID', '邮箱验证链接无效', 400);
    }
    
    throw new ApiError('EMAIL_VERIFICATION_FAILED', '邮箱验证失败', 400);
  }
};

/**
 * 生成密码重置令牌
 * @param {string} userId 用户ID
 * @param {string} email 邮箱地址
 * @param {Object} options 额外选项
 * @returns {string} 密码重置令牌
 */
const generatePasswordResetToken = (userId, email, options = {}) => {
  try {
    const payload = {
      sub: userId,
      email,
      type: 'password_reset',
      jti: crypto.randomUUID(),
      iat: Math.floor(Date.now() / 1000),
      // 添加随机熵以增强安全性
      entropy: crypto.randomBytes(16).toString('hex')
    };
    
    const signOptions = {
      algorithm: JWT_CONFIG.PASSWORD_RESET.ALGORITHM,
      expiresIn: JWT_CONFIG.PASSWORD_RESET.EXPIRES_IN,
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE
    };
    
    const token = jwt.sign(payload, JWT_CONFIG.PASSWORD_RESET.SECRET, signOptions);
    
    logger.debug('Password reset token generated', {
      user_id: userId,
      email
    });
    
    return token;
    
  } catch (error) {
    logger.error('Error generating password reset token', {
      error: error.message,
      user_id: userId,
      email
    });
    throw new ApiError('TOKEN_GENERATION_FAILED', '密码重置令牌生成失败', 500);
  }
};

/**
 * 验证密码重置令牌
 * @param {string} token 密码重置令牌
 * @returns {Object} 解码后的载荷
 */
const verifyPasswordResetToken = (token) => {
  try {
    const verifyOptions = {
      algorithms: [JWT_CONFIG.PASSWORD_RESET.ALGORITHM],
      issuer: JWT_CONFIG.ISSUER,
      audience: JWT_CONFIG.AUDIENCE
    };
    
    const decoded = jwt.verify(token, JWT_CONFIG.PASSWORD_RESET.SECRET, verifyOptions);
    
    if (decoded.type !== 'password_reset') {
      throw new ApiError('AUTH_TOKEN_INVALID', '令牌类型错误', 400);
    }
    
    return decoded;
    
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new ApiError('PASSWORD_RESET_TOKEN_EXPIRED', '密码重置链接已过期', 400);
    } else if (error.name === 'JsonWebTokenError') {
      throw new ApiError('PASSWORD_RESET_TOKEN_INVALID', '密码重置链接无效', 400);
    }
    
    throw new ApiError('PASSWORD_RESET_VERIFICATION_FAILED', '密码重置验证失败', 400);
  }
};

/**
 * ============================================
 * 工具函数
 * ============================================
 */

/**
 * 解析过期时间字符串为秒数
 * @param {string} expirationTime 过期时间字符串（如 '15m', '7d', '1h'）
 * @returns {number} 秒数
 */
const parseExpirationTime = (expirationTime) => {
  const timeUnits = {
    's': 1,
    'm': 60,
    'h': 60 * 60,
    'd': 24 * 60 * 60,
    'w': 7 * 24 * 60 * 60
  };
  
  const match = expirationTime.match(/^(\d+)([smhdw])$/);
  if (!match) {
    throw new Error(`Invalid expiration time format: ${expirationTime}`);
  }
  
  const [, number, unit] = match;
  return parseInt(number) * timeUnits[unit];
};

/**
 * 解码令牌（不验证签名）
 * @param {string} token JWT令牌
 * @returns {Object} 解码后的载荷
 */
const decodeToken = (token) => {
  try {
    return jwt.decode(token, { complete: true });
  } catch (error) {
    logger.warn('Token decode failed', {
      error: error.message,
      token: token.substring(0, 20) + '...'
    });
    return null;
  }
};

/**
 * 检查令牌是否即将过期
 * @param {string} token JWT令牌
 * @param {number} thresholdSeconds 阈值秒数（默认5分钟）
 * @returns {boolean} 是否即将过期
 */
const isTokenExpiringSoon = (token, thresholdSeconds = 300) => {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || !decoded.exp) {
      return true;
    }
    
    const currentTime = Math.floor(Date.now() / 1000);
    const expirationTime = decoded.exp;
    
    return (expirationTime - currentTime) <= thresholdSeconds;
    
  } catch (error) {
    return true;
  }
};

/**
 * 获取令牌剩余有效时间
 * @param {string} token JWT令牌
 * @returns {number} 剩余秒数，-1表示已过期或无效
 */
const getTokenRemainingTime = (token) => {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || !decoded.exp) {
      return -1;
    }
    
    const currentTime = Math.floor(Date.now() / 1000);
    const remainingTime = decoded.exp - currentTime;
    
    return Math.max(0, remainingTime);
    
  } catch (error) {
    return -1;
  }
};

module.exports = {
  // 令牌生成
  generateAccessToken,
  generateRefreshToken,
  generateTokens,
  
  // 令牌验证
  verifyAccessToken,
  verifyRefreshToken,
  
  // 特殊用途令牌
  generateEmailVerificationToken,
  verifyEmailVerificationToken,
  generatePasswordResetToken,
  verifyPasswordResetToken,
  
  // 工具函数
  parseExpirationTime,
  decodeToken,
  isTokenExpiringSoon,
  getTokenRemainingTime,
  
  // 配置导出
  JWT_CONFIG
};
