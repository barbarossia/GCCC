/**
 * GCCC 后端服务配置文件
 * 
 * 统一管理所有配置项，从环境变量读取配置
 * 
 * @author GCCC Development Team
 * @version 1.0.0
 */

require('dotenv').config();

/**
 * 获取环境变量，支持默认值和类型转换
 */
const getEnv = (name, defaultValue = undefined, type = 'string') => {
  const value = process.env[name];
  
  if (value === undefined) {
    if (defaultValue !== undefined) {
      return defaultValue;
    }
    throw new Error(`Required environment variable ${name} is not set`);
  }

  switch (type) {
    case 'number':
      const num = Number(value);
      if (isNaN(num)) {
        throw new Error(`Environment variable ${name} must be a number`);
      }
      return num;
    
    case 'boolean':
      return value.toLowerCase() === 'true';
    
    case 'array':
      return value.split(',').map(item => item.trim()).filter(Boolean);
    
    case 'json':
      try {
        return JSON.parse(value);
      } catch (error) {
        throw new Error(`Environment variable ${name} must be valid JSON`);
      }
    
    default:
      return value;
  }
};

/**
 * 配置对象
 */
const config = {
  // ====================================
  // 服务器配置
  // ====================================
  server: {
    nodeEnv: getEnv('NODE_ENV', 'development'),
    port: getEnv('PORT', 3000, 'number'),
    host: getEnv('HOST', 'localhost'),
    clusterMode: getEnv('CLUSTER_MODE', false, 'boolean'),
    clusterWorkers: getEnv('CLUSTER_WORKERS', 'auto'),
    gracefulShutdownTimeout: getEnv('GRACEFUL_SHUTDOWN_TIMEOUT', 30000, 'number'),
    keepAliveTimeout: getEnv('KEEP_ALIVE_TIMEOUT', 65000, 'number'),
    headersTimeout: getEnv('HEADERS_TIMEOUT', 66000, 'number')
  },

  // ====================================
  // 数据库配置
  // ====================================
  database: {
    host: getEnv('DB_HOST'),
    port: getEnv('DB_PORT', 5432, 'number'),
    name: getEnv('DB_NAME'),
    user: getEnv('DB_USER'),
    password: getEnv('DB_PASSWORD'),
    ssl: getEnv('DB_SSL', false, 'boolean'),
    maxConnections: getEnv('DB_MAX_CONNECTIONS', 20, 'number'),
    idleTimeout: getEnv('DB_IDLE_TIMEOUT', 30000, 'number'),
    connectionTimeout: getEnv('DB_CONNECTION_TIMEOUT', 2000, 'number'),
    autoMigrate: getEnv('DB_AUTO_MIGRATE', false, 'boolean')
  },

  // ====================================
  // Redis配置
  // ====================================
  redis: {
    host: getEnv('REDIS_HOST', 'localhost'),
    port: getEnv('REDIS_PORT', 6379, 'number'),
    password: getEnv('REDIS_PASSWORD', ''),
    db: getEnv('REDIS_DB', 0, 'number'),
    clusterMode: getEnv('REDIS_CLUSTER_MODE', false, 'boolean'),
    maxRetries: getEnv('REDIS_MAX_RETRIES', 3, 'number'),
    retryDelay: getEnv('REDIS_RETRY_DELAY', 1000, 'number')
  },

  // ====================================
  // JWT配置
  // ====================================
  jwt: {
    secret: getEnv('JWT_SECRET'),
    expiresIn: getEnv('JWT_EXPIRES_IN', '7d'),
    refreshSecret: getEnv('JWT_REFRESH_SECRET', getEnv('JWT_SECRET')),
    refreshExpiresIn: getEnv('JWT_REFRESH_EXPIRES_IN', '30d'),
    issuer: getEnv('JWT_ISSUER', 'gccc-backend'),
    audience: getEnv('JWT_AUDIENCE', 'gccc-users')
  },

  // ====================================
  // 区块链配置
  // ====================================
  blockchain: {
    enabled: getEnv('BLOCKCHAIN_ENABLED', true, 'boolean'),
    rpcUrl: getEnv('SOLANA_RPC_URL', 'https://api.devnet.solana.com'),
    network: getEnv('SOLANA_NETWORK', 'devnet'),
    commitment: getEnv('SOLANA_COMMITMENT', 'confirmed'),
    tokenMint: getEnv('GCCC_TOKEN_MINT', ''),
    stakingProgramId: getEnv('STAKING_PROGRAM_ID', ''),
    nftCollectionId: getEnv('NFT_COLLECTION_ID', ''),
    treasuryWallet: getEnv('TREASURY_WALLET', '')
  },

  // ====================================
  // API配置
  // ====================================
  api: {
    version: getEnv('API_VERSION', 'v1'),
    prefix: getEnv('API_PREFIX', '/api'),
    maxRequestSize: getEnv('MAX_REQUEST_SIZE', '10mb'),
    maxFileSize: getEnv('MAX_FILE_SIZE', '5mb')
  },

  // ====================================
  // 安全配置
  // ====================================
  security: {
    bcryptRounds: getEnv('BCRYPT_ROUNDS', 12, 'number'),
    sessionSecret: getEnv('SESSION_SECRET', getEnv('JWT_SECRET')),
    corsOrigins: getEnv('CORS_ORIGIN', '*', 'array'),
    rateLimitWindowMs: getEnv('RATE_LIMIT_WINDOW_MS', 900000, 'number'),
    rateLimitMaxRequests: getEnv('RATE_LIMIT_MAX_REQUESTS', 100, 'number'),
    slowDownDelayAfter: getEnv('SLOW_DOWN_DELAY_AFTER', 50, 'number'),
    slowDownDelayMs: getEnv('SLOW_DOWN_DELAY_MS', 500, 'number')
  },

  // ====================================
  // 日志配置
  // ====================================
  logging: {
    level: getEnv('LOG_LEVEL', 'info'),
    file: getEnv('LOG_FILE', 'logs/app.log'),
    maxSize: getEnv('LOG_MAX_SIZE', '10m'),
    maxFiles: getEnv('LOG_MAX_FILES', 5, 'number'),
    datePattern: getEnv('LOG_DATE_PATTERN', 'YYYY-MM-DD'),
    format: getEnv('LOG_FORMAT', 'json'),
    colorize: getEnv('LOG_COLORIZE', true, 'boolean')
  },

  // ====================================
  // 邮件配置
  // ====================================
  email: {
    enabled: getEnv('EMAIL_ENABLED', false, 'boolean'),
    host: getEnv('SMTP_HOST', ''),
    port: getEnv('SMTP_PORT', 587, 'number'),
    secure: getEnv('SMTP_SECURE', false, 'boolean'),
    user: getEnv('SMTP_USER', ''),
    password: getEnv('SMTP_PASS', ''),
    from: getEnv('EMAIL_FROM', ''),
    fromName: getEnv('EMAIL_FROM_NAME', 'GCCC Platform')
  },

  // ====================================
  // IPFS配置
  // ====================================
  ipfs: {
    enabled: getEnv('IPFS_ENABLED', false, 'boolean'),
    gateway: getEnv('IPFS_GATEWAY', 'https://ipfs.io/ipfs/'),
    apiUrl: getEnv('IPFS_API_URL', 'https://api.pinata.cloud'),
    apiKey: getEnv('PINATA_API_KEY', ''),
    secretKey: getEnv('PINATA_SECRET_KEY', ''),
    timeout: getEnv('IPFS_TIMEOUT', 30000, 'number')
  },

  // ====================================
  // 缓存配置
  // ====================================
  cache: {
    ttlDefault: getEnv('CACHE_TTL_DEFAULT', 3600, 'number'),
    ttlUserProfile: getEnv('CACHE_TTL_USER_PROFILE', 1800, 'number'),
    ttlProposals: getEnv('CACHE_TTL_PROPOSALS', 600, 'number'),
    ttlStakingInfo: getEnv('CACHE_TTL_STAKING_INFO', 300, 'number'),
    ttlTokenPrice: getEnv('CACHE_TTL_TOKEN_PRICE', 60, 'number')
  },

  // ====================================
  // 文件上传配置
  // ====================================
  upload: {
    dir: getEnv('UPLOAD_DIR', 'uploads'),
    maxSize: getEnv('UPLOAD_MAX_SIZE', 5242880, 'number'), // 5MB
    allowedTypes: getEnv('UPLOAD_ALLOWED_TYPES', 'image/jpeg,image/png,image/gif,image/webp', 'array'),
    tempDir: getEnv('UPLOAD_TEMP_DIR', 'temp')
  },

  // ====================================
  // 定时任务配置
  // ====================================
  cron: {
    enabled: getEnv('CRON_ENABLED', true, 'boolean'),
    stakingRewards: getEnv('CRON_STAKING_REWARDS', '0 0 * * *'),
    lotteryDraw: getEnv('CRON_LOTTERY_DRAW', '0 12 * * 0'),
    dataCleanup: getEnv('CRON_DATA_CLEANUP', '0 2 * * *'),
    syncBlockchain: getEnv('CRON_SYNC_BLOCKCHAIN', '*/5 * * * *')
  },

  // ====================================
  // 监控配置
  // ====================================
  monitoring: {
    healthCheckPath: getEnv('HEALTH_CHECK_PATH', '/health'),
    healthCheckTimeout: getEnv('HEALTH_CHECK_TIMEOUT', 5000, 'number'),
    metricsEnabled: getEnv('METRICS_ENABLED', true, 'boolean'),
    metricsPath: getEnv('METRICS_PATH', '/metrics'),
    sentryEnabled: getEnv('SENTRY_DSN', '') !== '',
    sentryDsn: getEnv('SENTRY_DSN', ''),
    sentryEnvironment: getEnv('SENTRY_ENVIRONMENT', getEnv('NODE_ENV', 'development')),
    sentrySampleRate: getEnv('SENTRY_SAMPLE_RATE', 1.0, 'number'),
    sentryTracesSampleRate: getEnv('SENTRY_TRACES_SAMPLE_RATE', 0.1, 'number')
  },

  // ====================================
  // 业务配置
  // ====================================
  business: {
    // 用户系统
    user: {
      maxDevices: getEnv('USER_MAX_DEVICES', 5, 'number'),
      inactiveDays: getEnv('USER_INACTIVE_DAYS', 90, 'number'),
      maxLoginAttempts: getEnv('USER_MAX_LOGIN_ATTEMPTS', 5, 'number'),
      lockoutDuration: getEnv('USER_LOCKOUT_DURATION', 900000, 'number')
    },

    // 积分系统
    points: {
      dailyCheckin: getEnv('POINTS_DAILY_CHECKIN', 10, 'number'),
      referralBonus: getEnv('POINTS_REFERRAL_BONUS', 100, 'number'),
      proposalCreate: getEnv('POINTS_PROPOSAL_CREATE', 50, 'number'),
      voteCast: getEnv('POINTS_VOTE_CAST', 5, 'number')
    },

    // 质押系统
    staking: {
      minAmount: getEnv('STAKING_MIN_AMOUNT', 100, 'number'),
      maxAmount: getEnv('STAKING_MAX_AMOUNT', 1000000, 'number'),
      lockPeriods: getEnv('STAKING_LOCK_PERIODS', '7,30,90,365', 'array').map(Number),
      apyRates: getEnv('STAKING_APY_RATES', '5,8,12,20', 'array').map(Number)
    },

    // 抽奖系统
    lottery: {
      ticketPrice: getEnv('LOTTERY_TICKET_PRICE', 10, 'number'),
      maxTicketsPerUser: getEnv('LOTTERY_MAX_TICKETS_PER_USER', 100, 'number'),
      drawInterval: getEnv('LOTTERY_DRAW_INTERVAL', 7, 'number')
    },

    // NFT系统
    nft: {
      mintPrice: getEnv('NFT_MINT_PRICE', 0.1, 'number'),
      maxSupply: getEnv('NFT_MAX_SUPPLY', 10000, 'number'),
      royaltyPercentage: getEnv('NFT_ROYALTY_PERCENTAGE', 2.5, 'number')
    }
  },

  // ====================================
  // 第三方服务配置
  // ====================================
  external: {
    coinGecko: {
      apiKey: getEnv('COINGECKO_API_KEY', ''),
      baseUrl: getEnv('COINGECKO_BASE_URL', 'https://api.coingecko.com/api/v3')
    },
    discord: {
      webhookUrl: getEnv('DISCORD_WEBHOOK_URL', '')
    },
    telegram: {
      botToken: getEnv('TELEGRAM_BOT_TOKEN', ''),
      chatId: getEnv('TELEGRAM_CHAT_ID', '')
    }
  },

  // ====================================
  // 特性开关
  // ====================================
  features: {
    userRegistration: getEnv('FEATURE_USER_REGISTRATION', true, 'boolean'),
    emailVerification: getEnv('FEATURE_EMAIL_VERIFICATION', false, 'boolean'),
    twoFactorAuth: getEnv('FEATURE_TWO_FACTOR_AUTH', false, 'boolean'),
    adminPanel: getEnv('FEATURE_ADMIN_PANEL', true, 'boolean'),
    analytics: getEnv('FEATURE_ANALYTICS', true, 'boolean'),
    rateLimiting: getEnv('FEATURE_RATE_LIMITING', true, 'boolean'),
    cors: getEnv('FEATURE_CORS', true, 'boolean'),
    compression: getEnv('FEATURE_COMPRESSION', true, 'boolean')
  }
};

/**
 * 配置验证
 */
function validateConfig() {
  const errors = [];

  // 验证JWT密钥长度
  if (config.jwt.secret.length < 32) {
    errors.push('JWT_SECRET must be at least 32 characters long');
  }

  // 验证端口范围
  if (config.server.port < 1 || config.server.port > 65535) {
    errors.push('PORT must be between 1 and 65535');
  }

  // 验证日志级别
  const validLogLevels = ['error', 'warn', 'info', 'debug'];
  if (!validLogLevels.includes(config.logging.level)) {
    errors.push(`LOG_LEVEL must be one of: ${validLogLevels.join(', ')}`);
  }

  // 验证环境
  const validEnvironments = ['development', 'staging', 'production', 'test'];
  if (!validEnvironments.includes(config.server.nodeEnv)) {
    errors.push(`NODE_ENV must be one of: ${validEnvironments.join(', ')}`);
  }

  if (errors.length > 0) {
    throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
  }
}

/**
 * 是否为生产环境
 */
config.isProduction = config.server.nodeEnv === 'production';

/**
 * 是否为开发环境
 */
config.isDevelopment = config.server.nodeEnv === 'development';

/**
 * 是否为测试环境
 */
config.isTest = config.server.nodeEnv === 'test';

// 验证配置
try {
  validateConfig();
} catch (error) {
  console.error('Configuration Error:', error.message);
  process.exit(1);
}

module.exports = config;
