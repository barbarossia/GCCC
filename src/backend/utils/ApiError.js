/**
 * GCCC 自定义错误类
 * 
 * 提供统一的错误处理机制和错误分类
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

/**
 * ============================================
 * 基础API错误类
 * ============================================
 */

/**
 * API错误基础类
 */
class ApiError extends Error {
  /**
   * 创建API错误实例
   * @param {string} code 错误代码
   * @param {string} message 错误消息
   * @param {number} statusCode HTTP状态码
   * @param {any} details 错误详情
   * @param {boolean} isOperational 是否为操作性错误
   */
  constructor(code, message, statusCode = 500, details = null, isOperational = true) {
    super(message);
    
    this.name = this.constructor.name;
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = isOperational;
    this.timestamp = new Date().toISOString();
    
    // 确保错误栈跟踪正确
    Error.captureStackTrace(this, this.constructor);
  }
  
  /**
   * 将错误转换为JSON格式
   * @returns {Object} JSON格式的错误信息
   */
  toJSON() {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      statusCode: this.statusCode,
      details: this.details,
      isOperational: this.isOperational,
      timestamp: this.timestamp,
      stack: process.env.NODE_ENV === 'development' ? this.stack : undefined
    };
  }
}

/**
 * ============================================
 * 认证授权错误
 * ============================================
 */

/**
 * 认证错误类
 */
class AuthenticationError extends ApiError {
  constructor(message = '认证失败', code = 'AUTH_FAILED', details = null) {
    super(code, message, 401, details);
    this.category = 'authentication';
  }
}

/**
 * 授权错误类（权限不足）
 */
class AuthorizationError extends ApiError {
  constructor(message = '权限不足', code = 'PERMISSION_DENIED', details = null) {
    super(code, message, 403, details);
    this.category = 'authorization';
  }
}

/**
 * 令牌相关错误类
 */
class TokenError extends ApiError {
  constructor(message = '令牌错误', code = 'TOKEN_ERROR', details = null) {
    super(code, message, 401, details);
    this.category = 'token';
  }
}

/**
 * ============================================
 * 验证错误
 * ============================================
 */

/**
 * 输入验证错误类
 */
class ValidationError extends ApiError {
  constructor(message = '输入验证失败', validationErrors = [], code = 'VALIDATION_ERROR') {
    const details = {
      validation_errors: validationErrors,
      error_count: validationErrors.length
    };
    
    super(code, message, 400, details);
    this.category = 'validation';
    this.validationErrors = validationErrors;
  }
  
  /**
   * 添加验证错误
   * @param {string} field 字段名
   * @param {string} message 错误消息
   * @param {any} value 字段值
   */
  addError(field, message, value = undefined) {
    const error = { field, message };
    if (value !== undefined) {
      error.value = value;
    }
    
    this.validationErrors.push(error);
    this.details.validation_errors = this.validationErrors;
    this.details.error_count = this.validationErrors.length;
  }
}

/**
 * 业务规则验证错误类
 */
class BusinessRuleError extends ApiError {
  constructor(message = '业务规则验证失败', code = 'BUSINESS_RULE_ERROR', details = null) {
    super(code, message, 400, details);
    this.category = 'business_rule';
  }
}

/**
 * ============================================
 * 资源错误
 * ============================================
 */

/**
 * 资源未找到错误类
 */
class NotFoundError extends ApiError {
  constructor(resource = 'Resource', resourceId = '', code = 'RESOURCE_NOT_FOUND') {
    const message = `${resource}不存在`;
    const details = {
      resource_type: resource,
      resource_id: resourceId
    };
    
    super(code, message, 404, details);
    this.category = 'not_found';
    this.resource = resource;
    this.resourceId = resourceId;
  }
}

/**
 * 资源冲突错误类
 */
class ConflictError extends ApiError {
  constructor(message = '资源冲突', code = 'RESOURCE_CONFLICT', details = null) {
    super(code, message, 409, details);
    this.category = 'conflict';
  }
}

/**
 * 资源已存在错误类
 */
class DuplicateError extends ApiError {
  constructor(resource = 'Resource', field = '', value = '', code = 'DUPLICATE_RESOURCE') {
    const message = `${resource}已存在`;
    const details = {
      resource_type: resource,
      duplicate_field: field,
      duplicate_value: value
    };
    
    super(code, message, 409, details);
    this.category = 'duplicate';
  }
}

/**
 * ============================================
 * 外部服务错误
 * ============================================
 */

/**
 * 外部服务错误类
 */
class ExternalServiceError extends ApiError {
  constructor(service, message = '外部服务错误', code = 'EXTERNAL_SERVICE_ERROR', details = null) {
    super(code, message, 503, details);
    this.category = 'external_service';
    this.service = service;
  }
}

/**
 * 数据库错误类
 */
class DatabaseError extends ApiError {
  constructor(message = '数据库操作失败', code = 'DATABASE_ERROR', details = null) {
    super(code, message, 500, details);
    this.category = 'database';
  }
}

/**
 * 缓存服务错误类
 */
class CacheError extends ApiError {
  constructor(message = '缓存服务错误', code = 'CACHE_ERROR', details = null) {
    super(code, message, 500, details);
    this.category = 'cache';
  }
}

/**
 * 邮件服务错误类
 */
class EmailServiceError extends ApiError {
  constructor(message = '邮件发送失败', code = 'EMAIL_SERVICE_ERROR', details = null) {
    super(code, message, 500, details);
    this.category = 'email';
  }
}

/**
 * ============================================
 * 限流错误
 * ============================================
 */

/**
 * 限流错误类
 */
class RateLimitError extends ApiError {
  constructor(limit, windowMs, code = 'RATE_LIMIT_EXCEEDED') {
    const message = '请求过于频繁，请稍后再试';
    const details = {
      limit,
      window_ms: windowMs,
      retry_after: Math.ceil(windowMs / 1000)
    };
    
    super(code, message, 429, details);
    this.category = 'rate_limit';
    this.limit = limit;
    this.windowMs = windowMs;
  }
}

/**
 * ============================================
 * 区块链相关错误
 * ============================================
 */

/**
 * 钱包错误类
 */
class WalletError extends ApiError {
  constructor(message = '钱包操作失败', code = 'WALLET_ERROR', details = null) {
    super(code, message, 400, details);
    this.category = 'wallet';
  }
}

/**
 * 区块链网络错误类
 */
class BlockchainNetworkError extends ApiError {
  constructor(network = 'blockchain', message = '区块链网络错误', code = 'BLOCKCHAIN_ERROR', details = null) {
    super(code, message, 503, details);
    this.category = 'blockchain';
    this.network = network;
  }
}

/**
 * 智能合约错误类
 */
class SmartContractError extends ApiError {
  constructor(contract, message = '智能合约执行失败', code = 'SMART_CONTRACT_ERROR', details = null) {
    super(code, message, 400, details);
    this.category = 'smart_contract';
    this.contract = contract;
  }
}

/**
 * ============================================
 * 游戏业务错误
 * ============================================
 */

/**
 * 游戏状态错误类
 */
class GameStateError extends ApiError {
  constructor(message = '游戏状态错误', code = 'GAME_STATE_ERROR', details = null) {
    super(code, message, 400, details);
    this.category = 'game_state';
  }
}

/**
 * 竞猜错误类
 */
class PredictionError extends ApiError {
  constructor(message = '竞猜操作失败', code = 'PREDICTION_ERROR', details = null) {
    super(code, message, 400, details);
    this.category = 'prediction';
  }
}

/**
 * 奖励错误类
 */
class RewardError extends ApiError {
  constructor(message = '奖励发放失败', code = 'REWARD_ERROR', details = null) {
    super(code, message, 500, details);
    this.category = 'reward';
  }
}

/**
 * ============================================
 * 系统错误
 * ============================================
 */

/**
 * 配置错误类
 */
class ConfigurationError extends ApiError {
  constructor(message = '系统配置错误', code = 'CONFIGURATION_ERROR', details = null) {
    super(code, message, 500, details, false); // 非操作性错误
    this.category = 'configuration';
  }
}

/**
 * 内部服务器错误类
 */
class InternalServerError extends ApiError {
  constructor(message = '内部服务器错误', code = 'INTERNAL_SERVER_ERROR', details = null) {
    super(code, message, 500, details, false); // 非操作性错误
    this.category = 'internal';
  }
}

/**
 * 服务不可用错误类
 */
class ServiceUnavailableError extends ApiError {
  constructor(message = '服务暂时不可用', code = 'SERVICE_UNAVAILABLE', details = null) {
    super(code, message, 503, details);
    this.category = 'service_unavailable';
  }
}

/**
 * ============================================
 * 错误工厂函数
 * ============================================
 */

/**
 * 错误工厂类
 */
class ErrorFactory {
  /**
   * 根据错误代码创建错误实例
   * @param {string} code 错误代码
   * @param {string} message 错误消息
   * @param {any} details 错误详情
   * @returns {ApiError} 错误实例
   */
  static create(code, message, details = null) {
    const errorMap = {
      // 认证错误
      'AUTH_FAILED': () => new AuthenticationError(message, code, details),
      'AUTH_TOKEN_INVALID': () => new TokenError(message, code, details),
      'AUTH_TOKEN_EXPIRED': () => new TokenError(message, code, details),
      'PERMISSION_DENIED': () => new AuthorizationError(message, code, details),
      
      // 验证错误
      'VALIDATION_ERROR': () => new ValidationError(message, details?.validation_errors || [], code),
      'BUSINESS_RULE_ERROR': () => new BusinessRuleError(message, code, details),
      
      // 资源错误
      'RESOURCE_NOT_FOUND': () => new NotFoundError(details?.resource_type || 'Resource', details?.resource_id || '', code),
      'RESOURCE_CONFLICT': () => new ConflictError(message, code, details),
      'DUPLICATE_RESOURCE': () => new DuplicateError(details?.resource_type || 'Resource', details?.field || '', details?.value || '', code),
      
      // 外部服务错误
      'DATABASE_ERROR': () => new DatabaseError(message, code, details),
      'CACHE_ERROR': () => new CacheError(message, code, details),
      'EMAIL_SERVICE_ERROR': () => new EmailServiceError(message, code, details),
      'EXTERNAL_SERVICE_ERROR': () => new ExternalServiceError(details?.service || 'Unknown', message, code, details),
      
      // 限流错误
      'RATE_LIMIT_EXCEEDED': () => new RateLimitError(details?.limit || 0, details?.window_ms || 0, code),
      
      // 区块链错误
      'WALLET_ERROR': () => new WalletError(message, code, details),
      'BLOCKCHAIN_ERROR': () => new BlockchainNetworkError(details?.network || 'blockchain', message, code, details),
      'SMART_CONTRACT_ERROR': () => new SmartContractError(details?.contract || 'unknown', message, code, details),
      
      // 游戏错误
      'GAME_STATE_ERROR': () => new GameStateError(message, code, details),
      'PREDICTION_ERROR': () => new PredictionError(message, code, details),
      'REWARD_ERROR': () => new RewardError(message, code, details),
      
      // 系统错误
      'CONFIGURATION_ERROR': () => new ConfigurationError(message, code, details),
      'INTERNAL_SERVER_ERROR': () => new InternalServerError(message, code, details),
      'SERVICE_UNAVAILABLE': () => new ServiceUnavailableError(message, code, details)
    };
    
    const creator = errorMap[code];
    return creator ? creator() : new ApiError(code, message, 500, details);
  }
  
  /**
   * 从标准Error创建ApiError
   * @param {Error} error 标准错误对象
   * @param {string} fallbackCode 备用错误代码
   * @returns {ApiError} API错误实例
   */
  static fromError(error, fallbackCode = 'INTERNAL_SERVER_ERROR') {
    if (error instanceof ApiError) {
      return error;
    }
    
    // 处理常见的Node.js错误
    const nodeErrorMap = {
      'ValidationError': 'VALIDATION_ERROR',
      'CastError': 'VALIDATION_ERROR',
      'MongoError': 'DATABASE_ERROR',
      'SequelizeError': 'DATABASE_ERROR',
      'JsonWebTokenError': 'AUTH_TOKEN_INVALID',
      'TokenExpiredError': 'AUTH_TOKEN_EXPIRED',
      'SyntaxError': 'VALIDATION_ERROR'
    };
    
    const code = nodeErrorMap[error.name] || fallbackCode;
    return ErrorFactory.create(code, error.message, {
      original_error: error.name,
      stack: error.stack
    });
  }
}

/**
 * ============================================
 * 错误助手函数
 * ============================================
 */

/**
 * 检查错误是否为操作性错误
 * @param {Error} error 错误对象
 * @returns {boolean} 是否为操作性错误
 */
const isOperationalError = (error) => {
  return error instanceof ApiError && error.isOperational;
};

/**
 * 获取错误的HTTP状态码
 * @param {Error} error 错误对象
 * @returns {number} HTTP状态码
 */
const getErrorStatusCode = (error) => {
  if (error instanceof ApiError) {
    return error.statusCode;
  }
  
  // 处理常见错误的状态码
  const statusCodeMap = {
    'ValidationError': 400,
    'CastError': 400,
    'JsonWebTokenError': 401,
    'TokenExpiredError': 401,
    'UnauthorizedError': 401,
    'ForbiddenError': 403,
    'NotFoundError': 404,
    'ConflictError': 409,
    'TooManyRequestsError': 429
  };
  
  return statusCodeMap[error.name] || 500;
};

module.exports = {
  // 基础错误类
  ApiError,
  
  // 认证授权错误
  AuthenticationError,
  AuthorizationError,
  TokenError,
  
  // 验证错误
  ValidationError,
  BusinessRuleError,
  
  // 资源错误
  NotFoundError,
  ConflictError,
  DuplicateError,
  
  // 外部服务错误
  ExternalServiceError,
  DatabaseError,
  CacheError,
  EmailServiceError,
  
  // 限流错误
  RateLimitError,
  
  // 区块链错误
  WalletError,
  BlockchainNetworkError,
  SmartContractError,
  
  // 游戏业务错误
  GameStateError,
  PredictionError,
  RewardError,
  
  // 系统错误
  ConfigurationError,
  InternalServerError,
  ServiceUnavailableError,
  
  // 工具类和函数
  ErrorFactory,
  isOperationalError,
  getErrorStatusCode
};
