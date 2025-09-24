#!/bin/bash

# 🚀 SkillVerse Production Quick Deploy Script
# Domain: skillverse.vn
# Usage: bash deploy-skillverse-production.sh

set -e

echo "🌟 ====================================="
echo "🚀 SkillVerse Production Deployment"
echo "🌐 Domain: skillverse.vn"
echo "🌟 ====================================="

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_warning "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me || curl -s ipecho.net/plain || curl -s icanhazip.com)
print_status "Detected server IP: $SERVER_IP"

# Step 1: System Update
print_status "Step 1: Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip ufw htop nano vim net-tools

print_success "System updated successfully!"

# Step 2: Install Docker
print_status "Step 2: Installing Docker and Docker Compose..."

# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

print_success "Docker and Docker Compose installed!"

# Step 3: Configure Firewall
print_status "Step 3: Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

print_success "Firewall configured!"

# Step 4: Create project structure
print_status "Step 4: Setting up project structure..."

mkdir -p ~/skillverse-workspace
cd ~/skillverse-workspace

# Clone repositories
print_status "Cloning repositories..."

git clone https://github.com/TruongTXK18FPT/SkillVerse_BackEnd.git backend
git clone https://github.com/TruongTXK18FPT/skillverse-prototype.git frontend  
git clone https://github.com/TruongTXK18FPT/skillverse-deployment.git deployment

print_success "Repositories cloned!"

# Step 5: Setup deployment files
print_status "Step 5: Setting up deployment configuration..."

cd deployment

# Copy environment file
cp .env.example .env

# Update .env with domain information
sed -i "s/your-domain.com/skillverse.vn/g" .env
sed -i "s/your_email@example.com/admin@skillverse.vn/g" .env
sed -i "s/SSL_ENABLED=false/SSL_ENABLED=true/g" .env

print_success "Environment configured!"

# Step 6: Install SSL certificate
print_status "Step 6: Installing SSL certificate for skillverse.vn..."

# Install certbot
sudo apt install -y certbot

# Check if domain resolves to this server
DOMAIN_IP=$(nslookup skillverse.vn | grep -A1 "Non-authoritative answer:" | grep "Address:" | awk '{print $2}' | head -1)

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    print_warning "DNS not properly configured!"
    print_warning "Domain skillverse.vn resolves to: $DOMAIN_IP"
    print_warning "Server IP is: $SERVER_IP"
    print_warning "Please update your DNS records first:"
    echo ""
    echo "Add these DNS records:"
    echo "A     @       $SERVER_IP"
    echo "A     www     $SERVER_IP"
    echo "A     api     $SERVER_IP"
    echo ""
    read -p "Press Enter after updating DNS records..."
fi

# Setup SSL
chmod +x ./scripts/setup-ssl.sh
sudo ./scripts/setup-ssl.sh skillverse.vn admin@skillverse.vn

print_success "SSL certificate installed!"

# Step 7: Deploy application
print_status "Step 7: Deploying SkillVerse application..."

# Make deploy script executable
chmod +x ../deploy-all.sh

# Deploy with SSL
../deploy-all.sh --ssl

print_success "Application deployed!"

# Step 8: Final verification
print_status "Step 8: Running health checks..."

sleep 30  # Wait for services to start

# Check container status
print_status "Container status:"
docker compose ps

# Test application
print_status "Testing application endpoints..."

# Test HTTP redirect to HTTPS
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://skillverse.vn || echo "000")
print_status "HTTP status: $HTTP_STATUS"

# Test HTTPS
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://skillverse.vn || echo "000")
print_status "HTTPS status: $HTTPS_STATUS"

# Test API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://skillverse.vn/api/health || echo "000")
print_status "API status: $API_STATUS"

# Final summary
echo ""
print_success "🎉 SkillVerse Production Deployment Complete!"
echo ""
echo "📊 Deployment Summary:"
echo "  🌐 Domain: https://skillverse.vn"
echo "  🔒 SSL: Enabled"
echo "  🐳 Containers: $(docker compose ps --services | wc -l) services"
echo "  💾 Database: PostgreSQL 17"
echo "  ⚡ Cache: Redis 7"
echo "  🔥 Status: $(docker compose ps --filter status=running | wc -l) running"
echo ""
echo "🔗 Important URLs:"
echo "  Frontend: https://skillverse.vn"
echo "  API: https://skillverse.vn/api"
echo "  Health Check: https://skillverse.vn/api/health"
echo "  API Docs: https://skillverse.vn/swagger-ui.html"
echo ""
echo "🛠️ Useful Commands:"
echo "  View logs: cd ~/skillverse-workspace/deployment && docker compose logs -f"
echo "  Restart: cd ~/skillverse-workspace/deployment && docker compose restart"
echo "  Update: cd ~/skillverse-workspace && ./deploy-all.sh --ssl"
echo ""

# Setup cron job for SSL renewal
print_status "Setting up SSL auto-renewal..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/certbot renew --quiet") | crontab -

print_success "SSL auto-renewal configured!"

# Create maintenance aliases
print_status "Creating maintenance aliases..."
cat >> ~/.bashrc << 'EOF'

# SkillVerse aliases
alias skillverse-logs='cd ~/skillverse-workspace/deployment && docker compose logs -f'
alias skillverse-status='cd ~/skillverse-workspace/deployment && docker compose ps'
alias skillverse-restart='cd ~/skillverse-workspace/deployment && docker compose restart'
alias skillverse-update='cd ~/skillverse-workspace && ./deploy-all.sh --ssl'
alias skillverse-backup='cd ~/skillverse-workspace/deployment && docker compose exec -T db pg_dump -U skillverse_user skillverse_db > ~/backup_$(date +%Y%m%d_%H%M%S).sql'

EOF

print_success "Maintenance aliases added to ~/.bashrc"

echo ""
print_success "✅ All done! SkillVerse is now running at https://skillverse.vn"
print_warning "💡 Reload your shell: source ~/.bashrc"
print_warning "🔄 Or start a new session to use the new aliases"

echo ""
echo "🆘 Need help? Check the logs:"
echo "   skillverse-logs"
echo ""
echo "📧 Support: admin@skillverse.vn"
echo "🌟 ====================================="