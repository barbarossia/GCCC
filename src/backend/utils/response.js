/**
 * GCCC API响应工具类
 * 
 * 提供统一的API响应格式，包括成功响应和错误响应
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

/**
 * API响应基础结构
 * {
 *   success: boolean,
 *   data?: any,
 *   error?: object,
 *   message: string,
 *   timestamp: string,
 *   request_id?: string
 * }
 */

/**
 * ============================================
 * 成功响应
 * ============================================
 */

/**
 * 创建成功响应
 * @param {any} data 响应数据
 * @param {string} message 响应消息
 * @param {Object} metadata 附加元数据
 * @returns {Object} 标准成功响应格式
 */
const createSuccessResponse = (data = null, message = 'success', metadata = {}) => {
  const response = {
    success: true,
    data,
    message,
    timestamp: new Date().toISOString(),
    ...metadata
  };
  
  // 如果提供了请求ID，添加到响应中
  if (metadata.request_id) {
    response.request_id = metadata.request_id;
  }
  
  return response;
};

/**
 * 创建分页响应
 * @param {Array} items 数据项目
 * @param {Object} pagination 分页信息
 * @param {string} message 响应消息
 * @param {Object} metadata 附加元数据
 * @returns {Object} 分页响应格式
 */
const createPaginatedResponse = (items = [], pagination = {}, message = 'success', metadata = {}) => {
  const {
    page = 1,
    limit = 20,
    total = items.length,
    total_pages = Math.ceil(total / limit)
  } = pagination;
  
  return createSuccessResponse({
    items,
    pagination: {
      current_page: page,
      per_page: limit,
      total_items: total,
      total_pages,
      has_next_page: page < total_pages,
      has_prev_page: page > 1
    }
  }, message, metadata);
};

/**
 * 创建列表响应
 * @param {Array} list 列表数据
 * @param {Object} summary 汇总信息
 * @param {string} message 响应消息
 * @param {Object} metadata 附加元数据
 * @returns {Object} 列表响应格式
 */
const createListResponse = (list = [], summary = {}, message = 'success', metadata = {}) => {
  return createSuccessResponse({
    list,
    summary: {
      total_count: list.length,
      ...summary
    }
  }, message, metadata);
};

/**
 * 创建创建操作响应
 * @param {any} resource 创建的资源
 * @param {string} resourceType 资源类型
 * @param {Object} metadata 附加元数据
 * @returns {Object} 创建响应格式
 */
const createCreatedResponse = (resource, resourceType = 'resource', metadata = {}) => {
  return createSuccessResponse(resource, `${resourceType}创建成功`, {
    ...metadata,
    action: 'created'
  });
};

/**
 * 创建更新操作响应
 * @param {any} resource 更新的资源
 * @param {string} resourceType 资源类型
 * @param {Object} metadata 附加元数据
 * @returns {Object} 更新响应格式
 */
const createUpdatedResponse = (resource, resourceType = 'resource', metadata = {}) => {
  return createSuccessResponse(resource, `${resourceType}更新成功`, {
    ...metadata,
    action: 'updated'
  });
};

/**
 * 创建删除操作响应
 * @param {string} resourceId 删除的资源ID
 * @param {string} resourceType 资源类型
 * @param {Object} metadata 附加元数据
 * @returns {Object} 删除响应格式
 */
const createDeletedResponse = (resourceId, resourceType = 'resource', metadata = {}) => {
  return createSuccessResponse({
    deleted_id: resourceId,
    deleted_at: new Date().toISOString()
  }, `${resourceType}删除成功`, {
    ...metadata,
    action: 'deleted'
  });
};

/**
 * ============================================
 * 错误响应
 * ============================================
 */

/**
 * 创建错误响应
 * @param {Error|Object} error 错误对象或错误信息
 * @param {Object} metadata 附加元数据
 * @returns {Object} 标准错误响应格式
 */
const createErrorResponse = (error, metadata = {}) => {
  let errorInfo;
  
  // 处理不同类型的错误
  if (error instanceof Error) {
    errorInfo = {
      code: error.code || 'INTERNAL_ERROR',
      message: error.message || '内部服务器错误',
      details: error.details || null,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    };
  } else if (typeof error === 'object') {
    errorInfo = {
      code: error.code || 'UNKNOWN_ERROR',
      message: error.message || '未知错误',
      details: error.details || null
    };
  } else {
    errorInfo = {
      code: 'GENERIC_ERROR',
      message: error?.toString() || '发生错误',
      details: null
    };
  }
  
  const response = {
    success: false,
    error: errorInfo,
    message: errorInfo.message,
    timestamp: new Date().toISOString(),
    ...metadata
  };
  
  // 添加请求ID用于错误追踪
  if (metadata.request_id) {
    response.request_id = metadata.request_id;
  }
  
  return response;
};

/**
 * 创建验证错误响应
 * @param {Array} validationErrors 验证错误数组
 * @param {string} message 错误消息
 * @param {Object} metadata 附加元数据
 * @returns {Object} 验证错误响应格式
 */
const createValidationErrorResponse = (validationErrors = [], message = '输入验证失败', metadata = {}) => {
  return createErrorResponse({
    code: 'VALIDATION_ERROR',
    message,
    details: {
      validation_errors: validationErrors,
      error_count: validationErrors.length
    }
  }, metadata);
};

/**
 * 创建认证错误响应
 * @param {string} message 错误消息
 * @param {string} code 错误代码
 * @param {Object} metadata 附加元数据
 * @returns {Object} 认证错误响应格式
 */
const createAuthErrorResponse = (message = '认证失败', code = 'AUTH_FAILED', metadata = {}) => {
  return createErrorResponse({
    code,
    message,
    details: {
      auth_required: true,
      ...metadata.details
    }
  }, metadata);
};

/**
 * 创建权限错误响应
 * @param {string} message 错误消息
 * @param {Array} requiredPermissions 所需权限
 * @param {Object} metadata 附加元数据
 * @returns {Object} 权限错误响应格式
 */
const createPermissionErrorResponse = (
  message = '权限不足', 
  requiredPermissions = [], 
  metadata = {}
) => {
  return createErrorResponse({
    code: 'PERMISSION_DENIED',
    message,
    details: {
      required_permissions: requiredPermissions,
      ...metadata.details
    }
  }, metadata);
};

/**
 * 创建资源未找到错误响应
 * @param {string} resourceType 资源类型
 * @param {string} resourceId 资源ID
 * @param {Object} metadata 附加元数据
 * @returns {Object} 资源未找到错误响应格式
 */
const createNotFoundErrorResponse = (
  resourceType = 'resource', 
  resourceId = '', 
  metadata = {}
) => {
  return createErrorResponse({
    code: 'RESOURCE_NOT_FOUND',
    message: `${resourceType}不存在`,
    details: {
      resource_type: resourceType,
      resource_id: resourceId,
      ...metadata.details
    }
  }, metadata);
};

/**
 * 创建冲突错误响应
 * @param {string} message 错误消息
 * @param {string} conflictReason 冲突原因
 * @param {Object} metadata 附加元数据
 * @returns {Object} 冲突错误响应格式
 */
const createConflictErrorResponse = (
  message = '资源冲突', 
  conflictReason = '', 
  metadata = {}
) => {
  return createErrorResponse({
    code: 'RESOURCE_CONFLICT',
    message,
    details: {
      conflict_reason: conflictReason,
      ...metadata.details
    }
  }, metadata);
};

/**
 * 创建限流错误响应
 * @param {number} limit 限制次数
 * @param {number} windowMs 时间窗口（毫秒）
 * @param {Object} metadata 附加元数据
 * @returns {Object} 限流错误响应格式
 */
const createRateLimitErrorResponse = (limit, windowMs, metadata = {}) => {
  return createErrorResponse({
    code: 'RATE_LIMIT_EXCEEDED',
    message: '请求过于频繁，请稍后再试',
    details: {
      limit,
      window_ms: windowMs,
      retry_after: Math.ceil(windowMs / 1000),
      ...metadata.details
    }
  }, metadata);
};

/**
 * ============================================
 * 状态响应
 * ============================================
 */

/**
 * 创建健康检查响应
 * @param {boolean} isHealthy 是否健康
 * @param {Object} checks 检查结果
 * @param {Object} metadata 附加元数据
 * @returns {Object} 健康检查响应格式
 */
const createHealthCheckResponse = (isHealthy = true, checks = {}, metadata = {}) => {
  return {
    success: isHealthy,
    data: {
      status: isHealthy ? 'healthy' : 'unhealthy',
      checks,
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || '1.0.0'
    },
    message: isHealthy ? 'Service is healthy' : 'Service is unhealthy',
    timestamp: new Date().toISOString(),
    ...metadata
  };
};

/**
 * 创建API信息响应
 * @param {Object} apiInfo API信息
 * @param {Object} metadata 附加元数据
 * @returns {Object} API信息响应格式
 */
const createApiInfoResponse = (apiInfo = {}, metadata = {}) => {
  return createSuccessResponse({
    name: 'GCCC Backend API',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    documentation: process.env.API_DOC_URL || 'https://api.gccc.games/docs',
    support: 'support@gccc.games',
    ...apiInfo
  }, 'API信息获取成功', metadata);
};

/**
 * ============================================
 * 响应装饰器
 * ============================================
 */

/**
 * 为响应添加请求追踪ID
 * @param {Object} response 响应对象
 * @param {string} requestId 请求ID
 * @returns {Object} 包含请求ID的响应
 */
const addRequestId = (response, requestId) => {
  return {
    ...response,
    request_id: requestId
  };
};

/**
 * 为响应添加执行时间
 * @param {Object} response 响应对象
 * @param {number} startTime 开始时间戳
 * @returns {Object} 包含执行时间的响应
 */
const addExecutionTime = (response, startTime) => {
  const executionTime = Date.now() - startTime;
  return {
    ...response,
    execution_time_ms: executionTime
  };
};

/**
 * 为响应添加调试信息（仅开发环境）
 * @param {Object} response 响应对象
 * @param {Object} debugInfo 调试信息
 * @returns {Object} 包含调试信息的响应
 */
const addDebugInfo = (response, debugInfo = {}) => {
  if (process.env.NODE_ENV !== 'development') {
    return response;
  }
  
  return {
    ...response,
    debug: {
      memory_usage: process.memoryUsage(),
      node_version: process.version,
      platform: process.platform,
      ...debugInfo
    }
  };
};

/**
 * ============================================
 * Express响应助手
 * ============================================
 */

/**
 * 发送成功响应
 * @param {Object} res Express响应对象
 * @param {any} data 响应数据
 * @param {string} message 响应消息
 * @param {number} statusCode 状态码
 * @param {Object} metadata 附加元数据
 */
const sendSuccess = (res, data = null, message = 'success', statusCode = 200, metadata = {}) => {
  const response = createSuccessResponse(data, message, metadata);
  res.status(statusCode).json(response);
};

/**
 * 发送错误响应
 * @param {Object} res Express响应对象
 * @param {Error|Object} error 错误对象
 * @param {number} statusCode 状态码
 * @param {Object} metadata 附加元数据
 */
const sendError = (res, error, statusCode = 500, metadata = {}) => {
  const response = createErrorResponse(error, metadata);
  res.status(statusCode).json(response);
};

/**
 * 发送分页响应
 * @param {Object} res Express响应对象
 * @param {Array} items 数据项目
 * @param {Object} pagination 分页信息
 * @param {string} message 响应消息
 * @param {number} statusCode 状态码
 * @param {Object} metadata 附加元数据
 */
const sendPaginated = (
  res, 
  items = [], 
  pagination = {}, 
  message = 'success', 
  statusCode = 200, 
  metadata = {}
) => {
  const response = createPaginatedResponse(items, pagination, message, metadata);
  res.status(statusCode).json(response);
};

module.exports = {
  // 成功响应
  createSuccessResponse,
  createPaginatedResponse,
  createListResponse,
  createCreatedResponse,
  createUpdatedResponse,
  createDeletedResponse,
  
  // 错误响应
  createErrorResponse,
  createValidationErrorResponse,
  createAuthErrorResponse,
  createPermissionErrorResponse,
  createNotFoundErrorResponse,
  createConflictErrorResponse,
  createRateLimitErrorResponse,
  
  // 状态响应
  createHealthCheckResponse,
  createApiInfoResponse,
  
  // 响应装饰器
  addRequestId,
  addExecutionTime,
  addDebugInfo,
  
  // Express助手
  sendSuccess,
  sendError,
  sendPaginated
};
