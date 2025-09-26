#!/bin/bash

# 🚀 SkillVerse Swagger Quick Setup Script
# Chạy script này để kiểm tra và setup Swagger trên Ubuntu server

set -e

echo "🚀 SkillVerse Swagger Setup & Check"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
DOMAIN=${1:-$SERVER_IP}

print_info "Checking Swagger setup for domain/IP: $DOMAIN"

# Check if Docker is running
if ! docker --version >/dev/null 2>&1; then
    print_error "Docker is not installed or not running"
    exit 1
fi

# Check if docker-compose is available
if ! docker compose version >/dev/null 2>&1; then
    print_error "Docker Compose is not available"
    exit 1
fi

# Check if project directory exists
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the project root directory."
    exit 1
fi

# Check container status
print_info "Checking container status..."
docker compose ps

# Check if backend is running
if ! docker compose ps | grep -q "backend.*Up"; then
    print_warning "Backend container is not running. Starting containers..."
    docker compose up -d
    sleep 10
fi

# Health checks
print_info "Running health checks..."

# Check backend health
if curl -f -s "http://localhost:8080/api/health" >/dev/null 2>&1; then
    print_status "Backend health check: OK"
else
    print_error "Backend health check: FAILED"
    print_info "Checking backend logs..."
    docker compose logs backend --tail=20
fi

# Check Swagger UI
if curl -f -s "http://localhost:8080/api/swagger-ui/index.html" >/dev/null 2>&1; then
    print_status "Swagger UI internal check: OK"
else
    print_error "Swagger UI internal check: FAILED"
    print_info "Checking if SpringDoc is configured properly..."
fi

# Check OpenAPI docs
if curl -f -s "http://localhost:8080/api/v3/api-docs" >/dev/null 2>&1; then
    print_status "OpenAPI docs check: OK"
else
    print_error "OpenAPI docs check: FAILED"
fi

# Check external access (nginx)
if curl -f -s "http://localhost/api/swagger-ui/index.html" >/dev/null 2>&1; then
    print_status "External Swagger access: OK"
else
    print_warning "External Swagger access: Check nginx configuration"
    print_info "Checking nginx logs..."
    docker compose logs nginx --tail=10
fi

# Print access URLs
echo ""
echo "🔗 Swagger Access URLs:"
echo "=================================="
echo "📚 Swagger UI:     http://$DOMAIN/api/swagger-ui/index.html"
echo "📄 OpenAPI JSON:   http://$DOMAIN/api/v3/api-docs"
echo "📄 OpenAPI YAML:   http://$DOMAIN/api/v3/api-docs.yaml"
echo "🔍 Health Check:   http://$DOMAIN/api/health"
echo ""

# Test from external
print_info "Testing external access..."

# Try to test external access
if command -v curl >/dev/null 2>&1; then
    if curl -f -s -m 5 "http://$DOMAIN/api/health" >/dev/null 2>&1; then
        print_status "External access test: SUCCESS"
    else
        print_warning "External access test: May need firewall/security group configuration"
    fi
fi

# Quick troubleshooting
echo ""
echo "🛠️ Troubleshooting Commands:"
echo "=================================="
echo "# Check backend logs:"
echo "docker compose logs backend --tail=50"
echo ""
echo "# Check nginx logs:"
echo "docker compose logs nginx --tail=50"
echo ""
echo "# Restart backend:"
echo "docker compose restart backend"
echo ""
echo "# Rebuild everything:"
echo "docker compose up -d --build"
echo ""
echo "# Test internal connectivity:"
echo "docker compose exec backend curl http://localhost:8080/api/swagger-ui/index.html"
echo ""

# Test JWT authentication setup
print_info "Testing JWT authentication setup..."
if curl -s "http://localhost:8080/api/v3/api-docs" | grep -q "Bearer Authentication"; then
    print_status "JWT Bearer authentication is configured in Swagger"
else
    print_warning "JWT Bearer authentication may not be properly configured"
fi

# Check swagger configuration
print_info "Checking Swagger configuration..."
if docker compose exec backend cat /app/src/main/resources/application.yml 2>/dev/null | grep -q springdoc; then
    print_status "SpringDoc configuration found in application.yml"
else
    print_warning "SpringDoc configuration may be missing"
fi

# Memory and performance check
print_info "System resources check..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -5

echo ""
print_info "Setup check completed!"
print_info "If you see any errors above, refer to SWAGGER_SETUP_GUIDE.md for detailed troubleshooting."

# SSH tunnel instructions
echo ""
echo "🔒 SSH Tunnel (if server is private):"
echo "=================================="
echo "# Create tunnel from your local machine:"
echo "ssh -L 8080:localhost:8080 $(whoami)@$DOMAIN"
echo "# Then access: http://localhost:8080/api/swagger-ui/index.html"
echo ""

# Final status
if curl -f -s "http://localhost:8080/api/swagger-ui/index.html" >/dev/null 2>&1; then
    print_status "🎉 Swagger is ready to use!"
else
    print_error "❌ Swagger setup needs attention. Check the logs above."
    exit 1
fi