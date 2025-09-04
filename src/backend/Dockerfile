# ========================================
# GCCC Backend Service Dockerfile
# Node.js API服务器容器配置
# ========================================

# 使用官方 Node.js 18 LTS 版本作为基础镜像
FROM node:18-alpine AS base

# 设置工作目录
WORKDIR /app

# 安装基础依赖和工具
RUN apk add --no-cache \
    curl \
    dumb-init \
    && rm -rf /var/cache/apk/*

# 创建非特权用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# ========================================
# 依赖安装阶段
# ========================================
FROM base AS dependencies

# 复制 package 文件
COPY package*.json ./

# 安装生产依赖
RUN npm ci --only=production && npm cache clean --force

# ========================================
# 开发依赖安装阶段（用于构建和测试）
# ========================================
FROM base AS dev-dependencies

# 复制 package 文件
COPY package*.json ./

# 安装所有依赖（包括开发依赖）
RUN npm ci && npm cache clean --force

# ========================================
# 应用构建阶段
# ========================================
FROM dev-dependencies AS build

# 复制源代码
COPY . .

# 运行代码检查和测试
RUN npm run lint
# RUN npm run test  # 如果有测试则取消注释

# 清理开发依赖，只保留生产依赖
RUN npm prune --production

# ========================================
# 生产运行阶段
# ========================================
FROM base AS production

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# 从构建阶段复制生产依赖
COPY --from=dependencies /app/node_modules ./node_modules

# 复制应用代码（排除开发文件）
COPY --chown=nextjs:nodejs . .

# 移除不需要的文件
RUN rm -rf \
    tests/ \
    docs/ \
    .env.example \
    .gitignore \
    *.md \
    ecosystem.config.js

# 切换到非特权用户
USER nextjs

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# 使用 dumb-init 启动应用
ENTRYPOINT ["dumb-init", "--"]

# 启动命令
CMD ["node", "server.js"]

# ========================================
# 开发环境阶段
# ========================================
FROM dev-dependencies AS development

# 设置开发环境变量
ENV NODE_ENV=development
ENV PORT=3000
ENV HOST=0.0.0.0

# 复制所有源代码
COPY . .

# 暴露端口
EXPOSE 3000
EXPOSE 9229

# 开发模式启动命令（支持热重载和调试）
CMD ["npm", "run", "dev"]

# ========================================
# 使用说明：
#
# 构建生产镜像：
# docker build --target production -t gccc-backend:latest .
#
# 构建开发镜像：
# docker build --target development -t gccc-backend:dev .
#
# 运行生产容器：
# docker run -d \
#   --name gccc-backend \
#   -p 3000:3000 \
#   -e DATABASE_URL="postgresql://user:pass@host:5432/gccc_db" \
#   -e JWT_SECRET="your-secret-key" \
#   gccc-backend:latest
#
# 运行开发容器：
# docker run -d \
#   --name gccc-backend-dev \
#   -p 3000:3000 \
#   -p 9229:9229 \
#   -v $(pwd):/app \
#   -v /app/node_modules \
#   gccc-backend:dev
# ========================================
