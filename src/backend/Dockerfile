# ================================================================
# GCCC Backend Simplified Dockerfile
# Optimized for development and production
# ================================================================

# Base Node.js image
FROM node:18-alpine AS base
LABEL maintainer="GCCC Development Team"
LABEL version="1.0.0"
LABEL description="GCCC Backend API Server"

# Create app directory and user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S gcccuser -u 1001 -G nodejs

WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./

# ================================================================
# Development Dependencies Stage
# Contains all dependencies including dev dependencies
# ================================================================
FROM base AS dev-dependencies

# Install all dependencies (including dev dependencies for testing)
RUN npm install && \
    npm cache clean --force

# Copy application source code
COPY --chown=gcccuser:nodejs . .

USER gcccuser

# Expose port
EXPOSE 3000

# Health check (using node instead of external tools)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health',(r)=>process.exit(r.statusCode===200?0:1))"

# Default command for development  
CMD ["npm", "run", "dev"]

# ================================================================
# Production Dependencies Stage  
# Only production dependencies for smaller image
# ================================================================
FROM base AS prod-dependencies

# Set production environment
ENV NODE_ENV=production

# Install only production dependencies
RUN npm install --only=production && \
    npm cache clean --force

# ================================================================
# Test Stage
# For running tests in CI/CD pipeline
# ================================================================
FROM dev-dependencies AS test

# Set test environment
ENV NODE_ENV=test

# Create test directories
RUN mkdir -p coverage test-results

# Health check for test environment
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=2 \
    CMD node -e "require('http').get('http://localhost:3001/health',(r)=>process.exit(r.statusCode===200?0:1))"

# Default test command
CMD ["npm", "test"]

# ================================================================
# Production Stage
# Final optimized production image
# ================================================================
FROM base AS production

# Set production environment
ENV NODE_ENV=production \
    PORT=3000 \
    LOG_LEVEL=info

# Copy production dependencies
COPY --from=prod-dependencies --chown=gcccuser:nodejs /app/node_modules ./node_modules

# Copy application source (since we don't have a build step for now)
COPY --chown=gcccuser:nodejs . .

# Create necessary directories with proper permissions
RUN mkdir -p logs temp uploads && \
    chown -R gcccuser:nodejs logs temp uploads

# Switch to non-root user
USER gcccuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health',(r)=>process.exit(r.statusCode===200?0:1))"

# Production startup command
CMD ["node", "server.js"]

# ================================================================
# Development Hot-reload Stage
# For local development with hot reloading
# ================================================================
FROM dev-dependencies AS development

# Set development environment
ENV NODE_ENV=development \
    PORT=3000 \
    LOG_LEVEL=debug

# Create development directories
RUN mkdir -p logs temp uploads

# Health check for development
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health',(r)=>process.exit(r.statusCode===200?0:1))"

# Development command with hot reloading
CMD ["npm", "run", "dev"]
