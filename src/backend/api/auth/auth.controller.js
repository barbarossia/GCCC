/**
 * GCCC 认证授权控制器
 * 
 * 处理所有认证相关的业务逻辑
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const crypto = require('crypto');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

// 导入服务
const authService = require('../../services/auth.service');
const userService = require('../../services/user.service');
const walletService = require('../../services/wallet.service');
const emailService = require('../../services/email.service');
const cacheService = require('../../services/cache.service');

// 导入工具
const logger = require('../../utils/logger');
const ApiError = require('../../utils/ApiError');
const { createSuccessResponse, createErrorResponse } = require('../../utils/response');
const { generateTokens, verifyRefreshToken } = require('../../utils/jwt');

/**
 * ============================================
 * 钱包连接认证
 * ============================================
 */

/**
 * 创建钱包连接挑战
 */
const createWalletChallenge = async (req, res, next) => {
  try {
    const { wallet_address, wallet_type } = req.body;
    
    logger.info('Creating wallet challenge', {
      wallet_address,
      wallet_type,
      ip: req.ip
    });
    
    // 生成挑战消息
    const timestamp = Date.now();
    const nonce = crypto.randomBytes(16).toString('hex');
    const challenge = `GCCC Authentication Challenge: ${timestamp} - ${nonce} - Please sign this message to verify your wallet ownership`;
    
    // 生成挑战ID
    const challenge_id = uuidv4();
    
    // 设置过期时间（15分钟）
    const expires_at = new Date(Date.now() + 15 * 60 * 1000);
    
    // 将挑战信息存储到缓存中
    const challengeData = {
      challenge_id,
      wallet_address,
      wallet_type,
      challenge,
      timestamp,
      expires_at: expires_at.toISOString(),
      created_by_ip: req.ip
    };
    
    await cacheService.set(
      `auth:challenge:${challenge_id}`,
      challengeData,
      15 * 60 // 15分钟过期
    );
    
    // 记录挑战创建日志
    logger.info('Wallet challenge created', {
      challenge_id,
      wallet_address,
      expires_at
    });
    
    res.status(200).json(createSuccessResponse({
      challenge,
      challenge_id,
      expires_at: expires_at.toISOString()
    }, '请使用钱包签名此消息进行验证'));
    
  } catch (error) {
    logger.error('Error creating wallet challenge', {
      error: error.message,
      stack: error.stack,
      wallet_address: req.body.wallet_address
    });
    next(error);
  }
};

/**
 * 验证钱包签名并登录
 */
const verifyWalletSignature = async (req, res, next) => {
  try {
    const { wallet_address, challenge_id, signature, message } = req.body;
    
    logger.info('Verifying wallet signature', {
      wallet_address,
      challenge_id,
      ip: req.ip
    });
    
    // 从缓存中获取挑战信息
    const challengeData = await cacheService.get(`auth:challenge:${challenge_id}`);
    if (!challengeData) {
      throw new ApiError('AUTH_CHALLENGE_EXPIRED', '验证挑战已过期或不存在', 410);
    }
    
    // 验证挑战是否匹配
    if (challengeData.wallet_address !== wallet_address || 
        challengeData.challenge !== message) {
      throw new ApiError('AUTH_CHALLENGE_MISMATCH', '验证挑战信息不匹配', 400);
    }
    
    // 检查挑战是否过期
    if (new Date() > new Date(challengeData.expires_at)) {
      await cacheService.delete(`auth:challenge:${challenge_id}`);
      throw new ApiError('AUTH_CHALLENGE_EXPIRED', '验证挑战已过期', 410);
    }
    
    // 验证钱包签名
    const isValidSignature = await walletService.verifySignature(
      wallet_address,
      message,
      signature,
      challengeData.wallet_type
    );
    
    if (!isValidSignature) {
      logger.warn('Invalid wallet signature', {
        wallet_address,
        challenge_id,
        ip: req.ip
      });
      throw new ApiError('AUTH_SIGNATURE_INVALID', '钱包签名验证失败', 401);
    }
    
    // 删除已使用的挑战
    await cacheService.delete(`auth:challenge:${challenge_id}`);
    
    // 查找或创建用户
    let user = await userService.findByWalletAddress(wallet_address);
    if (!user) {
      // 创建新用户
      user = await userService.createUserWithWallet({
        wallet_address,
        wallet_type: challengeData.wallet_type,
        verification_signature: signature,
        verification_message: message
      });
      
      logger.info('New user created via wallet authentication', {
        user_id: user.id,
        wallet_address
      });
    } else {
      // 更新最后登录时间
      await userService.updateLastLogin(user.id);
    }
    
    // 生成设备信息
    const deviceInfo = {
      device_id: req.body.device_id || uuidv4(),
      device_name: req.body.device_name || 'Unknown Device',
      platform: req.body.platform || 'web',
      ip_address: req.ip,
      user_agent: req.get('User-Agent')
    };
    
    // 创建会话
    const session = await authService.createSession(user.id, deviceInfo);
    
    // 生成JWT令牌
    const tokens = await generateTokens(user, session.id);
    
    // 获取用户权限
    const permissions = await authService.getUserPermissions(user.id);
    
    logger.info('Wallet authentication successful', {
      user_id: user.id,
      session_id: session.id,
      wallet_address
    });
    
    res.status(200).json(createSuccessResponse({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      token_type: 'Bearer',
      expires_in: tokens.expiresIn,
      user: {
        id: user.id,
        wallet_address: user.wallet_address,
        username: user.username,
        email: user.email,
        avatar_url: user.avatar_url,
        role: user.role,
        level: user.level,
        experience: user.experience,
        kyc_status: user.kyc_status,
        created_at: user.created_at,
        last_login_at: user.last_login_at
      },
      permissions
    }, '钱包验证成功，登录完成'));
    
  } catch (error) {
    logger.error('Error verifying wallet signature', {
      error: error.message,
      stack: error.stack,
      wallet_address: req.body.wallet_address,
      challenge_id: req.body.challenge_id
    });
    next(error);
  }
};

/**
 * ============================================
 * 邮箱密码认证
 * ============================================
 */

/**
 * 用户注册
 */
const register = async (req, res, next) => {
  try {
    const { username, email, password, referral_code, terms_accepted, privacy_accepted } = req.body;
    
    logger.info('User registration attempt', {
      username,
      email,
      has_referral: !!referral_code,
      ip: req.ip
    });
    
    // 检查用户名和邮箱是否已存在
    const existingUser = await userService.findByUsernameOrEmail(username, email);
    if (existingUser) {
      const field = existingUser.username === username ? 'username' : 'email';
      throw new ApiError('CONFLICT_USER_EXISTS', `${field === 'username' ? '用户名' : '邮箱'}已存在`, 409, {
        field,
        value: field === 'username' ? username : email
      });
    }
    
    // 验证推荐码（如果提供）
    let referrer = null;
    if (referral_code) {
      referrer = await userService.findByReferralCode(referral_code);
      if (!referrer) {
        throw new ApiError('VALIDATION_INVALID_REFERRAL', '推荐码不存在', 400);
      }
    }
    
    // 加密密码
    const hashedPassword = await bcrypt.hash(password, 12);
    
    // 生成推荐码
    const userReferralCode = await userService.generateUniqueReferralCode();
    
    // 创建用户
    const userData = {
      username,
      email,
      password: hashedPassword,
      referral_code: userReferralCode,
      referred_by: referrer?.id || null,
      status: 'active',
      kyc_status: 'pending',
      terms_accepted,
      privacy_accepted
    };
    
    const user = await userService.createUser(userData);
    
    // 处理推荐奖励
    if (referrer) {
      await userService.handleReferralReward(referrer.id, user.id, referral_code);
    }
    
    // 发送邮箱验证邮件
    const verificationToken = await authService.generateEmailVerificationToken(user.id);
    await emailService.sendVerificationEmail(user.email, verificationToken);
    
    logger.info('User registered successfully', {
      user_id: user.id,
      username,
      email,
      referrer_id: referrer?.id
    });
    
    res.status(201).json(createSuccessResponse({
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        avatar_url: user.avatar_url,
        role: user.role,
        level: user.level,
        experience: user.experience,
        kyc_status: user.kyc_status,
        referral_code: user.referral_code,
        created_at: user.created_at
      },
      verification: {
        email_verification_required: true,
        verification_email_sent: true
      }
    }, '注册成功，请查收邮箱验证链接'));
    
  } catch (error) {
    logger.error('Error during user registration', {
      error: error.message,
      stack: error.stack,
      username: req.body.username,
      email: req.body.email
    });
    next(error);
  }
};

/**
 * 用户登录
 */
const login = async (req, res, next) => {
  try {
    const { login, password, remember_me, device_info } = req.body;
    
    logger.info('User login attempt', {
      login,
      ip: req.ip,
      user_agent: req.get('User-Agent')
    });
    
    // 查找用户
    const user = await userService.findByUsernameOrEmail(login, login);
    if (!user) {
      throw new ApiError('AUTH_INVALID_CREDENTIALS', '用户名或密码错误', 401, { login });
    }
    
    // 检查账户状态
    if (user.status === 'suspended') {
      throw new ApiError('AUTH_ACCOUNT_SUSPENDED', '账户已被暂停', 423, {
        user_id: user.id,
        status: user.status
      });
    }
    
    if (user.status === 'inactive') {
      throw new ApiError('AUTH_ACCOUNT_INACTIVE', '账户未激活，请先验证邮箱', 423, {
        user_id: user.id,
        email_verification_required: true
      });
    }
    
    // 检查登录失败次数
    const failedAttempts = await authService.getFailedLoginAttempts(user.id);
    if (failedAttempts >= 5) {
      const lockoutTime = await authService.getAccountLockoutTime(user.id);
      if (lockoutTime && lockoutTime > new Date()) {
        throw new ApiError('AUTH_ACCOUNT_LOCKED', '账户已被锁定，请稍后再试', 423, {
          locked_until: lockoutTime.toISOString(),
          reason: 'multiple_failed_attempts'
        });
      }
    }
    
    // 验证密码
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      // 记录失败尝试
      await authService.recordFailedLoginAttempt(user.id, req.ip);
      
      logger.warn('Invalid password attempt', {
        user_id: user.id,
        login,
        ip: req.ip
      });
      
      throw new ApiError('AUTH_INVALID_CREDENTIALS', '用户名或密码错误', 401, { login });
    }
    
    // 清除失败尝试记录
    await authService.clearFailedLoginAttempts(user.id);
    
    // 更新最后登录时间
    await userService.updateLastLogin(user.id);
    
    // 创建设备信息
    const deviceData = {
      device_id: device_info?.device_id || uuidv4(),
      device_name: device_info?.device_name || 'Unknown Device',
      platform: device_info?.platform || 'web',
      app_version: device_info?.app_version || '1.0.0',
      ip_address: req.ip,
      user_agent: req.get('User-Agent')
    };
    
    // 创建会话
    const sessionDuration = remember_me ? 30 * 24 * 60 * 60 * 1000 : 12 * 60 * 60 * 1000; // 30天或12小时
    const session = await authService.createSession(user.id, deviceData, sessionDuration);
    
    // 生成JWT令牌
    const tokens = await generateTokens(user, session.id, remember_me);
    
    // 获取用户权限
    const permissions = await authService.getUserPermissions(user.id);
    
    logger.info('User login successful', {
      user_id: user.id,
      session_id: session.id,
      login,
      remember_me
    });
    
    res.status(200).json(createSuccessResponse({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      token_type: 'Bearer',
      expires_in: tokens.expiresIn,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        avatar_url: user.avatar_url,
        role: user.role,
        level: user.level,
        experience: user.experience,
        kyc_status: user.kyc_status,
        last_login_at: new Date().toISOString()
      },
      permissions
    }, '登录成功'));
    
  } catch (error) {
    logger.error('Error during user login', {
      error: error.message,
      stack: error.stack,
      login: req.body.login,
      ip: req.ip
    });
    next(error);
  }
};

/**
 * 忘记密码
 */
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    
    logger.info('Forgot password request', {
      email,
      ip: req.ip
    });
    
    // 查找用户
    const user = await userService.findByEmail(email);
    if (!user) {
      // 为了安全起见，即使用户不存在也返回成功
      return res.status(200).json(createSuccessResponse({
        email_sent: true,
        reset_link_expires_in: 3600
      }, '密码重置链接已发送到您的邮箱'));
    }
    
    // 生成重置令牌
    const resetToken = await authService.generatePasswordResetToken(user.id);
    
    // 发送重置邮件
    await emailService.sendPasswordResetEmail(user.email, resetToken);
    
    logger.info('Password reset email sent', {
      user_id: user.id,
      email
    });
    
    res.status(200).json(createSuccessResponse({
      email_sent: true,
      reset_link_expires_in: 3600 // 1小时
    }, '密码重置链接已发送到您的邮箱'));
    
  } catch (error) {
    logger.error('Error sending password reset email', {
      error: error.message,
      stack: error.stack,
      email: req.body.email
    });
    next(error);
  }
};

/**
 * 重置密码
 */
const resetPassword = async (req, res, next) => {
  try {
    const { reset_token, new_password } = req.body;
    
    logger.info('Password reset attempt', {
      reset_token: reset_token.substring(0, 10) + '...',
      ip: req.ip
    });
    
    // 验证重置令牌
    const tokenData = await authService.verifyPasswordResetToken(reset_token);
    if (!tokenData) {
      throw new ApiError('AUTH_INVALID_RESET_TOKEN', '重置令牌无效或已过期', 400);
    }
    
    // 加密新密码
    const hashedPassword = await bcrypt.hash(new_password, 12);
    
    // 更新用户密码
    await userService.updatePassword(tokenData.user_id, hashedPassword);
    
    // 删除重置令牌
    await authService.deletePasswordResetToken(reset_token);
    
    // 撤销所有用户会话（强制重新登录）
    await authService.revokeAllUserSessions(tokenData.user_id);
    
    logger.info('Password reset successful', {
      user_id: tokenData.user_id
    });
    
    res.status(200).json(createSuccessResponse({
      password_reset: true,
      auto_login: false
    }, '密码重置成功，请重新登录'));
    
  } catch (error) {
    logger.error('Error resetting password', {
      error: error.message,
      stack: error.stack,
      reset_token: req.body.reset_token?.substring(0, 10) + '...'
    });
    next(error);
  }
};

/**
 * ============================================
 * 令牌管理
 * ============================================
 */

/**
 * 刷新访问令牌
 */
const refreshToken = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;
    
    logger.info('Token refresh attempt', {
      refresh_token: refresh_token.substring(0, 20) + '...',
      ip: req.ip
    });
    
    // 验证刷新令牌
    const decoded = await verifyRefreshToken(refresh_token);
    
    // 检查会话是否仍然有效
    const session = await authService.getSession(decoded.session_id);
    if (!session || session.status !== 'active') {
      throw new ApiError('AUTH_SESSION_INVALID', '会话已失效，请重新登录', 401);
    }
    
    // 获取用户信息
    const user = await userService.findById(decoded.sub);
    if (!user || user.status !== 'active') {
      throw new ApiError('AUTH_USER_INVALID', '用户状态异常，请重新登录', 401);
    }
    
    // 生成新的令牌
    const tokens = await generateTokens(user, session.id);
    
    // 更新会话活跃时间
    await authService.updateSessionActivity(session.id);
    
    logger.info('Token refresh successful', {
      user_id: user.id,
      session_id: session.id
    });
    
    res.status(200).json(createSuccessResponse({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
      token_type: 'Bearer',
      expires_in: tokens.expiresIn
    }, '令牌刷新成功'));
    
  } catch (error) {
    logger.error('Error refreshing token', {
      error: error.message,
      stack: error.stack,
      refresh_token: req.body.refresh_token?.substring(0, 20) + '...'
    });
    next(error);
  }
};

/**
 * 验证令牌有效性
 */
const verifyToken = async (req, res, next) => {
  try {
    const user = req.user;
    const session = req.session;
    
    // 计算令牌剩余时间
    const tokenExp = req.tokenPayload.exp;
    const currentTime = Math.floor(Date.now() / 1000);
    const remainingTime = tokenExp - currentTime;
    
    res.status(200).json(createSuccessResponse({
      valid: true,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        permissions: req.user.permissions
      },
      token_info: {
        issued_at: new Date(req.tokenPayload.iat * 1000).toISOString(),
        expires_at: new Date(req.tokenPayload.exp * 1000).toISOString(),
        remaining_time: remainingTime
      }
    }, '令牌有效'));
    
  } catch (error) {
    logger.error('Error verifying token', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id
    });
    next(error);
  }
};

/**
 * 用户登出
 */
const logout = async (req, res, next) => {
  try {
    const { logout_all_devices } = req.body;
    const userId = req.user.id;
    const sessionId = req.session.id;
    
    logger.info('User logout', {
      user_id: userId,
      session_id: sessionId,
      logout_all_devices,
      ip: req.ip
    });
    
    if (logout_all_devices) {
      // 撤销所有用户会话
      await authService.revokeAllUserSessions(userId);
    } else {
      // 只撤销当前会话
      await authService.revokeSession(sessionId);
    }
    
    res.status(200).json(createSuccessResponse({
      logged_out: true,
      logout_time: new Date().toISOString()
    }, '登出成功'));
    
  } catch (error) {
    logger.error('Error during logout', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id,
      session_id: req.session?.id
    });
    next(error);
  }
};

/**
 * ============================================
 * 密码管理
 * ============================================
 */

/**
 * 修改密码
 */
const changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body;
    const userId = req.user.id;
    
    logger.info('Password change attempt', {
      user_id: userId,
      ip: req.ip
    });
    
    // 获取用户当前密码
    const user = await userService.findById(userId);
    if (!user.password) {
      throw new ApiError('AUTH_NO_PASSWORD', '该账户未设置密码', 400);
    }
    
    // 验证当前密码
    const isValidPassword = await bcrypt.compare(current_password, user.password);
    if (!isValidPassword) {
      throw new ApiError('AUTH_INVALID_CURRENT_PASSWORD', '当前密码错误', 400);
    }
    
    // 检查新密码是否与当前密码相同
    const isSamePassword = await bcrypt.compare(new_password, user.password);
    if (isSamePassword) {
      throw new ApiError('AUTH_SAME_PASSWORD', '新密码不能与当前密码相同', 400);
    }
    
    // 加密新密码
    const hashedPassword = await bcrypt.hash(new_password, 12);
    
    // 更新密码
    await userService.updatePassword(userId, hashedPassword);
    
    // 撤销除当前会话外的所有会话
    await authService.revokeOtherUserSessions(userId, req.session.id);
    
    logger.info('Password changed successfully', {
      user_id: userId
    });
    
    res.status(200).json(createSuccessResponse({
      password_changed: true,
      changed_at: new Date().toISOString()
    }, '密码修改成功'));
    
  } catch (error) {
    logger.error('Error changing password', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id
    });
    next(error);
  }
};

/**
 * ============================================
 * 权限管理
 * ============================================
 */

/**
 * 获取当前用户权限
 */
const getUserPermissions = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // 获取详细权限信息
    const permissions = await authService.getUserPermissions(userId);
    const permissionDetails = await authService.getPermissionDetails(permissions);
    
    res.status(200).json(createSuccessResponse({
      user_id: userId,
      role: userRole,
      permissions: permissionDetails,
      permission_strings: permissions
    }, '权限获取成功'));
    
  } catch (error) {
    logger.error('Error getting user permissions', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id
    });
    next(error);
  }
};

/**
 * 检查特定权限
 */
const checkPermissions = async (req, res, next) => {
  try {
    const { permissions } = req.body;
    const userPermissions = req.user.permissions || [];
    
    const checks = permissions.map(permission => {
      const granted = authService.hasPermission(userPermissions, permission);
      const result = { permission, granted };
      
      if (!granted) {
        result.reason = 'insufficient_role';
      }
      
      return result;
    });
    
    const all_granted = checks.every(check => check.granted);
    
    res.status(200).json(createSuccessResponse({
      checks,
      all_granted
    }, '权限检查完成'));
    
  } catch (error) {
    logger.error('Error checking permissions', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id,
      permissions: req.body.permissions
    });
    next(error);
  }
};

/**
 * ============================================
 * 会话管理
 * ============================================
 */

/**
 * 获取用户活跃会话列表
 */
const getUserSessions = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const currentSessionId = req.session.id;
    
    const sessions = await authService.getUserSessions(userId);
    
    const formattedSessions = sessions.map(session => ({
      session_id: session.id,
      device_info: {
        device_name: session.device_name,
        platform: session.platform,
        browser: session.browser,
        ip_address: session.ip_address,
        location: session.location || '未知位置'
      },
      created_at: session.created_at,
      last_active_at: session.last_active_at,
      is_current: session.id === currentSessionId,
      expires_at: session.expires_at
    }));
    
    res.status(200).json(createSuccessResponse({
      sessions: formattedSessions,
      total_sessions: sessions.length,
      active_sessions: sessions.filter(s => s.status === 'active').length
    }, '会话列表获取成功'));
    
  } catch (error) {
    logger.error('Error getting user sessions', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id
    });
    next(error);
  }
};

/**
 * 撤销指定会话
 */
const revokeSession = async (req, res, next) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user.id;
    const currentSessionId = req.session.id;
    
    // 防止撤销当前会话
    if (sessionId === currentSessionId) {
      throw new ApiError('AUTH_CANNOT_REVOKE_CURRENT', '不能撤销当前会话', 400);
    }
    
    // 验证会话属于当前用户
    const session = await authService.getSession(sessionId);
    if (!session || session.user_id !== userId) {
      throw new ApiError('AUTH_SESSION_NOT_FOUND', '会话不存在', 404);
    }
    
    // 撤销会话
    await authService.revokeSession(sessionId);
    
    logger.info('Session revoked', {
      user_id: userId,
      revoked_session_id: sessionId,
      current_session_id: currentSessionId
    });
    
    res.status(200).json(createSuccessResponse({
      session_revoked: true,
      session_id: sessionId,
      revoked_at: new Date().toISOString()
    }, '会话已撤销'));
    
  } catch (error) {
    logger.error('Error revoking session', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id,
      session_id: req.params.sessionId
    });
    next(error);
  }
};

/**
 * 撤销所有其他会话
 */
const revokeOtherSessions = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const currentSessionId = req.session.id;
    
    const revokedCount = await authService.revokeOtherUserSessions(userId, currentSessionId);
    
    logger.info('Other sessions revoked', {
      user_id: userId,
      current_session_id: currentSessionId,
      revoked_count: revokedCount
    });
    
    res.status(200).json(createSuccessResponse({
      sessions_revoked: revokedCount,
      current_session_preserved: true,
      revoked_at: new Date().toISOString()
    }, '其他会话已全部撤销'));
    
  } catch (error) {
    logger.error('Error revoking other sessions', {
      error: error.message,
      stack: error.stack,
      user_id: req.user?.id
    });
    next(error);
  }
};

/**
 * ============================================
 * 健康检查
 * ============================================
 */

/**
 * 认证服务健康检查
 */
const healthCheck = async (req, res, next) => {
  try {
    // 检查数据库连接
    const dbStatus = await authService.checkDatabaseHealth();
    
    // 检查缓存连接
    const cacheStatus = await cacheService.healthCheck();
    
    // 检查外部服务
    const emailStatus = await emailService.healthCheck();
    
    const isHealthy = dbStatus && cacheStatus && emailStatus;
    
    res.status(isHealthy ? 200 : 503).json({
      success: isHealthy,
      data: {
        service: 'auth',
        status: isHealthy ? 'healthy' : 'unhealthy',
        timestamp: new Date().toISOString(),
        checks: {
          database: dbStatus,
          cache: cacheStatus,
          email: emailStatus
        }
      },
      message: isHealthy ? 'Authentication service is healthy' : 'Authentication service is unhealthy'
    });
    
  } catch (error) {
    logger.error('Health check failed', {
      error: error.message,
      stack: error.stack
    });
    
    res.status(503).json({
      success: false,
      error: {
        code: 'HEALTH_CHECK_FAILED',
        message: 'Authentication service health check failed'
      }
    });
  }
};

module.exports = {
  // 钱包认证
  createWalletChallenge,
  verifyWalletSignature,
  
  // 邮箱认证
  register,
  login,
  forgotPassword,
  resetPassword,
  
  // 令牌管理
  refreshToken,
  verifyToken,
  logout,
  
  // 密码管理
  changePassword,
  
  // 权限管理
  getUserPermissions,
  checkPermissions,
  
  // 会话管理
  getUserSessions,
  revokeSession,
  revokeOtherSessions,
  
  // 健康检查
  healthCheck
};
