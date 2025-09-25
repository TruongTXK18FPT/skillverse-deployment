#!/bin/bash

# SkillVerse Complete SSL Setup for Ubuntu
# This script sets up SSL certificates and SSL proxy

set -e

# Configuration
DOMAIN_NAME="skillverse.vn"
EMAIL="admin@skillverse.vn"  # Change this to your email
CONTAINER_NAME="skillverse-ssl-proxy"
NETWORK_NAME="skillverse-network"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 SkillVerse SSL Setup for Ubuntu Server"
echo "=========================================="

# Check if running as root for SSL certificate generation
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root for SSL certificate generation"
   print_status "Run: sudo $0"
   exit 1
fi

# Step 1: Update system and install dependencies
print_status "Step 1: Installing dependencies..."
apt update
apt install -y certbot docker.io docker-compose curl

# Start Docker if not running
systemctl start docker
systemctl enable docker

# Step 2: Stop any conflicting services
print_status "Step 2: Stopping conflicting services..."
docker stop $CONTAINER_NAME skillverse-frontend skillverse-http-proxy 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Check if ports are free
if netstat -tuln | grep -q ':80\|:443'; then
    print_warning "Ports 80 or 443 are in use. Stopping services..."
    # Try to stop nginx or apache if running
    systemctl stop nginx apache2 2>/dev/null || true
fi

# Step 3: Generate SSL certificates
print_status "Step 3: Generating SSL certificates for $DOMAIN_NAME..."
if [ ! -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
    print_status "Generating new SSL certificate..."
    certbot certonly --standalone \
        -d $DOMAIN_NAME \
        -d www.$DOMAIN_NAME \
        --email $EMAIL \
        --agree-tos \
        --non-interactive
    
    if [ $? -eq 0 ]; then
        print_success "SSL certificates generated successfully!"
    else
        print_error "Failed to generate SSL certificates!"
        exit 1
    fi
else
    print_success "SSL certificates already exist!"
    # Check if certificates are valid
    certbot certificates | grep -A 5 $DOMAIN_NAME
fi

# Step 4: Create Docker network
print_status "Step 4: Setting up Docker network..."
if ! docker network ls | grep -q $NETWORK_NAME; then
    docker network create --driver bridge $NETWORK_NAME
    print_success "Network $NETWORK_NAME created!"
else
    print_success "Network $NETWORK_NAME already exists!"
fi

# Step 5: Start backend services if they exist
print_status "Step 5: Starting backend services..."
if [ -f "./docker/docker-compose.prod.yml" ]; then
    print_status "Starting backend services..."
    cd docker
    docker-compose -f docker-compose.prod.yml up -d db redis app
    cd ..
    
    # Wait for backend to be ready
    print_status "Waiting for backend to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8080/api/health > /dev/null; then
            print_success "Backend is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            print_warning "Backend may not be ready yet, but continuing..."
        fi
        sleep 2
    done
else
    print_warning "Backend docker-compose not found, SSL proxy will start without backend"
fi

# Step 6: Start SSL Proxy
print_status "Step 6: Starting SSL Proxy..."
NGINX_CONFIG_PATH="./nginx/nginx-ssl-simple.conf"

if [ ! -f "$NGINX_CONFIG_PATH" ]; then
    print_error "Nginx config not found: $NGINX_CONFIG_PATH"
    exit 1
fi

# Get absolute path
NGINX_CONFIG_ABS_PATH=$(realpath "$NGINX_CONFIG_PATH")

print_status "Starting SSL proxy container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -v /etc/letsencrypt:/etc/letsencrypt:ro \
    -v /var/www/certbot:/var/www/certbot:ro \
    -v "$NGINX_CONFIG_ABS_PATH:/etc/nginx/nginx.conf:ro" \
    --network $NETWORK_NAME \
    nginx:alpine

# Wait and check
sleep 5

if docker ps | grep -q $CONTAINER_NAME; then
    print_success "SSL Proxy started successfully!"
    
    # Test nginx config
    if docker exec $CONTAINER_NAME nginx -t; then
        print_success "Nginx configuration is valid!"
    else
        print_error "Nginx configuration test failed!"
        docker logs $CONTAINER_NAME --tail 20
        exit 1
    fi
    
    # Show status
    docker ps --filter name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
else
    print_error "Failed to start SSL proxy!"
    docker logs $CONTAINER_NAME --tail 20
    exit 1
fi

# Step 7: Test HTTPS
print_status "Step 7: Testing HTTPS..."
sleep 3

echo ""
print_success "🎉 SSL Setup Complete!"
print_status "Testing URLs:"
echo "  curl -I https://$DOMAIN_NAME"
echo "  curl -I http://$DOMAIN_NAME (should redirect)"

# Test the endpoints
print_status "Testing HTTPS connection..."
if curl -I -s -k https://$DOMAIN_NAME | grep -q "200 OK"; then
    print_success "✅ HTTPS is working!"
else
    print_warning "⚠️  HTTPS test failed, check logs:"
    docker logs $CONTAINER_NAME --tail 10
fi

# Step 8: Setup auto-renewal
print_status "Step 8: Setting up SSL certificate auto-renewal..."
cat > /etc/cron.d/letsencrypt-renewal << 'EOF'
# Renew Let's Encrypt certificates and restart SSL proxy
0 2 * * 1 root certbot renew --quiet && docker restart skillverse-ssl-proxy
EOF

print_success "Auto-renewal cron job created!"

# Final status
echo ""
echo "=========================================="
print_success "🚀 SkillVerse HTTPS Setup Complete!"
echo "=========================================="
print_status "Services running:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
print_status "Management commands:"
echo "  View logs: docker logs -f $CONTAINER_NAME"
echo "  Restart:   docker restart $CONTAINER_NAME"
echo "  Stop:      docker stop $CONTAINER_NAME"
echo "  Renew SSL: certbot renew"
echo ""
print_status "Your site should now be available at:"
echo "  🌐 https://$DOMAIN_NAME"
echo "  🔄 http://$DOMAIN_NAME (redirects to HTTPS)"