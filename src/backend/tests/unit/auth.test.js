/**
 * GCCC 认证模块单元测试
 * 
 * 测试认证相关的所有功能：钱包认证、邮箱认证、令牌管理等
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const request = require('supertest');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

// 导入应用和依赖
const app = require('../../../../app'); // 需要创建主应用文件
const authService = require('../../services/auth.service');
const userService = require('../../services/user.service');
const walletService = require('../../services/wallet.service');
const emailService = require('../../services/email.service');
const cacheService = require('../../services/cache.service');
const { generateTokens, verifyAccessToken } = require('../../utils/jwt');

// 测试数据库设置
const { setupTestDB, cleanupTestDB } = require('../helpers/db.helper');

describe('认证模块测试', () => {
  let testUser;
  let testWalletUser;
  let accessToken;
  let refreshToken;
  
  // 测试前设置
  beforeAll(async () => {
    await setupTestDB();
    
    // 创建测试用户
    testUser = {
      id: 'test-user-1',
      username: 'testuser',
      email: 'test@gccc.com',
      password: await bcrypt.hash('TestPassword123!', 12),
      status: 'active',
      role: 'user',
      kyc_status: 'verified',
      created_at: new Date(),
      updated_at: new Date()
    };
    
    testWalletUser = {
      id: 'test-wallet-user-1',
      username: 'walletuser',
      wallet_address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
      wallet_type: 'solana',
      status: 'active',
      role: 'user',
      kyc_status: 'verified',
      created_at: new Date(),
      updated_at: new Date()
    };
  });
  
  // 测试后清理
  afterAll(async () => {
    await cleanupTestDB();
  });
  
  // 每个测试前重置mocks
  beforeEach(() => {
    jest.clearAllMocks();
  });

  /**
   * ============================================
   * 钱包连接认证测试
   * ============================================
   */
  
  describe('钱包连接认证', () => {
    describe('POST /api/v1/auth/wallet/challenge', () => {
      it('应该成功创建钱包挑战', async () => {
        // Mock缓存服务
        cacheService.set = jest.fn().mockResolvedValue(true);
        
        const challengeData = {
          wallet_address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
          wallet_type: 'solana'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/wallet/challenge')
          .send(challengeData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data).toHaveProperty('challenge');
        expect(response.body.data).toHaveProperty('challenge_id');
        expect(response.body.data).toHaveProperty('expires_at');
        expect(cacheService.set).toHaveBeenCalled();
      });
      
      it('应该拒绝无效的钱包地址格式', async () => {
        const challengeData = {
          wallet_address: 'invalid-address',
          wallet_type: 'solana'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/wallet/challenge')
          .send(challengeData)
          .expect(400);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
      });
      
      it('应该拒绝不支持的钱包类型', async () => {
        const challengeData = {
          wallet_address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
          wallet_type: 'unsupported'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/wallet/challenge')
          .send(challengeData)
          .expect(400);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
      });
    });
    
    describe('POST /api/v1/auth/wallet/verify', () => {
      it('应该成功验证钱包签名并登录新用户', async () => {
        const challengeData = {
          challenge_id: 'test-challenge-id',
          wallet_address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
          challenge: 'GCCC Authentication Challenge: 1234567890 - abcd1234 - Please sign this message to verify your wallet ownership',
          wallet_type: 'solana'
        };
        
        // Mock服务
        cacheService.get = jest.fn().mockResolvedValue(challengeData);
        cacheService.delete = jest.fn().mockResolvedValue(true);
        walletService.verifySignature = jest.fn().mockResolvedValue(true);
        userService.findByWalletAddress = jest.fn().mockResolvedValue(null);
        userService.createUserWithWallet = jest.fn().mockResolvedValue(testWalletUser);
        authService.createSession = jest.fn().mockResolvedValue({ id: 'session-1' });
        authService.getUserPermissions = jest.fn().mockResolvedValue(['user:read']);
        
        const verifyData = {
          wallet_address: challengeData.wallet_address,
          challenge_id: challengeData.challenge_id,
          signature: 'mock-signature',
          message: challengeData.challenge
        };
        
        const response = await request(app)
          .post('/api/v1/auth/wallet/verify')
          .send(verifyData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data).toHaveProperty('access_token');
        expect(response.body.data).toHaveProperty('refresh_token');
        expect(response.body.data).toHaveProperty('user');
        expect(response.body.data.user.wallet_address).toBe(challengeData.wallet_address);
      });
      
      it('应该成功验证钱包签名并登录现有用户', async () => {
        const challengeData = {
          challenge_id: 'test-challenge-id',
          wallet_address: testWalletUser.wallet_address,
          challenge: 'GCCC Authentication Challenge: 1234567890 - abcd1234 - Please sign this message to verify your wallet ownership',
          wallet_type: 'solana'
        };
        
        // Mock服务
        cacheService.get = jest.fn().mockResolvedValue(challengeData);
        cacheService.delete = jest.fn().mockResolvedValue(true);
        walletService.verifySignature = jest.fn().mockResolvedValue(true);
        userService.findByWalletAddress = jest.fn().mockResolvedValue(testWalletUser);
        userService.updateLastLogin = jest.fn().mockResolvedValue(true);
        authService.createSession = jest.fn().mockResolvedValue({ id: 'session-1' });
        authService.getUserPermissions = jest.fn().mockResolvedValue(['user:read']);
        
        const verifyData = {
          wallet_address: challengeData.wallet_address,
          challenge_id: challengeData.challenge_id,
          signature: 'mock-signature',
          message: challengeData.challenge
        };
        
        const response = await request(app)
          .post('/api/v1/auth/wallet/verify')
          .send(verifyData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(userService.updateLastLogin).toHaveBeenCalledWith(testWalletUser.id);
      });
      
      it('应该拒绝已过期的挑战', async () => {
        cacheService.get = jest.fn().mockResolvedValue(null);
        
        const verifyData = {
          wallet_address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
          challenge_id: 'expired-challenge-id',
          signature: 'mock-signature',
          message: 'mock-challenge'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/wallet/verify')
          .send(verifyData)
          .expect(410);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_CHALLENGE_EXPIRED');
      });
      
      it('应该拒绝无效的签名', async () => {
        const challengeData = {
          challenge_id: 'test-challenge-id',
          wallet_address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
          challenge: 'GCCC Authentication Challenge: 1234567890 - abcd1234 - Please sign this message to verify your wallet ownership',
          wallet_type: 'solana'
        };
        
        cacheService.get = jest.fn().mockResolvedValue(challengeData);
        walletService.verifySignature = jest.fn().mockResolvedValue(false);
        
        const verifyData = {
          wallet_address: challengeData.wallet_address,
          challenge_id: challengeData.challenge_id,
          signature: 'invalid-signature',
          message: challengeData.challenge
        };
        
        const response = await request(app)
          .post('/api/v1/auth/wallet/verify')
          .send(verifyData)
          .expect(401);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_SIGNATURE_INVALID');
      });
    });
  });

  /**
   * ============================================
   * 邮箱密码认证测试
   * ============================================
   */
  
  describe('邮箱密码认证', () => {
    describe('POST /api/v1/auth/register', () => {
      it('应该成功注册新用户', async () => {
        // Mock服务
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(null);
        userService.generateUniqueReferralCode = jest.fn().mockResolvedValue('REF123456');
        userService.createUser = jest.fn().mockResolvedValue(testUser);
        authService.generateEmailVerificationToken = jest.fn().mockResolvedValue('verify-token');
        emailService.sendVerificationEmail = jest.fn().mockResolvedValue(true);
        
        const registerData = {
          username: 'newuser',
          email: 'newuser@gccc.com',
          password: 'NewPassword123!',
          terms_accepted: true,
          privacy_accepted: true
        };
        
        const response = await request(app)
          .post('/api/v1/auth/register')
          .send(registerData)
          .expect(201);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data).toHaveProperty('user');
        expect(response.body.data).toHaveProperty('verification');
        expect(response.body.data.verification.email_verification_required).toBe(true);
        expect(emailService.sendVerificationEmail).toHaveBeenCalled();
      });
      
      it('应该拒绝已存在的用户名', async () => {
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(testUser);
        
        const registerData = {
          username: testUser.username,
          email: 'different@gccc.com',
          password: 'NewPassword123!',
          terms_accepted: true,
          privacy_accepted: true
        };
        
        const response = await request(app)
          .post('/api/v1/auth/register')
          .send(registerData)
          .expect(409);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('CONFLICT_USER_EXISTS');
      });
      
      it('应该拒绝弱密码', async () => {
        const registerData = {
          username: 'newuser',
          email: 'newuser@gccc.com',
          password: '123456', // 弱密码
          terms_accepted: true,
          privacy_accepted: true
        };
        
        const response = await request(app)
          .post('/api/v1/auth/register')
          .send(registerData)
          .expect(400);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('VALIDATION_ERROR');
      });
      
      it('应该处理推荐码注册', async () => {
        const referrer = {
          id: 'referrer-user-id',
          referral_code: 'REF123456'
        };
        
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(null);
        userService.findByReferralCode = jest.fn().mockResolvedValue(referrer);
        userService.generateUniqueReferralCode = jest.fn().mockResolvedValue('REF789012');
        userService.createUser = jest.fn().mockResolvedValue(testUser);
        userService.handleReferralReward = jest.fn().mockResolvedValue(true);
        authService.generateEmailVerificationToken = jest.fn().mockResolvedValue('verify-token');
        emailService.sendVerificationEmail = jest.fn().mockResolvedValue(true);
        
        const registerData = {
          username: 'newuser',
          email: 'newuser@gccc.com',
          password: 'NewPassword123!',
          referral_code: 'REF123456',
          terms_accepted: true,
          privacy_accepted: true
        };
        
        const response = await request(app)
          .post('/api/v1/auth/register')
          .send(registerData)
          .expect(201);
        
        expect(response.body.success).toBe(true);
        expect(userService.handleReferralReward).toHaveBeenCalledWith(referrer.id, testUser.id, 'REF123456');
      });
    });
    
    describe('POST /api/v1/auth/login', () => {
      it('应该成功登录有效用户', async () => {
        // Mock服务
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(testUser);
        authService.getFailedLoginAttempts = jest.fn().mockResolvedValue(0);
        authService.clearFailedLoginAttempts = jest.fn().mockResolvedValue(true);
        userService.updateLastLogin = jest.fn().mockResolvedValue(true);
        authService.createSession = jest.fn().mockResolvedValue({ id: 'session-1' });
        authService.getUserPermissions = jest.fn().mockResolvedValue(['user:read']);
        
        const loginData = {
          login: testUser.username,
          password: 'TestPassword123!',
          device_info: {
            device_name: 'Test Device',
            platform: 'web'
          }
        };
        
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send(loginData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data).toHaveProperty('access_token');
        expect(response.body.data).toHaveProperty('refresh_token');
        expect(response.body.data).toHaveProperty('user');
        expect(response.body.data.user.id).toBe(testUser.id);
      });
      
      it('应该拒绝错误的密码', async () => {
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(testUser);
        authService.getFailedLoginAttempts = jest.fn().mockResolvedValue(0);
        authService.recordFailedLoginAttempt = jest.fn().mockResolvedValue(true);
        
        const loginData = {
          login: testUser.username,
          password: 'WrongPassword123!'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send(loginData)
          .expect(401);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_INVALID_CREDENTIALS');
        expect(authService.recordFailedLoginAttempt).toHaveBeenCalled();
      });
      
      it('应该拒绝不存在的用户', async () => {
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(null);
        
        const loginData = {
          login: 'nonexistent@gccc.com',
          password: 'AnyPassword123!'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send(loginData)
          .expect(401);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_INVALID_CREDENTIALS');
      });
      
      it('应该拒绝被锁定的账户', async () => {
        const suspendedUser = { ...testUser, status: 'suspended' };
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(suspendedUser);
        
        const loginData = {
          login: testUser.username,
          password: 'TestPassword123!'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send(loginData)
          .expect(423);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_ACCOUNT_SUSPENDED');
      });
      
      it('应该处理"记住我"选项', async () => {
        userService.findByUsernameOrEmail = jest.fn().mockResolvedValue(testUser);
        authService.getFailedLoginAttempts = jest.fn().mockResolvedValue(0);
        authService.clearFailedLoginAttempts = jest.fn().mockResolvedValue(true);
        userService.updateLastLogin = jest.fn().mockResolvedValue(true);
        authService.createSession = jest.fn().mockResolvedValue({ id: 'session-1' });
        authService.getUserPermissions = jest.fn().mockResolvedValue(['user:read']);
        
        const loginData = {
          login: testUser.username,
          password: 'TestPassword123!',
          remember_me: true
        };
        
        const response = await request(app)
          .post('/api/v1/auth/login')
          .send(loginData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        // 验证会话创建时传递了正确的持续时间
        const sessionCall = authService.createSession.mock.calls[0];
        expect(sessionCall[2]).toBe(30 * 24 * 60 * 60 * 1000); // 30天
      });
    });

    describe('POST /api/v1/auth/forgot-password', () => {
      it('应该发送密码重置邮件给存在的用户', async () => {
        userService.findByEmail = jest.fn().mockResolvedValue(testUser);
        authService.generatePasswordResetToken = jest.fn().mockResolvedValue('reset-token');
        emailService.sendPasswordResetEmail = jest.fn().mockResolvedValue(true);
        
        const forgotData = {
          email: testUser.email
        };
        
        const response = await request(app)
          .post('/api/v1/auth/forgot-password')
          .send(forgotData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.email_sent).toBe(true);
        expect(emailService.sendPasswordResetEmail).toHaveBeenCalledWith(testUser.email, 'reset-token');
      });
      
      it('应该返回成功响应即使用户不存在（安全考虑）', async () => {
        userService.findByEmail = jest.fn().mockResolvedValue(null);
        
        const forgotData = {
          email: 'nonexistent@gccc.com'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/forgot-password')
          .send(forgotData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.email_sent).toBe(true);
        // 但不应该发送邮件
        expect(emailService.sendPasswordResetEmail).not.toHaveBeenCalled();
      });
    });
    
    describe('POST /api/v1/auth/reset-password', () => {
      it('应该成功重置密码', async () => {
        const tokenData = { user_id: testUser.id };
        
        authService.verifyPasswordResetToken = jest.fn().mockResolvedValue(tokenData);
        userService.updatePassword = jest.fn().mockResolvedValue(true);
        authService.deletePasswordResetToken = jest.fn().mockResolvedValue(true);
        authService.revokeAllUserSessions = jest.fn().mockResolvedValue(true);
        
        const resetData = {
          reset_token: 'valid-reset-token',
          new_password: 'NewPassword456!'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/reset-password')
          .send(resetData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.password_reset).toBe(true);
        expect(authService.revokeAllUserSessions).toHaveBeenCalledWith(testUser.id);
      });
      
      it('应该拒绝无效的重置令牌', async () => {
        authService.verifyPasswordResetToken = jest.fn().mockResolvedValue(null);
        
        const resetData = {
          reset_token: 'invalid-reset-token',
          new_password: 'NewPassword456!'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/reset-password')
          .send(resetData)
          .expect(400);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_INVALID_RESET_TOKEN');
      });
    });
  });

  /**
   * ============================================
   * 令牌管理测试
   * ============================================
   */
  
  describe('令牌管理', () => {
    beforeEach(async () => {
      // 为每个测试生成新的令牌
      const tokens = await generateTokens(testUser, 'test-session-id');
      accessToken = tokens.accessToken;
      refreshToken = tokens.refreshToken;
    });
    
    describe('POST /api/v1/auth/refresh-token', () => {
      it('应该成功刷新访问令牌', async () => {
        const session = {
          id: 'test-session-id',
          user_id: testUser.id,
          status: 'active'
        };
        
        authService.getSession = jest.fn().mockResolvedValue(session);
        userService.findById = jest.fn().mockResolvedValue(testUser);
        authService.updateSessionActivity = jest.fn().mockResolvedValue(true);
        
        const refreshData = {
          refresh_token: refreshToken
        };
        
        const response = await request(app)
          .post('/api/v1/auth/refresh-token')
          .send(refreshData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data).toHaveProperty('access_token');
        expect(response.body.data).toHaveProperty('refresh_token');
        expect(response.body.data.token_type).toBe('Bearer');
      });
      
      it('应该拒绝无效的刷新令牌', async () => {
        const refreshData = {
          refresh_token: 'invalid-refresh-token'
        };
        
        const response = await request(app)
          .post('/api/v1/auth/refresh-token')
          .send(refreshData)
          .expect(401);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_REFRESH_TOKEN_INVALID');
      });
      
      it('应该拒绝已失效的会话', async () => {
        const inactiveSession = {
          id: 'test-session-id',
          user_id: testUser.id,
          status: 'revoked'
        };
        
        authService.getSession = jest.fn().mockResolvedValue(inactiveSession);
        
        const refreshData = {
          refresh_token: refreshToken
        };
        
        const response = await request(app)
          .post('/api/v1/auth/refresh-token')
          .send(refreshData)
          .expect(401);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_SESSION_INVALID');
      });
    });
    
    describe('GET /api/v1/auth/verify-token', () => {
      it('应该成功验证有效令牌', async () => {
        const session = {
          id: 'test-session-id',
          user_id: testUser.id,
          status: 'active'
        };
        
        // Mock认证中间件行为
        authService.getSession = jest.fn().mockResolvedValue(session);
        userService.findById = jest.fn().mockResolvedValue(testUser);
        authService.getUserPermissions = jest.fn().mockResolvedValue(['user:read']);
        
        const response = await request(app)
          .get('/api/v1/auth/verify-token')
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.valid).toBe(true);
        expect(response.body.data).toHaveProperty('user');
        expect(response.body.data).toHaveProperty('token_info');
      });
      
      it('应该拒绝缺少的令牌', async () => {
        const response = await request(app)
          .get('/api/v1/auth/verify-token')
          .expect(401);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_TOKEN_MISSING');
      });
    });
    
    describe('POST /api/v1/auth/logout', () => {
      it('应该成功登出当前会话', async () => {
        authService.revokeSession = jest.fn().mockResolvedValue(true);
        
        const logoutData = {
          logout_all_devices: false
        };
        
        const response = await request(app)
          .post('/api/v1/auth/logout')
          .set('Authorization', `Bearer ${accessToken}`)
          .send(logoutData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.logged_out).toBe(true);
        expect(authService.revokeSession).toHaveBeenCalledWith('test-session-id');
      });
      
      it('应该成功登出所有设备', async () => {
        authService.revokeAllUserSessions = jest.fn().mockResolvedValue(5);
        
        const logoutData = {
          logout_all_devices: true
        };
        
        const response = await request(app)
          .post('/api/v1/auth/logout')
          .set('Authorization', `Bearer ${accessToken}`)
          .send(logoutData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.logged_out).toBe(true);
        expect(authService.revokeAllUserSessions).toHaveBeenCalledWith(testUser.id);
      });
    });
  });

  /**
   * ============================================
   * 密码管理测试
   * ============================================
   */
  
  describe('密码管理', () => {
    describe('PUT /api/v1/auth/change-password', () => {
      it('应该成功修改密码', async () => {
        userService.findById = jest.fn().mockResolvedValue(testUser);
        userService.updatePassword = jest.fn().mockResolvedValue(true);
        authService.revokeOtherUserSessions = jest.fn().mockResolvedValue(3);
        
        const changeData = {
          current_password: 'TestPassword123!',
          new_password: 'NewTestPassword456!'
        };
        
        const response = await request(app)
          .put('/api/v1/auth/change-password')
          .set('Authorization', `Bearer ${accessToken}`)
          .send(changeData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.password_changed).toBe(true);
        expect(authService.revokeOtherUserSessions).toHaveBeenCalledWith(testUser.id, 'test-session-id');
      });
      
      it('应该拒绝错误的当前密码', async () => {
        userService.findById = jest.fn().mockResolvedValue(testUser);
        
        const changeData = {
          current_password: 'WrongCurrentPassword!',
          new_password: 'NewTestPassword456!'
        };
        
        const response = await request(app)
          .put('/api/v1/auth/change-password')
          .set('Authorization', `Bearer ${accessToken}`)
          .send(changeData)
          .expect(400);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_INVALID_CURRENT_PASSWORD');
      });
      
      it('应该拒绝与当前密码相同的新密码', async () => {
        userService.findById = jest.fn().mockResolvedValue(testUser);
        
        const changeData = {
          current_password: 'TestPassword123!',
          new_password: 'TestPassword123!' // 相同密码
        };
        
        const response = await request(app)
          .put('/api/v1/auth/change-password')
          .set('Authorization', `Bearer ${accessToken}`)
          .send(changeData)
          .expect(400);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_SAME_PASSWORD');
      });
    });
  });

  /**
   * ============================================
   * 权限管理测试
   * ============================================
   */
  
  describe('权限管理', () => {
    describe('GET /api/v1/auth/permissions', () => {
      it('应该返回用户权限列表', async () => {
        const permissions = ['user:read', 'user:write', 'prediction:create'];
        const permissionDetails = [
          { permission: 'user:read', description: '读取用户信息' },
          { permission: 'user:write', description: '修改用户信息' },
          { permission: 'prediction:create', description: '创建预测' }
        ];
        
        authService.getUserPermissions = jest.fn().mockResolvedValue(permissions);
        authService.getPermissionDetails = jest.fn().mockResolvedValue(permissionDetails);
        
        const response = await request(app)
          .get('/api/v1/auth/permissions')
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.permissions).toEqual(permissionDetails);
        expect(response.body.data.permission_strings).toEqual(permissions);
      });
    });
    
    describe('POST /api/v1/auth/check-permissions', () => {
      it('应该正确检查用户权限', async () => {
        const userPermissions = ['user:read', 'user:write'];
        // Mock用户权限
        testUser.permissions = userPermissions;
        authService.hasPermission = jest.fn()
          .mockReturnValueOnce(true) // user:read
          .mockReturnValueOnce(false); // admin:write
        
        const checkData = {
          permissions: ['user:read', 'admin:write']
        };
        
        const response = await request(app)
          .post('/api/v1/auth/check-permissions')
          .set('Authorization', `Bearer ${accessToken}`)
          .send(checkData)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.checks).toHaveLength(2);
        expect(response.body.data.checks[0]).toEqual({
          permission: 'user:read',
          granted: true
        });
        expect(response.body.data.checks[1]).toEqual({
          permission: 'admin:write',
          granted: false,
          reason: 'insufficient_role'
        });
        expect(response.body.data.all_granted).toBe(false);
      });
    });
  });

  /**
   * ============================================
   * 会话管理测试
   * ============================================
   */
  
  describe('会话管理', () => {
    describe('GET /api/v1/auth/sessions', () => {
      it('应该返回用户活跃会话列表', async () => {
        const sessions = [
          {
            id: 'session-1',
            device_name: 'Chrome Browser',
            platform: 'web',
            ip_address: '192.168.1.1',
            created_at: new Date(),
            last_active_at: new Date(),
            expires_at: new Date(Date.now() + 86400000),
            status: 'active'
          },
          {
            id: 'session-2',
            device_name: 'Mobile App',
            platform: 'ios',
            ip_address: '192.168.1.2',
            created_at: new Date(),
            last_active_at: new Date(),
            expires_at: new Date(Date.now() + 86400000),
            status: 'active'
          }
        ];
        
        authService.getUserSessions = jest.fn().mockResolvedValue(sessions);
        
        const response = await request(app)
          .get('/api/v1/auth/sessions')
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.sessions).toHaveLength(2);
        expect(response.body.data.total_sessions).toBe(2);
        expect(response.body.data.active_sessions).toBe(2);
      });
    });
    
    describe('DELETE /api/v1/auth/sessions/:sessionId', () => {
      it('应该成功撤销指定会话', async () => {
        const targetSession = {
          id: 'session-2',
          user_id: testUser.id
        };
        
        authService.getSession = jest.fn().mockResolvedValue(targetSession);
        authService.revokeSession = jest.fn().mockResolvedValue(true);
        
        const response = await request(app)
          .delete('/api/v1/auth/sessions/session-2')
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.session_revoked).toBe(true);
        expect(authService.revokeSession).toHaveBeenCalledWith('session-2');
      });
      
      it('应该拒绝撤销当前会话', async () => {
        const response = await request(app)
          .delete('/api/v1/auth/sessions/test-session-id') // 当前会话ID
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(400);
        
        expect(response.body.success).toBe(false);
        expect(response.body.error.code).toBe('AUTH_CANNOT_REVOKE_CURRENT');
      });
    });
    
    describe('DELETE /api/v1/auth/sessions/others', () => {
      it('应该成功撤销所有其他会话', async () => {
        authService.revokeOtherUserSessions = jest.fn().mockResolvedValue(3);
        
        const response = await request(app)
          .delete('/api/v1/auth/sessions/others')
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.sessions_revoked).toBe(3);
        expect(response.body.data.current_session_preserved).toBe(true);
        expect(authService.revokeOtherUserSessions).toHaveBeenCalledWith(testUser.id, 'test-session-id');
      });
    });
  });

  /**
   * ============================================
   * 健康检查测试
   * ============================================
   */
  
  describe('健康检查', () => {
    describe('GET /api/v1/auth/health', () => {
      it('应该返回健康状态', async () => {
        authService.checkDatabaseHealth = jest.fn().mockResolvedValue(true);
        cacheService.healthCheck = jest.fn().mockResolvedValue(true);
        emailService.healthCheck = jest.fn().mockResolvedValue(true);
        
        const response = await request(app)
          .get('/api/v1/auth/health')
          .expect(200);
        
        expect(response.body.success).toBe(true);
        expect(response.body.data.status).toBe('healthy');
        expect(response.body.data.checks).toEqual({
          database: true,
          cache: true,
          email: true
        });
      });
      
      it('应该返回不健康状态当服务有问题时', async () => {
        authService.checkDatabaseHealth = jest.fn().mockResolvedValue(false);
        cacheService.healthCheck = jest.fn().mockResolvedValue(true);
        emailService.healthCheck = jest.fn().mockResolvedValue(true);
        
        const response = await request(app)
          .get('/api/v1/auth/health')
          .expect(503);
        
        expect(response.body.success).toBe(false);
        expect(response.body.data.status).toBe('unhealthy');
        expect(response.body.data.checks.database).toBe(false);
      });
    });
  });

  /**
   * ============================================
   * 中间件测试
   * ============================================
   */
  
  describe('认证中间件', () => {
    it('应该允许有效令牌通过', async () => {
      const session = {
        id: 'test-session-id',
        user_id: testUser.id,
        status: 'active'
      };
      
      authService.getSession = jest.fn().mockResolvedValue(session);
      userService.findById = jest.fn().mockResolvedValue(testUser);
      authService.getUserPermissions = jest.fn().mockResolvedValue(['user:read']);
      
      // 测试需要认证的端点
      const response = await request(app)
        .get('/api/v1/auth/permissions')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      
      expect(response.body.success).toBe(true);
    });
    
    it('应该拒绝无效令牌', async () => {
      const response = await request(app)
        .get('/api/v1/auth/permissions')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('AUTH_TOKEN_INVALID');
    });
    
    it('应该拒绝缺少Authorization头', async () => {
      const response = await request(app)
        .get('/api/v1/auth/permissions')
        .expect(401);
      
      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('AUTH_TOKEN_MISSING');
    });
  });
});
