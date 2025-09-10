#!/bin/sh
# ================================================================
# GCCC Backend Health Check Script for Docker Container
# Used by Docker HEALTHCHECK instruction
# ================================================================

set -e

# Configuration
HEALTH_ENDPOINT="${HEALTH_ENDPOINT:-http://localhost:3000/api/health}"
MAX_RETRIES="${MAX_RETRIES:-3}"
TIMEOUT="${TIMEOUT:-10}"

# Colors for output (if supported)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "${RED}$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1${NC}" >&2
}

log_warning() {
    echo "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1${NC}" >&2
}

log_success() {
    echo "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1${NC}"
}

# Check if curl is available
check_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is not available in container"
        return 1
    fi
    return 0
}

# Check API health endpoint
check_api_health() {
    local retry=0
    
    while [ $retry -lt $MAX_RETRIES ]; do
        retry=$((retry + 1))
        log "Checking API health (attempt $retry/$MAX_RETRIES)..."
        
        # Make the health check request
        response=$(curl -f -s -m $TIMEOUT "$HEALTH_ENDPOINT" 2>/dev/null) || {
            log_warning "Health check attempt $retry failed"
            if [ $retry -lt $MAX_RETRIES ]; then
                sleep 2
                continue
            else
                log_error "Health check failed after $MAX_RETRIES attempts"
                return 1
            fi
        }
        
        # Parse response
        if echo "$response" | grep -q '"status":"healthy"'; then
            log_success "API health check passed"
            return 0
        else
            log_warning "API returned unhealthy status: $response"
            if [ $retry -lt $MAX_RETRIES ]; then
                sleep 2
                continue
            else
                log_error "API health check failed - unhealthy status"
                return 1
            fi
        fi
    done
    
    return 1
}

# Check process is running
check_process() {
    log "Checking Node.js process..."
    
    if pgrep -f "node" >/dev/null 2>&1; then
        log_success "Node.js process is running"
        return 0
    else
        log_error "Node.js process not found"
        return 1
    fi
}

# Check port is listening
check_port() {
    local port="${1:-3000}"
    log "Checking if port $port is listening..."
    
    if netstat -ln 2>/dev/null | grep -q ":$port "; then
        log_success "Port $port is listening"
        return 0
    elif ss -ln 2>/dev/null | grep -q ":$port "; then
        log_success "Port $port is listening"
        return 0
    else
        log_error "Port $port is not listening"
        return 1
    fi
}

# Main health check function
main() {
    log "Starting Docker health check for GCCC Backend..."
    
    # Check if curl is available
    if ! check_curl; then
        log_error "Cannot perform health check without curl"
        exit 1
    fi
    
    # Check if the process is running
    if ! check_process; then
        log_error "Process health check failed"
        exit 1
    fi
    
    # Check if the port is listening
    port=$(echo "$HEALTH_ENDPOINT" | sed -n 's/.*:\([0-9]*\).*/\1/p')
    if [ -z "$port" ]; then
        port=3000
    fi
    
    if ! check_port "$port"; then
        log_error "Port health check failed"
        exit 1
    fi
    
    # Check API health endpoint
    if ! check_api_health; then
        log_error "API health check failed"
        exit 1
    fi
    
    log_success "All health checks passed - container is healthy"
    exit 0
}

# Execute main function
main "$@"
