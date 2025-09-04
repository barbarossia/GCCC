# GCCC 后端API文档

## 目录
- [概述](#概述)
- [认证与授权](#认证与授权)
- [用户管理API](#用户管理api)
- [权限管理API](#权限管理api)
- [积分系统API](#积分系统api)
- [提案投票API](#提案投票api)
- [质押系统API](#质押系统api)
- [抽奖系统API](#抽奖系统api)
- [NFT管理API](#nft管理api)
- [系统管理API](#系统管理api)
- [错误处理](#错误处理)
- [部署说明](#部署说明)

## 概述

GCCC 后端API基于 Node.js + Express 构建，提供完整的Web3 DApp后端服务，包括用户认证、权限管理、积分系统、提案投票等核心功能。

### 技术栈
- **框架**: Node.js + Express
- **数据库**: PostgreSQL
- **身份验证**: JWT + 钱包签名验证
- **区块链**: Solana Web3.js
- **缓存**: Redis (可选)

### API基础信息
- **Base URL**: `https://api.gccc.com` (生产环境) / `http://localhost:3000` (开发环境)
- **API版本**: v1
- **数据格式**: JSON
- **字符编码**: UTF-8

## 认证与授权

### 认证机制
GCCC使用基于钱包签名的Web3身份验证机制，结合JWT token进行会话管理。

#### 认证流程
1. 客户端请求随机数 (nonce)
2. 使用钱包私钥对消息进行签名
3. 提交签名进行验证
4. 服务器返回JWT token

#### 权限等级
- **Level 0**: 普通用户 - 基础功能权限
- **Level 1**: 版主 - 内容管理权限
- **Level 2**: 管理员 - 系统管理权限
- **Level 3**: 超级管理员 - 所有权限

#### 请求头格式
```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

## 用户管理API

### 1. 获取认证随机数

**接口**: `GET /api/auth/nonce`

**描述**: 获取用于钱包签名认证的随机数

**请求参数**:
```json
{
  "walletAddress": "string (required) - 钱包地址",
  "purpose": "string (optional) - 用途，默认为 'auth'"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "nonce": "a1b2c3d4e5f6g7h8",
    "message": "GCCC Login: a1b2c3d4e5f6g7h8\nTimestamp: 2025-08-11T10:30:00Z",
    "expiresAt": "2025-08-11T10:35:00Z"
  }
}
```

### 2. 用户注册

**接口**: `POST /api/auth/register`

**描述**: 注册新用户账户

**请求参数**:
```json
{
  "walletAddress": "string (required) - 钱包地址",
  "signature": "string (required) - 钱包签名",
  "message": "string (required) - 签名的消息",
  "nonce": "string (required) - 随机数",
  "username": "string (optional) - 用户名",
  "email": "string (optional) - 邮箱",
  "referralCode": "string (optional) - 推荐码"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "userId": 123,
    "username": "user123",
    "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
    "referralCode": "ABC123XYZ",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "expiresAt": "2025-08-12T10:30:00Z"
  },
  "message": "User registered successfully"
}
```

### 3. 用户登录

**接口**: `POST /api/auth/login`

**描述**: 用户登录验证

**请求参数**:
```json
{
  "walletAddress": "string (required) - 钱包地址",
  "signature": "string (required) - 钱包签名",
  "message": "string (required) - 签名的消息",
  "nonce": "string (required) - 随机数"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 123,
      "username": "user123",
      "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
      "email": "user@example.com",
      "avatarUrl": "https://example.com/avatar.jpg",
      "vipLevel": 0,
      "verificationLevel": 1,
      "isAdmin": false,
      "permissions": ["user.view", "proposal.create", "vote.view"],
      "roles": [
        {
          "roleId": 1,
          "roleName": "user",
          "roleLevel": 0
        }
      ]
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "expiresAt": "2025-08-12T10:30:00Z"
  },
  "message": "Login successful"
}
```

### 4. 刷新Token

**接口**: `POST /api/auth/refresh`

**描述**: 刷新访问令牌

**请求参数**:
```json
{
  "refreshToken": "string (required) - 刷新令牌"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "token": "new_jwt_token_here",
    "refreshToken": "new_refresh_token_here",
    "expiresAt": "2025-08-12T10:30:00Z"
  }
}
```

### 5. 用户登出

**接口**: `POST /api/auth/logout`

**描述**: 用户登出，清除会话

**认证**: 需要Bearer Token

**响应示例**:
```json
{
  "success": true,
  "message": "Logout successful"
}
```

### 6. 获取用户信息

**接口**: `GET /api/user/profile`

**描述**: 获取当前用户详细信息

**认证**: 需要Bearer Token

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 123,
    "username": "user123",
    "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
    "email": "user@example.com",
    "avatarUrl": "https://example.com/avatar.jpg",
    "vipLevel": 0,
    "verificationLevel": 1,
    "referralCode": "ABC123XYZ",
    "referredBy": null,
    "createdAt": "2025-01-01T00:00:00Z",
    "lastLoginAt": "2025-08-11T10:30:00Z",
    "wallets": [
      {
        "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
        "isPrimary": true,
        "nickname": "Main Wallet",
        "verifiedAt": "2025-01-01T00:00:00Z"
      }
    ],
    "referralStats": {
      "totalReferrals": 5,
      "activeReferrals": 3,
      "totalRewards": "1000.50"
    }
  }
}
```

### 7. 更新用户信息

**接口**: `PUT /api/user/profile`

**描述**: 更新用户个人信息

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "username": "string (optional) - 用户名",
  "email": "string (optional) - 邮箱",
  "avatarUrl": "string (optional) - 头像URL"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "id": 123,
    "username": "newusername",
    "email": "newemail@example.com",
    "avatarUrl": "https://example.com/newavatar.jpg",
    "updatedAt": "2025-08-11T10:30:00Z"
  },
  "message": "Profile updated successfully"
}
```

### 8. 绑定钱包

**接口**: `POST /api/user/wallets`

**描述**: 绑定新的钱包地址

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "walletAddress": "string (required) - 钱包地址",
  "signature": "string (required) - 钱包签名",
  "message": "string (required) - 签名的消息",
  "nonce": "string (required) - 随机数",
  "nickname": "string (optional) - 钱包别名"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "walletId": 456,
    "walletAddress": "9xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
    "nickname": "Secondary Wallet",
    "isPrimary": false,
    "verifiedAt": "2025-08-11T10:30:00Z"
  },
  "message": "Wallet bound successfully"
}
```

### 9. 获取推荐信息

**接口**: `GET /api/user/referrals`

**描述**: 获取用户推荐信息和奖励记录

**认证**: 需要Bearer Token

**查询参数**:
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "referralCode": "ABC123XYZ",
    "totalReferrals": 10,
    "activeReferrals": 8,
    "totalRewards": "2500.75",
    "pendingRewards": "100.25",
    "referralUrl": "https://gccc.com/register?ref=ABC123XYZ",
    "referrals": [
      {
        "id": 789,
        "username": "referreduser1",
        "walletAddress": "8xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
        "referredAt": "2025-07-01T00:00:00Z",
        "rewardAmount": "200.50",
        "rewardStatus": "paid",
        "level": 1
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 1,
      "totalItems": 10
    }
  }
}
```

## 权限管理API

### 1. 创建管理员

**接口**: `POST /api/admin/create`

**描述**: 创建新的管理员用户

**认证**: 需要Bearer Token (超级管理员权限)

**请求参数**:
```json
{
  "walletAddress": "string (required) - 钱包地址",
  "username": "string (required) - 用户名",
  "role": "string (required) - 角色名 (admin, super_admin, moderator)",
  "email": "string (optional) - 邮箱",
  "reason": "string (required) - 创建原因"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "userId": 456,
    "username": "newadmin",
    "walletAddress": "8xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
    "role": "admin",
    "adminLevel": 2,
    "createdAt": "2025-08-11T10:30:00Z"
  },
  "message": "Admin user created successfully"
}
```

### 2. 获取管理员列表

**接口**: `GET /api/admin/list`

**描述**: 获取所有管理员用户列表

**认证**: 需要Bearer Token (管理员权限)

**查询参数**:
- `role` (string, optional): 角色筛选
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "admins": [
      {
        "id": 1,
        "username": "superadmin",
        "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
        "email": "admin@gccc.com",
        "roleName": "super_admin",
        "roleDisplayName": "超级管理员",
        "roleLevel": 3,
        "grantedAt": "2025-01-01T00:00:00Z",
        "grantedBy": null
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 1,
      "totalItems": 5
    }
  }
}
```

### 3. 升级用户角色

**接口**: `POST /api/admin/promote/:userId`

**描述**: 升级用户角色权限

**认证**: 需要Bearer Token (超级管理员权限)

**请求参数**:
```json
{
  "role": "string (required) - 目标角色",
  "reason": "string (required) - 升级原因",
  "expiresAt": "string (optional) - 过期时间 ISO8601格式"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "User promoted successfully"
}
```

### 4. 撤销用户角色

**接口**: `POST /api/admin/demote/:userId`

**描述**: 撤销用户角色权限

**认证**: 需要Bearer Token (超级管理员权限)

**请求参数**:
```json
{
  "role": "string (required) - 要撤销的角色",
  "reason": "string (required) - 撤销原因"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "User role revoked successfully"
}
```

### 5. 获取用户权限

**接口**: `GET /api/user/:userId/permissions`

**描述**: 获取指定用户的所有权限

**认证**: 需要Bearer Token (管理员权限或查看自己的权限)

**响应示例**:
```json
{
  "success": true,
  "data": {
    "userId": 123,
    "roles": [
      {
        "roleId": 1,
        "roleName": "admin",
        "roleLevel": 2,
        "grantedAt": "2025-08-01T00:00:00Z"
      }
    ],
    "permissions": [
      {
        "permissionName": "user.view",
        "permissionDisplayName": "查看用户",
        "module": "user",
        "action": "read"
      },
      {
        "permissionName": "proposal.approve",
        "permissionDisplayName": "审核提案",
        "module": "proposal",
        "action": "approve"
      }
    ],
    "maxRoleLevel": 2,
    "isAdmin": true
  }
}
```

## 积分系统API

### 1. 每日签到

**接口**: `POST /api/points/checkin`

**描述**: 用户每日签到获取积分

**认证**: 需要Bearer Token

**响应示例**:
```json
{
  "success": true,
  "data": {
    "pointsEarned": 200,
    "totalPoints": 1500,
    "checkinDate": "2025-08-11",
    "consecutiveDays": 5,
    "bonusPoints": 50,
    "nextCheckinAt": "2025-08-12T00:00:00Z"
  },
  "message": "Daily check-in successful"
}
```

### 2. 获取积分余额

**接口**: `GET /api/points/balance`

**描述**: 获取用户当前积分余额

**认证**: 需要Bearer Token

**响应示例**:
```json
{
  "success": true,
  "data": {
    "currentPoints": 1500,
    "totalEarned": 5000,
    "totalSpent": 3500,
    "lastCheckinDate": "2025-08-11",
    "consecutiveDays": 5
  }
}
```

### 3. 积分交易记录

**接口**: `GET /api/points/transactions`

**描述**: 获取用户积分交易历史

**认证**: 需要Bearer Token

**查询参数**:
- `type` (string, optional): 交易类型 (earn, spend)
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20
- `startDate` (string, optional): 开始日期
- `endDate` (string, optional): 结束日期

**响应示例**:
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": 123,
        "type": "earn",
        "amount": 200,
        "source": "daily_checkin",
        "description": "每日签到奖励",
        "createdAt": "2025-08-11T10:30:00Z"
      },
      {
        "id": 122,
        "type": "spend",
        "amount": -100,
        "source": "lottery",
        "description": "抽奖消费",
        "createdAt": "2025-08-10T15:20:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 100
    },
    "summary": {
      "totalEarned": 3000,
      "totalSpent": 1500,
      "netGain": 1500
    }
  }
}
```

### 4. 积分转账

**接口**: `POST /api/points/transfer`

**描述**: 向其他用户转账积分

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "toUserId": "integer (required) - 接收用户ID",
  "amount": "integer (required) - 转账金额",
  "message": "string (optional) - 转账备注"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "transactionId": 789,
    "fromUserId": 123,
    "toUserId": 456,
    "amount": 100,
    "message": "朋友间积分转账",
    "createdAt": "2025-08-11T10:30:00Z",
    "remainingBalance": 1400
  },
  "message": "Points transferred successfully"
}
```

## 提案投票API

### 1. 创建提案

**接口**: `POST /api/proposals`

**描述**: 创建新的纪念币提案

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "title": "string (required) - 提案标题",
  "description": "string (required) - 提案描述",
  "eventName": "string (required) - 纪念事件名称",
  "imageUrl": "string (optional) - 提案图片URL",
  "eventDate": "string (required) - 事件日期 ISO8601格式",
  "coinLevel": "string (required) - 建议等级 (gold, silver, bronze, iron)",
  "tags": "array (optional) - 标签数组"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "proposalId": 789,
    "title": "纪念人工智能突破性进展",
    "description": "纪念2025年AI技术的重大突破...",
    "eventName": "AI Breakthrough 2025",
    "imageUrl": "https://example.com/proposal789.jpg",
    "creator": {
      "userId": 123,
      "username": "user123",
      "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
    },
    "status": "pending",
    "voteCount": 0,
    "createdAt": "2025-08-11T10:30:00Z",
    "votingStartsAt": "2025-08-11T00:00:00Z",
    "votingEndsAt": "2025-08-19T23:59:59Z"
  },
  "message": "Proposal created successfully"
}
```

### 2. 获取提案列表

**接口**: `GET /api/proposals`

**描述**: 获取提案列表

**查询参数**:
- `status` (string, optional): 提案状态 (pending, voting, completed, rejected)
- `phase` (string, optional): 当前阶段 (submission, voting, minting)
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认10

**响应示例**:
```json
{
  "success": true,
  "data": {
    "proposals": [
      {
        "proposalId": 789,
        "title": "纪念人工智能突破性进展",
        "description": "纪念2025年AI技术的重大突破...",
        "eventName": "AI Breakthrough 2025",
        "imageUrl": "https://example.com/proposal789.jpg",
        "creator": {
          "userId": 123,
          "username": "user123"
        },
        "status": "voting",
        "voteCount": 1250,
        "voteWeight": "125000.50",
        "rank": 1,
        "createdAt": "2025-08-01T00:00:00Z",
        "votingEndsAt": "2025-08-19T23:59:59Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 2,
      "totalItems": 10
    },
    "currentPhase": {
      "phase": "voting",
      "startDate": "2025-08-11T00:00:00Z",
      "endDate": "2025-08-19T23:59:59Z",
      "description": "投票阶段：社区成员可以对提案进行投票"
    }
  }
}
```

### 3. 获取提案详情

**接口**: `GET /api/proposals/:proposalId`

**描述**: 获取特定提案的详细信息

**响应示例**:
```json
{
  "success": true,
  "data": {
    "proposalId": 789,
    "title": "纪念人工智能突破性进展",
    "description": "纪念2025年AI技术的重大突破，包括GPT-5的发布和量子计算的商业化应用...",
    "eventName": "AI Breakthrough 2025",
    "eventDate": "2025-07-15T00:00:00Z",
    "imageUrl": "https://example.com/proposal789.jpg",
    "coinLevel": "gold",
    "tags": ["AI", "Technology", "Innovation"],
    "creator": {
      "userId": 123,
      "username": "user123",
      "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
      "avatarUrl": "https://example.com/avatar123.jpg"
    },
    "status": "voting",
    "voteCount": 1250,
    "voteWeight": "125000.50",
    "rank": 1,
    "totalVoters": 85,
    "createdAt": "2025-08-01T00:00:00Z",
    "votingStartsAt": "2025-08-11T00:00:00Z",
    "votingEndsAt": "2025-08-19T23:59:59Z",
    "userVote": {
      "hasVoted": true,
      "voteWeight": "1000.00",
      "votedAt": "2025-08-12T14:30:00Z"
    },
    "comments": [
      {
        "commentId": 456,
        "userId": 789,
        "username": "commenter1",
        "content": "这是一个很好的提案！",
        "createdAt": "2025-08-12T09:15:00Z"
      }
    ]
  }
}
```

### 4. 投票

**接口**: `POST /api/proposals/:proposalId/vote`

**描述**: 对提案进行投票

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "stakeAmount": "string (required) - 质押GCCC数量",
  "signature": "string (required) - 钱包签名",
  "txHash": "string (optional) - 链上交易哈希"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "voteId": 12345,
    "proposalId": 789,
    "userId": 123,
    "stakeAmount": "1000.00",
    "voteWeight": "1000.00",
    "txHash": "5j7K8L9M0N1O2P3Q4R5S6T7U8V9W0X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6N7O8P",
    "votedAt": "2025-08-11T10:30:00Z",
    "newTotalVotes": 1251,
    "newTotalWeight": "126000.50",
    "newRank": 1
  },
  "message": "Vote cast successfully"
}
```

### 5. 获取投票记录

**接口**: `GET /api/proposals/:proposalId/votes`

**描述**: 获取提案的投票记录

**查询参数**:
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "votes": [
      {
        "voteId": 12345,
        "userId": 123,
        "username": "voter1",
        "stakeAmount": "1000.00",
        "voteWeight": "1000.00",
        "txHash": "5j7K8L9M0N1O2P3Q4R5S6T7U8V9W0X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6N7O8P",
        "votedAt": "2025-08-11T10:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 85
    },
    "summary": {
      "totalVotes": 1250,
      "totalWeight": "125000.50",
      "averageStake": "100.00",
      "uniqueVoters": 85
    }
  }
}
```

## 质押系统API

### 1. 质押GCCC Token

**接口**: `POST /api/staking/stake`

**描述**: 质押GCCC Token参与治理

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "amount": "string (required) - 质押数量",
  "signature": "string (required) - 钱包签名",
  "txHash": "string (required) - 链上交易哈希"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "stakeId": 456,
    "userId": 123,
    "amount": "1000.00",
    "txHash": "5j7K8L9M0N1O2P3Q4R5S6T7U8V9W0X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6N7O8P",
    "stakedAt": "2025-08-11T10:30:00Z",
    "lockupPeriod": "30 days",
    "unlockAt": "2025-09-10T10:30:00Z",
    "estimatedReward": "50.00",
    "totalStaked": "5000.00"
  },
  "message": "Tokens staked successfully"
}
```

### 2. 赎回质押

**接口**: `POST /api/staking/unstake`

**描述**: 赎回质押的GCCC Token

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "stakeId": "integer (optional) - 特定质押ID，不提供则赎回所有可赎回的",
  "amount": "string (optional) - 赎回数量，不提供则全部赎回",
  "signature": "string (required) - 钱包签名"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "unstakeId": 789,
    "userId": 123,
    "amount": "1000.00",
    "rewards": "55.25",
    "totalAmount": "1055.25",
    "txHash": "6k8L9M0N1O2P3Q4R5S6T7U8V9W0X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6N7O8P9Q",
    "unstakedAt": "2025-09-10T10:30:00Z",
    "remainingStaked": "4000.00"
  },
  "message": "Tokens unstaked successfully"
}
```

### 3. 获取质押信息

**接口**: `GET /api/staking/info`

**描述**: 获取用户质押信息

**认证**: 需要Bearer Token

**响应示例**:
```json
{
  "success": true,
  "data": {
    "totalStaked": "5000.00",
    "availableToStake": "2000.00",
    "totalRewards": "125.75",
    "claimableRewards": "25.50",
    "votingPower": "5000.00",
    "lockupStatus": {
      "lockedAmount": "3000.00",
      "unlockableAmount": "2000.00",
      "nextUnlockAt": "2025-09-01T00:00:00Z"
    },
    "stakes": [
      {
        "stakeId": 456,
        "amount": "1000.00",
        "stakedAt": "2025-08-11T10:30:00Z",
        "lockupPeriod": "30 days",
        "unlockAt": "2025-09-10T10:30:00Z",
        "rewards": "55.25",
        "status": "locked"
      }
    ],
    "apy": "12.5%"
  }
}
```

### 4. 获取质押历史

**接口**: `GET /api/staking/history`

**描述**: 获取质押/赎回历史记录

**认证**: 需要Bearer Token

**查询参数**:
- `type` (string, optional): 操作类型 (stake, unstake)
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "history": [
      {
        "id": 789,
        "type": "stake",
        "amount": "1000.00",
        "txHash": "5j7K8L9M0N1O2P3Q4R5S6T7U8V9W0X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5M6N7O8P",
        "createdAt": "2025-08-11T10:30:00Z",
        "status": "confirmed"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 50
    }
  }
}
```

## 抽奖系统API

### 1. 进行抽奖

**接口**: `POST /api/lottery/draw`

**描述**: 使用积分进行抽奖

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "drawType": "string (required) - 抽奖类型 (daily, premium)",
  "drawCount": "integer (optional) - 抽奖次数，默认1"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "drawId": 12345,
    "drawType": "daily",
    "drawCount": 1,
    "pointsSpent": 100,
    "rewards": [
      {
        "type": "nft",
        "item": "Bronze Commemorative Coin",
        "level": "bronze",
        "quantity": 1,
        "value": "0.1 SOL",
        "imageUrl": "https://example.com/bronze-coin.jpg",
        "mintTxHash": "7m9N0O1P2Q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S"
      }
    ],
    "remainingPoints": 1400,
    "dailyDrawsRemaining": 1,
    "nextDrawAvailableAt": "2025-08-12T00:00:00Z",
    "drawnAt": "2025-08-11T10:30:00Z"
  },
  "message": "Lottery draw successful"
}
```

### 2. 获取抽奖记录

**接口**: `GET /api/lottery/history`

**描述**: 获取用户抽奖历史记录

**认证**: 需要Bearer Token

**查询参数**:
- `drawType` (string, optional): 抽奖类型筛选
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "draws": [
      {
        "drawId": 12345,
        "drawType": "daily",
        "pointsSpent": 100,
        "rewards": [
          {
            "type": "nft",
            "item": "Bronze Commemorative Coin",
            "level": "bronze",
            "quantity": 1,
            "value": "0.1 SOL"
          }
        ],
        "drawnAt": "2025-08-11T10:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 100
    },
    "statistics": {
      "totalDraws": 100,
      "totalPointsSpent": 10000,
      "totalRewardsValue": "15.5 SOL",
      "rareItemsWon": 3
    }
  }
}
```

### 3. 获取抽奖配置

**接口**: `GET /api/lottery/config`

**描述**: 获取抽奖系统配置和概率信息

**响应示例**:
```json
{
  "success": true,
  "data": {
    "drawTypes": {
      "daily": {
        "name": "每日抽奖",
        "cost": 100,
        "maxDrawsPerDay": 2,
        "description": "使用积分进行的每日抽奖"
      },
      "premium": {
        "name": "高级抽奖",
        "cost": 500,
        "maxDrawsPerDay": 5,
        "description": "更高概率获得稀有奖品"
      }
    },
    "rewards": {
      "gold_coin": {
        "name": "金质纪念币",
        "probability": 0.002,
        "value": "10 SOL",
        "rarity": "legendary"
      },
      "silver_coin": {
        "name": "银质纪念币",
        "probability": 0.033,
        "value": "1 SOL",
        "rarity": "rare"
      },
      "bronze_coin": {
        "name": "铜质纪念币",
        "probability": 0.1,
        "value": "0.1 SOL",
        "rarity": "uncommon"
      },
      "fragments": {
        "name": "纪念币碎片",
        "probability": 0.865,
        "value": "Variable",
        "rarity": "common"
      }
    },
    "userLimits": {
      "dailyDrawsRemaining": 2,
      "premiumDrawsRemaining": 5,
      "nextResetAt": "2025-08-12T00:00:00Z"
    }
  }
}
```

## NFT管理API

### 1. 获取用户NFT

**接口**: `GET /api/nft/collection`

**描述**: 获取用户拥有的所有NFT

**认证**: 需要Bearer Token

**查询参数**:
- `category` (string, optional): NFT类别 (commemorative_coin, fragment)
- `level` (string, optional): 等级筛选 (gold, silver, bronze, iron)
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "nfts": [
      {
        "nftId": 123,
        "tokenId": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
        "name": "AI Breakthrough 2025 - Gold",
        "description": "纪念2025年人工智能重大突破的金质纪念币",
        "category": "commemorative_coin",
        "level": "gold",
        "faceValue": "10 SOL",
        "imageUrl": "https://example.com/nft123.jpg",
        "attributes": {
          "event_name": "AI Breakthrough 2025",
          "issue_date": "2025-08-20",
          "serial_number": "001",
          "rarity": "legendary"
        },
        "mintedAt": "2025-08-20T10:00:00Z",
        "mintTxHash": "8n0O1P2Q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T",
        "isRedeemable": true,
        "marketValue": "12.5 SOL"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 50
    },
    "summary": {
      "totalNFTs": 50,
      "totalValue": "125.5 SOL",
      "byLevel": {
        "gold": 2,
        "silver": 8,
        "bronze": 25,
        "iron": 15
      }
    }
  }
}
```

### 2. 合成NFT

**接口**: `POST /api/nft/synthesize`

**描述**: 使用碎片合成纪念币

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "targetLevel": "string (required) - 目标等级 (bronze, silver, gold)",
  "fragmentTokens": "array (required) - 碎片Token地址数组",
  "signature": "string (required) - 钱包签名"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "synthesisId": 789,
    "targetLevel": "bronze",
    "fragmentsUsed": [
      "8n0O1P2Q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T",
      "9o1P2Q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T2U"
    ],
    "newNft": {
      "tokenId": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
      "name": "Synthesized Bronze Coin",
      "level": "bronze",
      "faceValue": "0.1 SOL",
      "imageUrl": "https://example.com/bronze-coin.jpg"
    },
    "txHash": "0p2Q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T2U3V",
    "synthesizedAt": "2025-08-11T10:30:00Z"
  },
  "message": "NFT synthesized successfully"
}
```

### 3. 赎回NFT

**接口**: `POST /api/nft/redeem`

**描述**: 赎回纪念币获取SOL

**认证**: 需要Bearer Token

**请求参数**:
```json
{
  "nftTokenId": "string (required) - NFT Token地址",
  "signature": "string (required) - 钱包签名"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "redemptionId": 456,
    "nftTokenId": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
    "nftName": "AI Breakthrough 2025 - Gold",
    "faceValue": "10 SOL",
    "redemptionAmount": "10.0",
    "burnTxHash": "1q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T2U3V4W",
    "paymentTxHash": "2r4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T2U3V4W5X",
    "redeemedAt": "2025-08-11T10:30:00Z"
  },
  "message": "NFT redeemed successfully"
}
```

### 4. NFT转账记录

**接口**: `GET /api/nft/transfers`

**描述**: 获取NFT转账历史记录

**认证**: 需要Bearer Token

**查询参数**:
- `type` (string, optional): 转账类型 (mint, transfer, burn, redeem)
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "transfers": [
      {
        "transferId": 123,
        "type": "mint",
        "nftTokenId": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
        "nftName": "AI Breakthrough 2025 - Gold",
        "fromAddress": null,
        "toAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
        "txHash": "8n0O1P2Q3R4S5T6U7V8W9X0Y1Z2A3B4C5D6E7F8G9H0I1J2K3L4M5N6O7P8Q9R0S1T",
        "createdAt": "2025-08-20T10:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 100
    }
  }
}
```

## 系统管理API

### 1. 系统统计

**接口**: `GET /api/admin/stats`

**描述**: 获取系统整体统计信息

**认证**: 需要Bearer Token (管理员权限)

**响应示例**:
```json
{
  "success": true,
  "data": {
    "users": {
      "total": 10000,
      "active": 8500,
      "newToday": 25,
      "newThisWeek": 180
    },
    "proposals": {
      "total": 120,
      "currentPhase": "voting",
      "activeProposals": 8,
      "totalVotes": 25000
    },
    "tokens": {
      "totalStaked": "1250000.00",
      "totalSupply": "1000000000.00",
      "circulatingSupply": "150000000.00",
      "stakingRatio": "0.83%"
    },
    "nfts": {
      "totalMinted": 5000,
      "goldCoins": 50,
      "silverCoins": 500,
      "bronzeCoins": 2000,
      "ironCoins": 2450
    },
    "points": {
      "totalEarned": "50000000",
      "totalSpent": "30000000",
      "dailyCheckins": 2500
    }
  }
}
```

### 2. 用户管理

**接口**: `GET /api/admin/users`

**描述**: 获取用户列表和管理信息

**认证**: 需要Bearer Token (管理员权限)

**查询参数**:
- `status` (string, optional): 用户状态筛选
- `vipLevel` (integer, optional): VIP等级筛选
- `search` (string, optional): 搜索关键词
- `page` (integer, optional): 页码，默认1
- `limit` (integer, optional): 每页数量，默认20

**响应示例**:
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 123,
        "username": "user123",
        "walletAddress": "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
        "email": "user@example.com",
        "vipLevel": 0,
        "status": "active",
        "totalPoints": 1500,
        "totalStaked": "1000.00",
        "nftCount": 15,
        "registeredAt": "2025-01-01T00:00:00Z",
        "lastLoginAt": "2025-08-11T09:30:00Z",
        "referralCount": 5
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 100,
      "totalItems": 2000
    }
  }
}
```

### 3. 系统配置

**接口**: `GET /api/admin/config`

**描述**: 获取系统配置参数

**认证**: 需要Bearer Token (超级管理员权限)

**响应示例**:
```json
{
  "success": true,
  "data": {
    "checkin": {
      "dailyPoints": 200,
      "bonusEnabled": true,
      "consecutiveBonusPoints": 50,
      "maxConsecutiveDays": 30
    },
    "lottery": {
      "dailyDrawLimit": 2,
      "premiumDrawLimit": 5,
      "dailyDrawCost": 100,
      "premiumDrawCost": 500
    },
    "staking": {
      "minimumStake": "100.00",
      "lockupPeriod": 30,
      "apy": "12.5",
      "earlyUnstakePenalty": "5.0"
    },
    "proposals": {
      "submissionPeriod": 10,
      "votingPeriod": 9,
      "mintingPeriod": 6,
      "maxProposalsPerRound": 10,
      "minimumStakeToVote": "10.00"
    },
    "nft": {
      "synthesisEnabled": true,
      "redemptionEnabled": true,
      "goldCoinValue": "10.00",
      "silverCoinValue": "1.00",
      "bronzeCoinValue": "0.10"
    }
  }
}
```

### 4. 更新系统配置

**接口**: `PUT /api/admin/config`

**描述**: 更新系统配置参数

**认证**: 需要Bearer Token (超级管理员权限)

**请求参数**:
```json
{
  "section": "string (required) - 配置分区",
  "config": "object (required) - 配置对象"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "updatedSection": "checkin",
    "newConfig": {
      "dailyPoints": 250,
      "bonusEnabled": true,
      "consecutiveBonusPoints": 60,
      "maxConsecutiveDays": 30
    },
    "updatedAt": "2025-08-11T10:30:00Z",
    "updatedBy": {
      "userId": 1,
      "username": "superadmin"
    }
  },
  "message": "Configuration updated successfully"
}
```

### 5. 系统维护

**接口**: `POST /api/admin/maintenance`

**描述**: 系统维护操作

**认证**: 需要Bearer Token (超级管理员权限)

**请求参数**:
```json
{
  "action": "string (required) - 维护操作 (enable, disable, cleanup)",
  "message": "string (optional) - 维护消息",
  "duration": "integer (optional) - 维护时长(分钟)"
}
```

**响应示例**:
```json
{
  "success": true,
  "data": {
    "maintenanceId": 789,
    "action": "enable",
    "message": "系统升级维护，预计30分钟",
    "startedAt": "2025-08-11T02:00:00Z",
    "estimatedEndAt": "2025-08-11T02:30:00Z",
    "startedBy": {
      "userId": 1,
      "username": "superadmin"
    }
  },
  "message": "Maintenance mode enabled"
}
```

## 错误处理

### 错误响应格式

所有API错误都遵循统一的响应格式：

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": "Detailed error information",
    "timestamp": "2025-08-11T10:30:00Z",
    "path": "/api/endpoint",
    "requestId": "req_123456"
  }
}
```

### 常见错误码

| 错误码 | HTTP状态码 | 描述 |
|--------|------------|------|
| `INVALID_REQUEST` | 400 | 请求参数无效 |
| `UNAUTHORIZED` | 401 | 未授权访问 |
| `FORBIDDEN` | 403 | 权限不足 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `VALIDATION_ERROR` | 422 | 数据验证失败 |
| `RATE_LIMIT_EXCEEDED` | 429 | 请求频率超限 |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |
| `WALLET_SIGNATURE_INVALID` | 400 | 钱包签名验证失败 |
| `INSUFFICIENT_BALANCE` | 400 | 余额不足 |
| `NONCE_EXPIRED` | 400 | 随机数已过期 |
| `DUPLICATE_VOTE` | 400 | 重复投票 |
| `PROPOSAL_NOT_ACTIVE` | 400 | 提案未激活 |
| `STAKING_LOCKED` | 400 | 质押仍在锁定期 |
| `DAILY_LIMIT_EXCEEDED` | 400 | 超过每日限制 |

### 错误处理示例

```javascript
// 客户端错误处理示例
try {
  const response = await fetch('/api/points/checkin', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  const data = await response.json();
  
  if (!data.success) {
    switch (data.error.code) {
      case 'DAILY_LIMIT_EXCEEDED':
        alert('今日已签到，请明天再来！');
        break;
      case 'UNAUTHORIZED':
        // 重定向到登录页面
        window.location.href = '/login';
        break;
      default:
        alert(`操作失败: ${data.error.message}`);
    }
    return;
  }
  
  // 处理成功响应
  console.log('签到成功:', data.data);
} catch (error) {
  console.error('网络错误:', error);
  alert('网络连接失败，请稍后重试');
}
```

## 部署说明

### 环境变量配置

```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gccc_db
DB_USER=gccc_user
DB_PASSWORD=your_secure_password

# JWT配置
JWT_SECRET=your-jwt-secret-key
JWT_EXPIRE=24h
REFRESH_TOKEN_EXPIRE=7d

# Solana配置
SOLANA_NETWORK=devnet
SOLANA_RPC_URL=https://api.devnet.solana.com
GCCC_TOKEN_MINT=your_token_mint_address

# Redis配置 (可选)
REDIS_URL=redis://localhost:6379

# 系统配置
NODE_ENV=production
PORT=3000
CORS_ORIGIN=https://gccc.com

# 安全配置
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
BCRYPT_ROUNDS=12

# 外部服务
EMAIL_SERVICE_API_KEY=your_email_api_key
IPFS_GATEWAY_URL=https://gateway.pinata.cloud
```

### 启动命令

```bash
# 开发环境
npm run dev

# 生产环境
npm start

# 使用PM2部署
pm2 start ecosystem.config.js
```

### Docker部署

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["npm", "start"]
```

### API文档生成

```bash
# 生成Swagger文档
npm run docs:generate

# 启动文档服务器
npm run docs:serve
```

### 监控和日志

- **健康检查**: `GET /health`
- **监控指标**: `GET /metrics` (Prometheus格式)
- **日志级别**: 通过`LOG_LEVEL`环境变量配置
- **错误追踪**: 集成Sentry错误监控

### 安全建议

1. **使用HTTPS**: 生产环境必须使用SSL/TLS
2. **API限流**: 配置合理的请求频率限制
3. **输入验证**: 严格验证所有输入参数
4. **权限控制**: 实施细粒度的权限管理
5. **日志审计**: 记录所有敏感操作
6. **定期备份**: 定期备份数据库和配置
7. **安全更新**: 及时更新依赖包和系统补丁
