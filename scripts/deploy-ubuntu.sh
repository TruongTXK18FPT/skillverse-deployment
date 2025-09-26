#!/bin/bash

# 🚀 SkillVerse Production Deployment Script
# This script sets up and runs the SkillVerse application on Ubuntu

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PROJECT_DIR="/home/skillverse/skillverse-production"
DEPLOYMENT_DIR="$PROJECT_DIR/deployment"
DOCKER_DIR="$DEPLOYMENT_DIR/docker"

print_status "🚀 Starting SkillVerse Production Deployment..."

# Check if running as correct user
if [ "$USER" != "skillverse" ]; then
    print_warning "Not running as 'skillverse' user. Current user: $USER"
fi

# Navigate to project directory
print_status "📁 Navigating to project directory: $PROJECT_DIR"
cd "$PROJECT_DIR" || {
    print_error "Failed to navigate to $PROJECT_DIR"
    exit 1
}

# Check directory structure
print_status "🔍 Checking directory structure..."
REQUIRED_DIRS=(
    "deployment/docker"
    "SkillVerse_BackEnd"
    "skillverse-prototype"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        print_error "Required directory not found: $dir"
        print_status "Expected structure:"
        print_status "  $PROJECT_DIR/"
        print_status "  ├── deployment/docker/"
        print_status "  ├── SkillVerse_BackEnd/"
        print_status "  └── skillverse-prototype/"
        exit 1
    else
        print_success "✅ Found: $dir"
    fi
done

# Pull latest changes for each repository
print_status "📥 Pulling latest changes..."

# Pull deployment repository
print_status "Pulling deployment repository..."
cd "$DEPLOYMENT_DIR"
git pull origin main || print_warning "Failed to pull deployment repo"

# Pull backend repository
print_status "Pulling backend repository..."
cd "$PROJECT_DIR/SkillVerse_BackEnd"
git pull origin main || print_warning "Failed to pull backend repo"

# Pull frontend repository
print_status "Pulling frontend repository..."
cd "$PROJECT_DIR/skillverse-prototype"
git pull origin main || print_warning "Failed to pull frontend repo"

# Return to docker directory
cd "$DOCKER_DIR"

# Check for .env file
print_status "🔧 Checking environment configuration..."
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    
    # Create .env file with production values
    cat > .env << 'EOF'
# 🔒 SkillVerse Production Environment Variables

# === Database Configuration ===
DB_PASSWORD=12345
DB_HOST=localhost
DB_PORT=5432
DB_NAME=SkillVerseDB
DB_USER=postgres

# Docker Database Configuration
DOCKER_DB_PASSWORD=secure_db_password_2024
DOCKER_DB_HOST=db
DOCKER_DB_NAME=skillverse_db
DOCKER_DB_USER=skillverse_user

# === Redis Configuration ===
REDIS_PASSWORD=secure_redis_password_2024
REDIS_HOST=redis
REDIS_PORT=6379

# === JWT Configuration ===
JWT_SECRET=1TjXchw5FloESb63Kc+DFhTARvpWL4jUGCwfGWxuG5SIf/1y/LgJxHnMqaF6A/ij

# === Email Configuration ===
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=skillverseexe@gmail.com
SMTP_PASSWORD=fgbx gygh iglz dcou
EMAIL_FROM=skillverseexe@gmail.com
EMAIL_FROM_NAME=SkillVerse

# === Performance ===
JAVA_OPTS=-Xmx1024m -Xms512m -XX:+UseG1GC
LOG_LEVEL=INFO
EOF
    
    print_success "✅ Created .env file"
else
    print_success "✅ Found .env file"
fi

# Stop existing containers
print_status "🛑 Stopping existing containers..."
docker compose -f docker-compose.yml down || print_warning "No existing containers to stop"

# Remove unused images and containers
print_status "🧹 Cleaning up unused Docker resources..."
docker system prune -f || print_warning "Failed to clean up Docker resources"

# Build and start services
print_status "🏗️ Building and starting services..."
print_status "This may take a few minutes for the first build..."

# Build images
docker compose -f docker-compose.yml build --no-cache || {
    print_error "Failed to build Docker images"
    exit 1
}

# Start services
docker compose -f docker-compose.yml up -d || {
    print_error "Failed to start services"
    exit 1
}

# Wait for services to be ready
print_status "⏳ Waiting for services to be ready..."
sleep 30

# Check service health
print_status "🔍 Checking service health..."

# Check database
if docker compose -f docker-compose.yml exec -T db pg_isready -U skillverse_user > /dev/null 2>&1; then
    print_success "✅ Database is ready"
else
    print_warning "⚠️ Database may not be ready yet"
fi

# Check Redis
if docker compose -f docker-compose.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_success "✅ Redis is ready"
else
    print_warning "⚠️ Redis may not be ready yet"
fi

# Check backend health
print_status "Checking backend health..."
for i in {1..12}; do
    if curl -f -s http://localhost:8080/api/health > /dev/null 2>&1; then
        print_success "✅ Backend is healthy"
        break
    else
        if [ $i -eq 12 ]; then
            print_warning "⚠️ Backend health check failed after 60 seconds"
        else
            print_status "Waiting for backend... ($i/12)"
            sleep 5
        fi
    fi
done

# Check frontend
if curl -f -s http://localhost:80/health > /dev/null 2>&1; then
    print_success "✅ Frontend is ready"
else
    print_warning "⚠️ Frontend may not be ready yet"
fi

# Display service status
print_status "📊 Service Status:"
docker compose -f docker-compose.yml ps

# Display access URLs
print_success "🎉 Deployment completed!"
print_status ""
print_status "🌐 Access URLs:"
print_status "  Frontend:     http://$(hostname -I | awk '{print $1}')/"
print_status "  Backend API:  http://$(hostname -I | awk '{print $1}'):8080/api/"
print_status "  Swagger UI:   http://$(hostname -I | awk '{print $1}'):8080/api/swagger-ui/index.html"
print_status "  Health Check: http://$(hostname -I | awk '{print $1}'):8080/api/health"
print_status ""
print_status "📋 Useful Commands:"
print_status "  View logs:    docker compose -f docker-compose.yml logs -f"
print_status "  Restart:      docker compose -f docker-compose.yml restart"
print_status "  Stop:         docker compose -f docker-compose.yml down"
print_status ""

# Show container logs for troubleshooting
print_status "📝 Recent logs (last 10 lines per service):"
echo "=== Backend Logs ==="
docker compose -f docker-compose.yml logs --tail=10 app 2>/dev/null || echo "No backend logs available"
echo ""
echo "=== Frontend Logs ==="
docker compose -f docker-compose.yml logs --tail=10 frontend 2>/dev/null || echo "No frontend logs available"
echo ""

print_success "🚀 SkillVerse is now running!"