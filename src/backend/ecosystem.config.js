module.exports = {
  apps: [
    {
      name: 'gccc-backend',
      script: 'server.js',
      cwd: './',
      instances: process.env.NODE_ENV === 'production' ? 'max' : 1,
      exec_mode: process.env.NODE_ENV === 'production' ? 'cluster' : 'fork',
      watch: process.env.NODE_ENV !== 'production',
      ignore_watch: [
        'node_modules',
        'logs',
        'tests',
        'uploads',
        'temp',
        '.git'
      ],
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
        HOST: 'localhost'
      },
      env_staging: {
        NODE_ENV: 'staging',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      log_file: './logs/pm2-combined.log',
      time: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 4000,
      kill_timeout: 5000,
      listen_timeout: 8000,
      shutdown_with_message: true,
      source_map_support: false,
      merge_logs: true,
      instance_var: 'INSTANCE_ID',
      // 健康检查配置
      health_check_grace_period: 3000,
      health_check_fatal_exceptions: true,
      // 资源监控
      monitoring: true,
      pmx: true,
      // 自动重启条件
      max_memory_restart: '1G',
      node_args: [
        '--max-old-space-size=1024'
      ],
      // 进程间通信
      vizion: false,
      // 异常处理
      catch_exceptions: true,
      // 集群模式配置
      increment_var: 'PORT',
      // Windows特定配置
      ...(process.platform === 'win32' && {
        script: 'server.js',
        interpreter: 'node'
      })
    }
  ],

  // PM2 Deploy配置
  deploy: {
    // 生产环境部署
    production: {
      user: 'gccc',
      host: ['your-production-server.com'],
      ref: 'origin/main',
      repo: 'https://github.com/gccc-org/backend.git',
      path: '/var/www/gccc-backend',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': 'apt update && apt install nodejs npm -y',
      'post-setup': 'ls -la',
      ssh_options: 'StrictHostKeyChecking=no',
      env: {
        NODE_ENV: 'production'
      }
    },

    // 预发布环境部署
    staging: {
      user: 'gccc',
      host: ['your-staging-server.com'],
      ref: 'origin/develop',
      repo: 'https://github.com/gccc-org/backend.git',
      path: '/var/www/gccc-backend-staging',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env staging',
      'pre-setup': 'apt update && apt install nodejs npm -y',
      env: {
        NODE_ENV: 'staging'
      }
    }
  }
};
