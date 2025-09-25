#!/bin/bash

# SkillVerse SSL Certificate Generator
# Generates Let's Encrypt SSL certificates for skillverse.vn

set -e

DOMAIN_NAME="skillverse.vn"
EMAIL="tranxuantin1234@gmail.com"  # Change this to your email

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

echo "🔐 SSL Certificate Generator for SkillVerse"
echo "==========================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   print_status "Run: sudo $0"
   exit 1
fi

# Install certbot if not exists
if ! command -v certbot &> /dev/null; then
    print_status "Installing certbot..."
    apt update
    apt install -y certbot
fi

# Stop services that might use port 80
print_status "Stopping services on port 80/443..."
docker stop skillverse-frontend skillverse-ssl-proxy skillverse-http-proxy 2>/dev/null || true
systemctl stop nginx apache2 2>/dev/null || true

# Generate or renew certificates
if [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
    print_status "SSL certificates exist. Checking if renewal is needed..."
    certbot renew --dry-run
    
    if certbot renew --quiet; then
        print_success "Certificates renewed successfully!"
    else
        print_warning "No renewal needed or renewal failed"
    fi
else
    print_status "Generating new SSL certificates for $DOMAIN_NAME..."
    
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
fi

# Verify certificates
print_status "Certificate information:"
certbot certificates | grep -A 10 "$DOMAIN_NAME"

# Set up permissions
print_status "Setting up certificate permissions..."
chmod 755 /etc/letsencrypt/live/
chmod 755 /etc/letsencrypt/archive/
chmod 644 /etc/letsencrypt/live/$DOMAIN_NAME/*.pem
chmod 600 /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem

print_success "🎉 SSL certificates are ready!"
print_status "Certificate files location:"
echo "  - Certificate: /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
echo "  - Private Key: /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem"
echo "  - Chain: /etc/letsencrypt/live/$DOMAIN_NAME/chain.pem"
echo ""
print_status "Next steps:"
echo "  1. Run SSL proxy: ./scripts/run-ssl-proxy.sh"
echo "  2. Or run full setup: sudo ./scripts/ubuntu-ssl-setup.sh"