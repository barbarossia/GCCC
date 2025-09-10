/**
 * 验证中间件
 *
 * @author GCCC Development Team
 * @version 1.0.0
 */

const { validationResult } = require('express-validator');
const logger = require('../utils/logger');
const { createErrorResponse } = require('../utils/response');

/**
 * 处理验证结果的中间件
 * @param {Object} req - Express request对象
 * @param {Object} res - Express response对象
 * @param {Function} next - Next函数
 */
const handleValidationErrors = (req, res, next) => {
  try {
    const errors = validationResult(req);

    if (!errors.isEmpty()) {
      const errorMessages = errors.array().map((error) => ({
        field: error.path,
        message: error.msg,
        value: error.value,
      }));

      logger.warn('请求验证失败:', {
        path: req.path,
        method: req.method,
        errors: errorMessages,
        body: req.body,
        params: req.params,
        query: req.query,
      });

      return res
        .status(400)
        .json(
          createErrorResponse(
            '请求参数验证失败',
            'VALIDATION_ERROR',
            errorMessages
          )
        );
    }

    next();
  } catch (error) {
    logger.error('验证中间件错误:', error);
    return res
      .status(500)
      .json(createErrorResponse('服务器内部错误', 'INTERNAL_ERROR'));
  }
};

module.exports = {
  handleValidationErrors,
};
