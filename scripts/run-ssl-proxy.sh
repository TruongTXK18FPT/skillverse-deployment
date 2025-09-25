#!/bin/bash

# SkillVerse SSL Proxy Setup Script
# This script runs a standalone nginx SSL proxy for SkillVerse

set -e

echo "🔧 Setting up SSL Proxy for SkillVerse..."

# Configuration
CONTAINER_NAME="skillverse-ssl-proxy"
NETWORK_NAME="skillverse-network"
NGINX_CONFIG_PATH="./nginx/nginx-ssl-simple.conf"
SSL_CERT_PATH="/etc/letsencrypt"
DOMAIN_NAME="skillverse.vn"

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Check if SSL certificates exist
if [ ! -f "$SSL_CERT_PATH/live/$DOMAIN_NAME/fullchain.pem" ]; then
    print_error "SSL certificates not found at $SSL_CERT_PATH/live/$DOMAIN_NAME/"
    print_warning "Please generate SSL certificates first using:"
    echo "  sudo certbot certonly --standalone -d $DOMAIN_NAME"
    exit 1
fi

# Check if nginx config exists
if [ ! -f "$NGINX_CONFIG_PATH" ]; then
    print_error "Nginx configuration not found: $NGINX_CONFIG_PATH"
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_warning "Stopping existing container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

# Create network if it doesn't exist
if ! docker network ls --format 'table {{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
    print_status "Creating network: $NETWORK_NAME"
    docker network create --driver bridge $NETWORK_NAME
else
    print_status "Network $NETWORK_NAME already exists"
fi

# Get absolute path for nginx config
NGINX_CONFIG_ABS_PATH=$(realpath "$NGINX_CONFIG_PATH")
if [ ! -f "$NGINX_CONFIG_ABS_PATH" ]; then
    print_error "Cannot find nginx config at: $NGINX_CONFIG_ABS_PATH"
    exit 1
fi

print_status "Starting SSL Proxy container..."
print_status "Container name: $CONTAINER_NAME"
print_status "Network: $NETWORK_NAME"
print_status "Nginx config: $NGINX_CONFIG_ABS_PATH"
print_status "SSL certificates: $SSL_CERT_PATH"

# Run the SSL proxy container
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -v "$SSL_CERT_PATH:/etc/letsencrypt:ro" \
    -v "$NGINX_CONFIG_ABS_PATH:/etc/nginx/nginx.conf:ro" \
    --network $NETWORK_NAME \
    nginx:alpine

# Wait for container to start
sleep 3

# Check if container is running
if docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -q "$CONTAINER_NAME.*Up"; then
    print_success "SSL Proxy container started successfully!"
    print_status "Container status:"
    docker ps --filter name=$CONTAINER_NAME --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
    
    # Test nginx configuration
    print_status "Testing nginx configuration..."
    if docker exec $CONTAINER_NAME nginx -t; then
        print_success "Nginx configuration is valid!"
    else
        print_error "Nginx configuration test failed!"
        print_status "Container logs:"
        docker logs $CONTAINER_NAME --tail 20
        exit 1
    fi
    
    # Show container logs
    print_status "Recent container logs:"
    docker logs $CONTAINER_NAME --tail 10
    
    echo ""
    print_success "SSL Proxy is ready!"
    print_status "You can now test HTTPS access:"
    echo "  curl -I https://$DOMAIN_NAME"
    echo "  curl -I http://$DOMAIN_NAME (should redirect to HTTPS)"
    echo ""
    print_status "To view logs: docker logs -f $CONTAINER_NAME"
    print_status "To stop: docker stop $CONTAINER_NAME"
    print_status "To restart: docker restart $CONTAINER_NAME"
    
else
    print_error "Failed to start SSL Proxy container!"
    print_status "Container logs:"
    docker logs $CONTAINER_NAME --tail 20
    exit 1
fi