#!/bin/bash

# 🔒 SSL Setup Script for SkillVerse using Let's Encrypt
# Usage: sudo ./setup-ssl.sh your-domain.com [your-email@domain.com]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run this script as root (use sudo)${NC}"
    exit 1
fi

# Get domain from argument
DOMAIN=$1
EMAIL=$2

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Usage: sudo $0 your-domain.com [your-email@domain.com]${NC}"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    EMAIL="webmaster@${DOMAIN}"
    echo -e "${YELLOW}⚠️  No email provided, using: $EMAIL${NC}"
fi

echo -e "${BLUE}🔒 Setting up SSL for: $DOMAIN${NC}"
echo -e "${BLUE}📧 Contact email: $EMAIL${NC}"

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt update -qq

# Install certbot
echo -e "${YELLOW}🔧 Installing Certbot...${NC}"
apt install -y certbot python3-certbot-nginx

# Create webroot directory for challenges
echo -e "${YELLOW}📁 Creating webroot directory...${NC}"
mkdir -p /var/www/certbot
chown -R www-data:www-data /var/www/certbot

# Stop nginx if running
echo -e "${YELLOW}🛑 Stopping nginx...${NC}"
systemctl stop nginx 2>/dev/null || docker stop nginx 2>/dev/null || true

# Get certificate
echo -e "${YELLOW}🔐 Obtaining SSL certificate...${NC}"
certbot certonly \
    --standalone \
    --preferred-challenges http \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --domains "$DOMAIN" \
    --domains "www.$DOMAIN"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to obtain SSL certificate${NC}"
    exit 1
fi

# Create renewal hook
echo -e "${YELLOW}🔄 Setting up auto-renewal...${NC}"
cat > /etc/letsencrypt/renewal-hooks/deploy/skillverse-reload.sh << 'EOF'
#!/bin/bash
# Reload nginx after certificate renewal
if docker ps | grep -q nginx; then
    docker exec nginx nginx -t && docker exec nginx nginx -s reload
else
    systemctl reload nginx 2>/dev/null || true
fi
EOF

chmod +x /etc/letsencrypt/renewal-hooks/deploy/skillverse-reload.sh

# Test auto-renewal
echo -e "${YELLOW}🧪 Testing auto-renewal...${NC}"
certbot renew --dry-run

# Setup cron job for renewal
echo -e "${YELLOW}⏰ Setting up cron job for auto-renewal...${NC}"
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Create SSL configuration template
echo -e "${YELLOW}📝 Creating SSL configuration...${NC}"
cat > /tmp/ssl-params.conf << 'EOF'
# SSL Configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# Security Headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
EOF

# Update nginx-ssl.conf with actual domain
if [ -f "nginx-ssl.conf" ]; then
    echo -e "${YELLOW}🔧 Updating nginx-ssl.conf with your domain...${NC}"
    sed -i "s/your-domain.com/$DOMAIN/g" nginx-ssl.conf
    echo -e "${GREEN}✅ nginx-ssl.conf updated with domain: $DOMAIN${NC}"
fi

# Display certificate info
echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
echo -e "${BLUE}📋 Certificate Information:${NC}"
certbot certificates

echo -e "${BLUE}📁 Certificate files location:${NC}"
echo -e "${GREEN}   Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem${NC}"
echo -e "${GREEN}   Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem${NC}"
echo -e "${GREEN}   Chain: /etc/letsencrypt/live/$DOMAIN/chain.pem${NC}"

echo -e "${BLUE}🔄 Next Steps:${NC}"
echo -e "${YELLOW}   1. Update your nginx-ssl.conf with your actual domain${NC}"
echo -e "${YELLOW}   2. Run: ./deploy.sh --ssl${NC}"
echo -e "${YELLOW}   3. Test SSL: https://$DOMAIN${NC}"

echo -e "${GREEN}🎉 SSL setup completed successfully!${NC}"