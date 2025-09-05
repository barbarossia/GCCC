# GCCC 认证授权模块 API 设计

## 模块概述

认证授权模块是 GCCC 系统的核心安全组件，负责用户身份验证、权限控制、会话管理等功能。该模块采用基于 JWT 的无状态认证和 RBAC 权限控制模型，支持钱包连接验证和传统邮箱密码认证两种方式。

## 架构设计

### 认证流程架构

```mermaid
graph TD
    A[客户端请求] --> B{认证类型}
    B -->|钱包认证| C[钱包连接]
    B -->|邮箱认证| D[邮箱密码验证]

    C --> E[签名验证]
    D --> F[密码验证]

    E --> G{验证成功?}
    F --> G

    G -->|是| H[生成JWT令牌]
    G -->|否| I[返回认证失败]

    H --> J[返回访问令牌]
    J --> K[后续API调用]
    K --> L[JWT验证中间件]
    L --> M{令牌有效?}
    M -->|是| N[权限检查]
    M -->|否| O[返回401]
    N --> P{有权限?}
    P -->|是| Q[执行业务逻辑]
    P -->|否| R[返回403]
```

### 权限控制架构 (RBAC)

```mermaid
graph LR
    A[用户 User] --> B[角色 Role]
    B --> C[权限 Permission]
    C --> D[资源 Resource]

    subgraph "角色类型"
        E[游客 Guest]
        F[普通用户 User]
        G[VIP用户 VIP]
        H[管理员 Admin]
        I[超级管理员 SuperAdmin]
    end

    subgraph "权限类型"
        J[读权限 Read]
        K[写权限 Write]
        L[删除权限 Delete]
        M[管理权限 Manage]
    end
```

## API 接口设计

### 1. 钱包连接认证

#### 1.1 请求连接随机消息

**接口信息**

- **URL**: `POST /api/v1/auth/wallet/challenge`
- **权限**: 公开访问
- **频率限制**: 100 次/小时

**请求参数**

```json
{
  "wallet_address": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
  "wallet_type": "solana"
}
```

| 参数           | 类型   | 必需 | 说明                       |
| -------------- | ------ | ---- | -------------------------- |
| wallet_address | string | ✅   | 钱包地址，50 字符以内      |
| wallet_type    | string | ✅   | 钱包类型: solana, ethereum |

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "challenge": "GCCC Authentication Challenge: 1725451200987 - Please sign this message to verify your wallet ownership",
    "challenge_id": "challenge_uuid_123",
    "expires_at": "2025-09-04T10:15:00.000Z"
  },
  "message": "请使用钱包签名此消息进行验证"
}
```

**错误响应**

```json
// 400 - 参数验证失败
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "钱包地址格式不正确",
    "details": {
      "field": "wallet_address",
      "constraint": "必须是有效的Solana钱包地址"
    }
  }
}

// 429 - 频率限制
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "请求过于频繁，请稍后再试",
    "details": {
      "retry_after": 3600
    }
  }
}
```

#### 1.2 验证钱包签名并登录

**接口信息**

- **URL**: `POST /api/v1/auth/wallet/verify`
- **权限**: 公开访问
- **频率限制**: 50 次/小时

**请求参数**

```json
{
  "wallet_address": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
  "challenge_id": "challenge_uuid_123",
  "signature": "signature_base64_encoded_string",
  "message": "GCCC Authentication Challenge: 1725451200987 - Please sign this message to verify your wallet ownership"
}
```

| 参数           | 类型   | 必需 | 说明           |
| -------------- | ------ | ---- | -------------- |
| wallet_address | string | ✅   | 钱包地址       |
| challenge_id   | string | ✅   | 挑战 ID        |
| signature      | string | ✅   | 签名字符串     |
| message        | string | ✅   | 签名的原始消息 |

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer",
    "expires_in": 86400,
    "user": {
      "id": "user_123",
      "wallet_address": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
      "username": "user_123",
      "email": null,
      "avatar_url": null,
      "role": "user",
      "level": 1,
      "experience": 0,
      "kyc_status": "pending",
      "created_at": "2025-09-04T10:00:00.000Z",
      "last_login_at": "2025-09-04T10:00:00.000Z"
    }
  },
  "message": "钱包验证成功，登录完成"
}
```

**错误响应**

```json
// 400 - 签名验证失败
{
  "success": false,
  "error": {
    "code": "AUTH_SIGNATURE_INVALID",
    "message": "钱包签名验证失败",
    "details": {
      "wallet_address": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    }
  }
}

// 410 - 挑战已过期
{
  "success": false,
  "error": {
    "code": "AUTH_CHALLENGE_EXPIRED",
    "message": "验证挑战已过期，请重新获取",
    "details": {
      "challenge_id": "challenge_uuid_123",
      "expired_at": "2025-09-04T10:15:00.000Z"
    }
  }
}
```

### 2. 邮箱密码认证

#### 2.1 用户注册

**接口信息**

- **URL**: `POST /api/v1/auth/register`
- **权限**: 公开访问
- **频率限制**: 20 次/小时

**请求参数**

```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePassword123!",
  "confirm_password": "SecurePassword123!",
  "referral_code": "REF123456",
  "terms_accepted": true,
  "privacy_accepted": true
}
```

| 参数             | 类型    | 必需 | 说明                                         |
| ---------------- | ------- | ---- | -------------------------------------------- |
| username         | string  | ✅   | 用户名，3-50 字符，字母数字下划线            |
| email            | string  | ✅   | 邮箱地址，有效格式                           |
| password         | string  | ✅   | 密码，8-128 字符，包含大小写字母数字特殊字符 |
| confirm_password | string  | ✅   | 确认密码，必须与 password 一致               |
| referral_code    | string  | ❌   | 推荐码，可选                                 |
| terms_accepted   | boolean | ✅   | 是否接受服务条款                             |
| privacy_accepted | boolean | ✅   | 是否接受隐私政策                             |

**成功响应** (201)

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_456",
      "username": "john_doe",
      "email": "john@example.com",
      "avatar_url": null,
      "role": "user",
      "level": 1,
      "experience": 0,
      "kyc_status": "pending",
      "referral_code": "JD789012",
      "created_at": "2025-09-04T10:00:00.000Z"
    },
    "verification": {
      "email_verification_required": true,
      "verification_email_sent": true
    }
  },
  "message": "注册成功，请查收邮箱验证链接"
}
```

**错误响应**

```json
// 409 - 用户名或邮箱已存在
{
  "success": false,
  "error": {
    "code": "CONFLICT_USER_EXISTS",
    "message": "用户名或邮箱已存在",
    "details": {
      "field": "email",
      "value": "john@example.com"
    }
  }
}

// 400 - 密码强度不足
{
  "success": false,
  "error": {
    "code": "VALIDATION_PASSWORD_WEAK",
    "message": "密码强度不足",
    "details": {
      "requirements": [
        "至少8个字符",
        "包含大写字母",
        "包含小写字母",
        "包含数字",
        "包含特殊字符"
      ]
    }
  }
}
```

#### 2.2 邮箱密码登录

**接口信息**

- **URL**: `POST /api/v1/auth/login`
- **权限**: 公开访问
- **频率限制**: 30 次/小时

**请求参数**

```json
{
  "login": "john@example.com",
  "password": "SecurePassword123!",
  "remember_me": true,
  "device_info": {
    "device_id": "device_uuid_123",
    "device_name": "John's iPhone",
    "platform": "ios",
    "app_version": "1.0.0"
  }
}
```

| 参数        | 类型    | 必需 | 说明             |
| ----------- | ------- | ---- | ---------------- |
| login       | string  | ✅   | 用户名或邮箱     |
| password    | string  | ✅   | 密码             |
| remember_me | boolean | ❌   | 是否记住登录状态 |
| device_info | object  | ❌   | 设备信息         |

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer",
    "expires_in": 86400,
    "user": {
      "id": "user_456",
      "username": "john_doe",
      "email": "john@example.com",
      "avatar_url": "https://example.com/avatar.jpg",
      "role": "user",
      "level": 5,
      "experience": 1250,
      "kyc_status": "approved",
      "last_login_at": "2025-09-04T10:00:00.000Z"
    },
    "permissions": [
      "user:read",
      "user:update",
      "proposal:read",
      "proposal:create",
      "vote:create",
      "points:read"
    ]
  },
  "message": "登录成功"
}
```

**错误响应**

```json
// 401 - 登录凭据无效
{
  "success": false,
  "error": {
    "code": "AUTH_INVALID_CREDENTIALS",
    "message": "用户名或密码错误",
    "details": {
      "login": "john@example.com"
    }
  }
}

// 423 - 账户被锁定
{
  "success": false,
  "error": {
    "code": "AUTH_ACCOUNT_LOCKED",
    "message": "账户已被锁定，请联系客服",
    "details": {
      "locked_until": "2025-09-04T12:00:00.000Z",
      "reason": "multiple_failed_attempts"
    }
  }
}
```

### 3. 令牌管理

#### 3.1 刷新访问令牌

**接口信息**

- **URL**: `POST /api/v1/auth/refresh`
- **权限**: 持有有效 refresh_token
- **频率限制**: 100 次/小时

**请求参数**

```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "message": "令牌刷新成功"
}
```

#### 3.2 验证令牌有效性

**接口信息**

- **URL**: `POST /api/v1/auth/verify`
- **权限**: 需要 Bearer Token
- **频率限制**: 1000 次/小时

**请求头**

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "valid": true,
    "user": {
      "id": "user_456",
      "username": "john_doe",
      "email": "john@example.com",
      "role": "user",
      "permissions": ["user:read", "user:update", "proposal:read"]
    },
    "token_info": {
      "issued_at": "2025-09-04T10:00:00.000Z",
      "expires_at": "2025-09-04T22:00:00.000Z",
      "remaining_time": 43200
    }
  },
  "message": "令牌有效"
}
```

#### 3.3 登出

**接口信息**

- **URL**: `POST /api/v1/auth/logout`
- **权限**: 需要 Bearer Token
- **频率限制**: 100 次/小时

**请求参数**

```json
{
  "logout_all_devices": false
}
```

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "logged_out": true,
    "logout_time": "2025-09-04T10:00:00.000Z"
  },
  "message": "登出成功"
}
```

### 4. 密码管理

#### 4.1 修改密码

**接口信息**

- **URL**: `PUT /api/v1/auth/password`
- **权限**: 需要 Bearer Token + user:update 权限
- **频率限制**: 10 次/小时

**请求参数**

```json
{
  "current_password": "OldPassword123!",
  "new_password": "NewPassword456!",
  "confirm_password": "NewPassword456!"
}
```

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "password_changed": true,
    "changed_at": "2025-09-04T10:00:00.000Z"
  },
  "message": "密码修改成功"
}
```

#### 4.2 忘记密码

**接口信息**

- **URL**: `POST /api/v1/auth/forgot-password`
- **权限**: 公开访问
- **频率限制**: 5 次/小时

**请求参数**

```json
{
  "email": "john@example.com"
}
```

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "email_sent": true,
    "reset_link_expires_in": 3600
  },
  "message": "密码重置链接已发送到您的邮箱"
}
```

#### 4.3 重置密码

**接口信息**

- **URL**: `POST /api/v1/auth/reset-password`
- **权限**: 需要有效的重置 token
- **频率限制**: 10 次/小时

**请求参数**

```json
{
  "reset_token": "reset_token_string",
  "new_password": "NewPassword456!",
  "confirm_password": "NewPassword456!"
}
```

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "password_reset": true,
    "auto_login": false
  },
  "message": "密码重置成功，请重新登录"
}
```

### 5. 权限管理

#### 5.1 获取当前用户权限

**接口信息**

- **URL**: `GET /api/v1/auth/permissions`
- **权限**: 需要 Bearer Token
- **频率限制**: 100 次/小时

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "user_id": "user_456",
    "role": "user",
    "permissions": [
      {
        "resource": "user",
        "actions": ["read", "update"]
      },
      {
        "resource": "proposal",
        "actions": ["read", "create"]
      },
      {
        "resource": "vote",
        "actions": ["create"]
      },
      {
        "resource": "points",
        "actions": ["read"]
      }
    ],
    "permission_strings": [
      "user:read",
      "user:update",
      "proposal:read",
      "proposal:create",
      "vote:create",
      "points:read"
    ]
  },
  "message": "权限获取成功"
}
```

#### 5.2 检查特定权限

**接口信息**

- **URL**: `POST /api/v1/auth/check-permission`
- **权限**: 需要 Bearer Token
- **频率限制**: 500 次/小时

**请求参数**

```json
{
  "permissions": ["proposal:create", "vote:create", "admin:read"]
}
```

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "checks": [
      {
        "permission": "proposal:create",
        "granted": true
      },
      {
        "permission": "vote:create",
        "granted": true
      },
      {
        "permission": "admin:read",
        "granted": false,
        "reason": "insufficient_role"
      }
    ],
    "all_granted": false
  },
  "message": "权限检查完成"
}
```

### 6. 会话管理

#### 6.1 获取活跃会话列表

**接口信息**

- **URL**: `GET /api/v1/auth/sessions`
- **权限**: 需要 Bearer Token + user:read 权限
- **频率限制**: 50 次/小时

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "session_id": "session_123",
        "device_info": {
          "device_name": "John's iPhone",
          "platform": "ios",
          "browser": "Safari",
          "ip_address": "192.168.1.100",
          "location": "北京, 中国"
        },
        "created_at": "2025-09-04T08:00:00.000Z",
        "last_active_at": "2025-09-04T10:00:00.000Z",
        "is_current": true,
        "expires_at": "2025-09-04T22:00:00.000Z"
      },
      {
        "session_id": "session_456",
        "device_info": {
          "device_name": "John's MacBook",
          "platform": "macos",
          "browser": "Chrome",
          "ip_address": "192.168.1.101",
          "location": "北京, 中国"
        },
        "created_at": "2025-09-03T14:00:00.000Z",
        "last_active_at": "2025-09-03T18:00:00.000Z",
        "is_current": false,
        "expires_at": "2025-09-04T02:00:00.000Z"
      }
    ],
    "total_sessions": 2,
    "active_sessions": 1
  },
  "message": "会话列表获取成功"
}
```

#### 6.2 撤销指定会话

**接口信息**

- **URL**: `DELETE /api/v1/auth/sessions/{session_id}`
- **权限**: 需要 Bearer Token + user:update 权限
- **频率限制**: 20 次/小时

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "session_revoked": true,
    "session_id": "session_456",
    "revoked_at": "2025-09-04T10:00:00.000Z"
  },
  "message": "会话已撤销"
}
```

#### 6.3 撤销所有其他会话

**接口信息**

- **URL**: `DELETE /api/v1/auth/sessions/others`
- **权限**: 需要 Bearer Token + user:update 权限
- **频率限制**: 10 次/小时

**成功响应** (200)

```json
{
  "success": true,
  "data": {
    "sessions_revoked": 3,
    "current_session_preserved": true,
    "revoked_at": "2025-09-04T10:00:00.000Z"
  },
  "message": "其他会话已全部撤销"
}
```

## 安全实现

### 1. JWT 令牌安全

#### 令牌结构

```javascript
// JWT Header
{
  "alg": "HS256",
  "typ": "JWT"
}

// JWT Payload
{
  "sub": "user_456",                    // 用户ID
  "iss": "gccc-api",                    // 签发者
  "aud": "gccc-client",                 // 接收者
  "exp": 1725451200,                    // 过期时间
  "iat": 1725447600,                    // 签发时间
  "nbf": 1725447600,                    // 生效时间
  "jti": "token_uuid_123",              // 令牌唯一ID
  "type": "access",                     // 令牌类型: access/refresh
  "session_id": "session_123",          // 会话ID
  "user": {
    "id": "user_456",
    "username": "john_doe",
    "email": "john@example.com",
    "role": "user",
    "permissions": ["user:read", "user:update"]
  },
  "device": {
    "device_id": "device_uuid_123",
    "platform": "ios"
  }
}
```

#### 令牌配置

```javascript
const jwtConfig = {
  // 访问令牌
  access_token: {
    secret: process.env.JWT_ACCESS_SECRET,
    algorithm: "HS256",
    expiresIn: "12h", // 12小时
    issuer: "gccc-api",
    audience: "gccc-client",
  },

  // 刷新令牌
  refresh_token: {
    secret: process.env.JWT_REFRESH_SECRET,
    algorithm: "HS256",
    expiresIn: "7d", // 7天
    issuer: "gccc-api",
    audience: "gccc-client",
  },
};
```

### 2. 密码安全策略

#### 密码强度要求

```javascript
const passwordPolicy = {
  minLength: 8,
  maxLength: 128,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  forbiddenPatterns: [
    "password",
    "12345678",
    "qwerty",
    // 常见弱密码模式
  ],
  noReuse: 5, // 不能重复使用最近5个密码
  maxAge: 90, // 密码最长90天有效期
};
```

#### 密码加密存储

```javascript
const bcrypt = require("bcrypt");

// 密码加密
const hashPassword = async (password) => {
  const saltRounds = 12;
  return await bcrypt.hash(password, saltRounds);
};

// 密码验证
const verifyPassword = async (password, hash) => {
  return await bcrypt.compare(password, hash);
};
```

### 3. 钱包签名验证

#### Solana 签名验证

```javascript
const { verifySignature } = require("@solana/web3.js");
const { PublicKey } = require("@solana/web3.js");

const verifyWalletSignature = async (walletAddress, message, signature) => {
  try {
    const publicKey = new PublicKey(walletAddress);
    const messageBytes = new TextEncoder().encode(message);
    const signatureBytes = Buffer.from(signature, "base64");

    const isValid = verifySignature(messageBytes, signatureBytes, publicKey);
    return isValid;
  } catch (error) {
    return false;
  }
};
```

### 4. 权限控制实现

#### RBAC 权限模型

```javascript
// 角色权限配置
const rolePermissions = {
  guest: [],
  user: [
    "user:read",
    "user:update",
    "proposal:read",
    "proposal:create",
    "vote:create",
    "points:read",
    "staking:read",
    "staking:create",
    "lottery:read",
    "lottery:participate",
    "nft:read",
  ],
  vip: [
    // 继承user权限
    ...rolePermissions.user,
    "proposal:featured",
    "staking:priority",
    "lottery:priority",
  ],
  admin: [
    // 用户管理
    "user:*",
    "admin:read",
    "admin:create",

    // 提案管理
    "proposal:*",
    "vote:*",

    // 系统管理
    "system:read",
    "system:update",
    "config:read",
    "config:update",

    // 监控管理
    "monitor:read",
    "logs:read",
  ],
  superadmin: ["*:*"], // 所有权限
};
```

#### 权限检查中间件

```javascript
const requirePermissions = (requiredPermissions) => {
  return (req, res, next) => {
    const userPermissions = req.user.permissions || [];

    const hasPermission = requiredPermissions.every((permission) => {
      // 检查是否有通配符权限
      if (userPermissions.includes("*:*")) return true;

      // 检查具体权限
      if (userPermissions.includes(permission)) return true;

      // 检查资源通配符权限
      const [resource, action] = permission.split(":");
      if (userPermissions.includes(`${resource}:*`)) return true;

      return false;
    });

    if (!hasPermission) {
      return res.status(403).json({
        success: false,
        error: {
          code: "PERMISSION_DENIED",
          message: "权限不足",
          details: {
            required_permissions: requiredPermissions,
            user_permissions: userPermissions,
          },
        },
      });
    }

    next();
  };
};
```

### 5. 安全防护措施

#### 登录失败限制

```javascript
const loginAttemptLimiter = {
  windowMs: 15 * 60 * 1000, // 15分钟窗口
  maxAttempts: 5, // 最多5次失败
  blockDuration: 60 * 60 * 1000, // 锁定1小时

  // IP级别限制
  ipWindowMs: 60 * 60 * 1000, // 1小时窗口
  ipMaxAttempts: 20, // IP最多20次失败
  ipBlockDuration: 24 * 60 * 60 * 1000, // 锁定24小时
};
```

#### 会话安全

```javascript
const sessionConfig = {
  secure: true, // 仅HTTPS传输
  httpOnly: true, // 防止XSS攻击
  sameSite: "strict", // 防止CSRF攻击
  maxAge: 12 * 60 * 60 * 1000, // 12小时过期
  rolling: true, // 活动时自动续期

  // 会话固定防护
  regenerateOnLogin: true,

  // 设备指纹验证
  deviceFingerprintRequired: true,
};
```

## 错误处理

### 认证错误代码

| 错误代码                 | HTTP 状态码 | 说明           |
| ------------------------ | ----------- | -------------- |
| AUTH_TOKEN_MISSING       | 401         | 缺少访问令牌   |
| AUTH_TOKEN_INVALID       | 401         | 无效的访问令牌 |
| AUTH_TOKEN_EXPIRED       | 401         | 访问令牌已过期 |
| AUTH_TOKEN_MALFORMED     | 401         | 令牌格式错误   |
| AUTH_INVALID_CREDENTIALS | 401         | 登录凭据无效   |
| AUTH_SIGNATURE_INVALID   | 401         | 钱包签名无效   |
| AUTH_CHALLENGE_EXPIRED   | 410         | 验证挑战已过期 |
| AUTH_ACCOUNT_LOCKED      | 423         | 账户被锁定     |
| AUTH_ACCOUNT_DISABLED    | 423         | 账户被禁用     |
| AUTH_EMAIL_NOT_VERIFIED  | 403         | 邮箱未验证     |
| PERMISSION_DENIED        | 403         | 权限不足       |
| PERMISSION_INVALID_ROLE  | 403         | 无效的角色     |

### 统一错误处理

```javascript
const authErrorHandler = (error, req, res, next) => {
  const errorMap = {
    TokenExpiredError: {
      code: "AUTH_TOKEN_EXPIRED",
      status: 401,
      message: "访问令牌已过期",
    },
    JsonWebTokenError: {
      code: "AUTH_TOKEN_INVALID",
      status: 401,
      message: "无效的访问令牌",
    },
    SignatureVerificationError: {
      code: "AUTH_SIGNATURE_INVALID",
      status: 401,
      message: "钱包签名验证失败",
    },
  };

  const errorInfo = errorMap[error.name] || {
    code: "AUTH_UNKNOWN_ERROR",
    status: 500,
    message: "认证服务异常",
  };

  res.status(errorInfo.status).json({
    success: false,
    error: {
      code: errorInfo.code,
      message: errorInfo.message,
      details: process.env.NODE_ENV === "development" ? error.stack : undefined,
    },
    timestamp: new Date().toISOString(),
  });
};
```

## 测试用例

### 单元测试示例

```javascript
describe("Authentication API", () => {
  describe("POST /api/v1/auth/wallet/challenge", () => {
    it("应该为有效的钱包地址生成挑战", async () => {
      const response = await request(app)
        .post("/api/v1/auth/wallet/challenge")
        .send({
          wallet_address: "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
          wallet_type: "solana",
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.challenge).toContain(
        "GCCC Authentication Challenge"
      );
      expect(response.body.data.challenge_id).toBeDefined();
    });

    it("应该拒绝无效的钱包地址", async () => {
      const response = await request(app)
        .post("/api/v1/auth/wallet/challenge")
        .send({
          wallet_address: "invalid_address",
          wallet_type: "solana",
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe("VALIDATION_ERROR");
    });
  });

  describe("POST /api/v1/auth/login", () => {
    it("应该允许有效凭据登录", async () => {
      const response = await request(app)
        .post("/api/v1/auth/login")
        .send({
          login: "test@example.com",
          password: "TestPassword123!",
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.access_token).toBeDefined();
      expect(response.body.data.user.email).toBe("test@example.com");
    });
  });
});
```

### 集成测试示例

```javascript
describe("Authentication Flow", () => {
  it("完整的钱包认证流程", async () => {
    // 1. 请求挑战
    const challengeResponse = await request(app)
      .post("/api/v1/auth/wallet/challenge")
      .send({
        wallet_address: testWalletAddress,
        wallet_type: "solana",
      });

    const { challenge, challenge_id } = challengeResponse.body.data;

    // 2. 生成签名
    const signature = await signMessage(challenge, testPrivateKey);

    // 3. 验证签名并登录
    const loginResponse = await request(app)
      .post("/api/v1/auth/wallet/verify")
      .send({
        wallet_address: testWalletAddress,
        challenge_id,
        signature,
        message: challenge,
      })
      .expect(200);

    const { access_token } = loginResponse.body.data;

    // 4. 使用令牌访问受保护资源
    const profileResponse = await request(app)
      .get("/api/v1/auth/permissions")
      .set("Authorization", `Bearer ${access_token}`)
      .expect(200);

    expect(profileResponse.body.data.permissions).toContain("user:read");
  });
});
```

## 性能优化

### 1. 缓存策略

```javascript
// Redis缓存配置
const cacheConfig = {
  // 挑战缓存
  challenge: {
    prefix: "auth:challenge:",
    ttl: 15 * 60, // 15分钟
  },

  // 用户会话缓存
  session: {
    prefix: "auth:session:",
    ttl: 12 * 60 * 60, // 12小时
  },

  // 用户权限缓存
  permissions: {
    prefix: "auth:permissions:",
    ttl: 30 * 60, // 30分钟
  },

  // 登录失败计数
  loginAttempts: {
    prefix: "auth:attempts:",
    ttl: 60 * 60, // 1小时
  },
};
```

### 2. 数据库优化

```sql
-- 用户表索引优化
CREATE INDEX idx_users_email ON users(email) WHERE status = 'active';
CREATE INDEX idx_users_username ON users(username) WHERE status = 'active';
CREATE INDEX idx_user_wallets_address ON user_wallets(wallet_address);

-- 会话表分区
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    token_hash VARCHAR(128) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (created_at);
```

### 3. 性能监控指标

- **登录响应时间**: 目标 < 200ms
- **令牌验证时间**: 目标 < 50ms
- **权限检查时间**: 目标 < 10ms
- **签名验证时间**: 目标 < 100ms
- **并发登录数**: 支持 1000+ QPS

---

> 📘 **注意**: 认证授权是系统安全的核心，实现时应严格遵循安全最佳实践，定期进行安全审计和渗透测试。
