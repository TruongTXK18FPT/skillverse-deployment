#!/bin/bash

# 🚀 SkillVerse Deployment Script with SSL Support
# Usage: ./deploy.sh [--ssl] [--staging]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="SkillVerse"
COMPOSE_FILE="docker-compose.yml"
SSL_MODE=false
STAGING_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssl)
            SSL_MODE=true
            shift
            ;;
        --staging)
            STAGING_MODE=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚀 Starting $PROJECT_NAME deployment...${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is required but not installed.${NC}" >&2; exit 1; }
command -v docker compose >/dev/null 2>&1 || { echo -e "${RED}❌ Docker Compose is required but not installed.${NC}" >&2; exit 1; }

# Display system info
echo -e "${BLUE}💻 System Information:${NC}"
echo "   Docker: $(docker --version)"
echo "   Docker Compose: $(docker compose version)"
echo "   Date: $(date)"
echo "   User: $(whoami)"
echo "   PWD: $(pwd)"

# SSL Configuration
if [ "$SSL_MODE" = true ]; then
    echo -e "${GREEN}🔒 SSL Mode enabled${NC}"
    
    # Check if SSL certificates exist
    if [ ! -f "/etc/letsencrypt/live/your-domain.com/fullchain.pem" ]; then
        echo -e "${YELLOW}⚠️  SSL certificates not found. Please run SSL setup first.${NC}"
        echo -e "${BLUE}💡 Run: sudo ./setup-ssl.sh your-domain.com${NC}"
        exit 1
    fi
    
    # Use SSL nginx config
    if [ -f "nginx-ssl.conf" ]; then
        cp nginx-ssl.conf skillverse-prototype/nginx.conf
        echo -e "${GREEN}✅ SSL nginx configuration applied${NC}"
    else
        echo -e "${RED}❌ nginx-ssl.conf not found${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}🔓 HTTP Mode (no SSL)${NC}"
fi

# Backup current containers state
echo -e "${YELLOW}💾 Creating backup...${NC}"
mkdir -p backups
docker compose ps > "backups/containers_$(date +%Y%m%d_%H%M%S).log" 2>/dev/null || true

# Clean up old images
echo -e "${YELLOW}🧹 Cleaning up old Docker images...${NC}"
docker image prune -f >/dev/null 2>&1 || true

# Stop existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker compose down --remove-orphans

# Build and start services
echo -e "${YELLOW}🏗️  Building and starting services...${NC}"
if [ "$STAGING_MODE" = true ]; then
    echo -e "${BLUE}📊 Staging mode - pulling images without cache${NC}"
    docker compose build --no-cache
else
    docker compose build
fi

# Start services
echo -e "${YELLOW}🚀 Starting services...${NC}"
docker compose up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 15

# Health checks
echo -e "${YELLOW}🏥 Running health checks...${NC}"

# Check containers status
echo -e "${BLUE}📊 Container Status:${NC}"
docker compose ps

# Health check function
check_health() {
    local url=$1
    local service=$2
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}   Checking $service...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" >/dev/null 2>&1; then
            echo -e "${GREEN}   ✅ $service is healthy${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}   ⏳ Attempt $attempt/$max_attempts for $service...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}   ❌ $service health check failed${NC}"
    return 1
}

# Determine protocol
PROTOCOL="http"
if [ "$SSL_MODE" = true ]; then
    PROTOCOL="https"
fi

# Run health checks
HEALTH_CHECK_FAILED=false

if ! check_health "${PROTOCOL}://localhost/health" "Frontend"; then
    HEALTH_CHECK_FAILED=true
fi

if ! check_health "${PROTOCOL}://localhost/api/health" "Backend API"; then
    HEALTH_CHECK_FAILED=true
fi

# Database connection check
echo -e "${BLUE}   Checking Database connection...${NC}"
if docker compose exec -T db pg_isready -U skillverse_user -d skillverse_db >/dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Database is ready${NC}"
else
    echo -e "${RED}   ❌ Database connection failed${NC}"
    HEALTH_CHECK_FAILED=true
fi

# Redis check
echo -e "${BLUE}   Checking Redis connection...${NC}"
if docker compose exec -T redis redis-cli ping >/dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Redis is ready${NC}"
else
    echo -e "${RED}   ❌ Redis connection failed${NC}"
    HEALTH_CHECK_FAILED=true
fi

# Display resource usage
echo -e "${BLUE}📊 Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Final status
if [ "$HEALTH_CHECK_FAILED" = true ]; then
    echo -e "${RED}❌ Deployment completed with errors${NC}"
    echo -e "${YELLOW}📋 Check logs with: docker compose logs${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo -e "${BLUE}🌐 Application URLs:${NC}"
    if [ "$SSL_MODE" = true ]; then
        echo -e "${GREEN}   🔒 HTTPS: https://localhost${NC}"
        echo -e "${GREEN}   🔒 API: https://localhost/api/health${NC}"
    else
        echo -e "${YELLOW}   🔓 HTTP: http://localhost${NC}"
        echo -e "${YELLOW}   🔓 API: http://localhost/api/health${NC}"
    fi
    echo -e "${BLUE}📊 Monitoring: docker compose logs -f${NC}"
fi

echo -e "${BLUE}🎉 $PROJECT_NAME deployment script completed!${NC}"