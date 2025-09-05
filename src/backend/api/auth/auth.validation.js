/**
 * GCCC 认证授权参数验证规则
 * 
 * 使用Joi库定义所有认证相关接口的参数验证规则
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

const Joi = require('joi');

/**
 * ============================================
 * 基础验证模式
 * ============================================
 */

// 钱包地址验证
const walletAddress = Joi.string()
  .min(32)
  .max(50)
  .pattern(/^[1-9A-HJ-NP-Za-km-z]+$/)
  .messages({
    'string.pattern.base': '钱包地址格式不正确',
    'string.min': '钱包地址长度不能少于32个字符',
    'string.max': '钱包地址长度不能超过50个字符'
  });

// 邮箱验证
const email = Joi.string()
  .email()
  .max(255)
  .messages({
    'string.email': '邮箱格式不正确',
    'string.max': '邮箱长度不能超过255个字符'
  });

// 用户名验证
const username = Joi.string()
  .min(3)
  .max(50)
  .pattern(/^[a-zA-Z0-9_-]+$/)
  .messages({
    'string.pattern.base': '用户名只能包含字母、数字、下划线和连字符',
    'string.min': '用户名长度不能少于3个字符',
    'string.max': '用户名长度不能超过50个字符'
  });

// 密码验证
const password = Joi.string()
  .min(8)
  .max(128)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
  .messages({
    'string.pattern.base': '密码必须包含至少一个大写字母、一个小写字母、一个数字和一个特殊字符',
    'string.min': '密码长度不能少于8个字符',
    'string.max': '密码长度不能超过128个字符'
  });

// UUID验证
const uuid = Joi.string()
  .guid({ version: 'uuidv4' })
  .messages({
    'string.guid': 'UUID格式不正确'
  });

/**
 * ============================================
 * 钱包连接认证验证
 * ============================================
 */

// 请求钱包挑战验证
const walletChallenge = {
  body: Joi.object({
    wallet_address: walletAddress.required(),
    wallet_type: Joi.string()
      .valid('solana', 'ethereum')
      .default('solana')
      .messages({
        'any.only': '钱包类型只能是 solana 或 ethereum'
      })
  })
};

// 验证钱包签名验证
const walletVerify = {
  body: Joi.object({
    wallet_address: walletAddress.required(),
    challenge_id: uuid.required(),
    signature: Joi.string()
      .required()
      .min(64)
      .max(256)
      .messages({
        'string.min': '签名长度不正确',
        'string.max': '签名长度不正确'
      }),
    message: Joi.string()
      .required()
      .min(10)
      .max(500)
      .messages({
        'string.min': '签名消息长度不正确',
        'string.max': '签名消息长度不正确'
      })
  })
};

/**
 * ============================================
 * 邮箱密码认证验证
 * ============================================
 */

// 用户注册验证
const register = {
  body: Joi.object({
    username: username.required(),
    email: email.required(),
    password: password.required(),
    confirm_password: Joi.string()
      .valid(Joi.ref('password'))
      .required()
      .messages({
        'any.only': '确认密码必须与密码一致'
      }),
    referral_code: Joi.string()
      .min(6)
      .max(20)
      .pattern(/^[A-Z0-9]+$/)
      .optional()
      .messages({
        'string.pattern.base': '推荐码格式不正确',
        'string.min': '推荐码长度不能少于6个字符',
        'string.max': '推荐码长度不能超过20个字符'
      }),
    terms_accepted: Joi.boolean()
      .valid(true)
      .required()
      .messages({
        'any.only': '必须接受服务条款'
      }),
    privacy_accepted: Joi.boolean()
      .valid(true)
      .required()
      .messages({
        'any.only': '必须接受隐私政策'
      })
  })
};

// 用户登录验证
const login = {
  body: Joi.object({
    login: Joi.alternatives()
      .try(email, username)
      .required()
      .messages({
        'alternatives.match': '请输入有效的邮箱或用户名'
      }),
    password: Joi.string()
      .required()
      .messages({
        'string.empty': '密码不能为空'
      }),
    remember_me: Joi.boolean()
      .default(false),
    device_info: Joi.object({
      device_id: uuid.optional(),
      device_name: Joi.string()
        .max(100)
        .optional(),
      platform: Joi.string()
        .valid('web', 'ios', 'android', 'desktop')
        .optional(),
      app_version: Joi.string()
        .pattern(/^\d+\.\d+\.\d+$/)
        .optional()
    }).optional()
  })
};

// 忘记密码验证
const forgotPassword = {
  body: Joi.object({
    email: email.required()
  })
};

// 重置密码验证
const resetPassword = {
  body: Joi.object({
    reset_token: Joi.string()
      .required()
      .min(32)
      .max(256)
      .messages({
        'string.min': '重置令牌格式不正确',
        'string.max': '重置令牌格式不正确'
      }),
    new_password: password.required(),
    confirm_password: Joi.string()
      .valid(Joi.ref('new_password'))
      .required()
      .messages({
        'any.only': '确认密码必须与新密码一致'
      })
  })
};

/**
 * ============================================
 * 令牌管理验证
 * ============================================
 */

// 刷新令牌验证
const refreshToken = {
  body: Joi.object({
    refresh_token: Joi.string()
      .required()
      .min(100)
      .max(1000)
      .messages({
        'string.min': '刷新令牌格式不正确',
        'string.max': '刷新令牌格式不正确'
      })
  })
};

// 登出验证
const logout = {
  body: Joi.object({
    logout_all_devices: Joi.boolean()
      .default(false)
  })
};

/**
 * ============================================
 * 密码管理验证
 * ============================================
 */

// 修改密码验证
const changePassword = {
  body: Joi.object({
    current_password: Joi.string()
      .required()
      .messages({
        'string.empty': '当前密码不能为空'
      }),
    new_password: password.required(),
    confirm_password: Joi.string()
      .valid(Joi.ref('new_password'))
      .required()
      .messages({
        'any.only': '确认密码必须与新密码一致'
      })
  })
};

/**
 * ============================================
 * 权限管理验证
 * ============================================
 */

// 检查权限验证
const checkPermission = {
  body: Joi.object({
    permissions: Joi.array()
      .items(
        Joi.string()
          .pattern(/^[a-z_]+:[a-z_*]+$/)
          .messages({
            'string.pattern.base': '权限格式应为 resource:action'
          })
      )
      .min(1)
      .max(20)
      .required()
      .messages({
        'array.min': '至少需要检查一个权限',
        'array.max': '一次最多检查20个权限'
      })
  })
};

/**
 * ============================================
 * 会话管理验证
 * ============================================
 */

// 撤销会话验证
const revokeSession = {
  params: Joi.object({
    sessionId: uuid.required()
  })
};

/**
 * ============================================
 * 通用验证规则
 * ============================================
 */

// 分页验证
const pagination = {
  query: Joi.object({
    page: Joi.number()
      .integer()
      .min(1)
      .default(1),
    limit: Joi.number()
      .integer()
      .min(1)
      .max(100)
      .default(20),
    sort: Joi.string()
      .valid('created_at', 'updated_at', 'last_active_at')
      .default('created_at'),
    order: Joi.string()
      .valid('asc', 'desc')
      .default('desc')
  })
};

module.exports = {
  // 钱包认证
  walletChallenge,
  walletVerify,
  
  // 邮箱认证
  register,
  login,
  forgotPassword,
  resetPassword,
  
  // 令牌管理
  refreshToken,
  logout,
  
  // 密码管理
  changePassword,
  
  // 权限管理
  checkPermission,
  
  // 会话管理
  revokeSession,
  
  // 通用规则
  pagination,
  
  // 基础验证模式（供其他模块使用）
  schemas: {
    walletAddress,
    email,
    username,
    password,
    uuid
  }
};
