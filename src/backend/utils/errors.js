/**
 * 自定义错误类
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

/**
 * API错误基类
 */
class APIError extends Error {
  constructor(
    message,
    statusCode = 500,
    code = 'INTERNAL_ERROR',
    details = null
  ) {
    super(message);
    this.name = 'APIError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.timestamp = new Date().toISOString();

    // 确保堆栈跟踪正确显示
    Error.captureStackTrace(this, APIError);
  }

  /**
   * 转换为JSON格式
   */
  toJSON() {
    return {
      name: this.name,
      message: this.message,
      statusCode: this.statusCode,
      code: this.code,
      details: this.details,
      timestamp: this.timestamp,
    };
  }
}

/**
 * 验证错误
 */
class ValidationError extends APIError {
  constructor(message, details = null) {
    super(message, 400, 'VALIDATION_ERROR', details);
    this.name = 'ValidationError';
  }
}

/**
 * 认证错误
 */
class AuthenticationError extends APIError {
  constructor(message = '认证失败') {
    super(message, 401, 'AUTHENTICATION_ERROR');
    this.name = 'AuthenticationError';
  }
}

/**
 * 授权错误
 */
class AuthorizationError extends APIError {
  constructor(message = '权限不足') {
    super(message, 403, 'AUTHORIZATION_ERROR');
    this.name = 'AuthorizationError';
  }
}

/**
 * 资源未找到错误
 */
class NotFoundError extends APIError {
  constructor(message = '资源未找到') {
    super(message, 404, 'NOT_FOUND');
    this.name = 'NotFoundError';
  }
}

/**
 * 冲突错误
 */
class ConflictError extends APIError {
  constructor(message = '资源冲突') {
    super(message, 409, 'CONFLICT');
    this.name = 'ConflictError';
  }
}

/**
 * 限流错误
 */
class RateLimitError extends APIError {
  constructor(message = '请求过于频繁') {
    super(message, 429, 'RATE_LIMIT_ERROR');
    this.name = 'RateLimitError';
  }
}

/**
 * 服务不可用错误
 */
class ServiceUnavailableError extends APIError {
  constructor(message = '服务暂时不可用') {
    super(message, 503, 'SERVICE_UNAVAILABLE');
    this.name = 'ServiceUnavailableError';
  }
}

module.exports = {
  APIError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  RateLimitError,
  ServiceUnavailableError,
};
