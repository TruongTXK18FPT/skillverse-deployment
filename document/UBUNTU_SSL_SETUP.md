# SkillVerse Ubuntu SSL Setup Guide

## 📋 Prerequisites
- Ubuntu VPS với domain skillverse.vn đã point DNS
- Docker và Docker Compose đã cài đặt
- Ports 80, 443 đã mở trong firewall

## 🔄 Step 1: Pull latest deployment code
```bash
# SSH vào Ubuntu server
ssh your-user@your-server-ip

# Navigate to deployment directory
cd /opt/skillverse/skillverse-deployment

# Pull latest changes
git pull origin main

# Check new files
ls -la scripts/
ls -la nginx/
```

## 🔐 Step 2: Generate SSL certificates
```bash
# Install Certbot if not already installed
sudo apt update
sudo apt install -y certbot

# Stop any services using ports 80/443
sudo docker stop skillverse-frontend skillverse-http-proxy skillverse-ssl-proxy 2>/dev/null || true

# Generate SSL certificates for skillverse.vn
sudo certbot certonly --standalone \
  -d skillverse.vn \
  -d www.skillverse.vn \
  --email your-email@domain.com \
  --agree-tos \
  --non-interactive

# Verify certificates
sudo ls -la /etc/letsencrypt/live/skillverse.vn/
```

## 🚀 Step 3: Run SSL proxy
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run SSL proxy setup
./scripts/run-ssl-proxy.sh

# Or manually run:
docker run -d \
  --name skillverse-ssl-proxy \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  -v $(pwd)/nginx/nginx-ssl-simple.conf:/etc/nginx/nginx.conf:ro \
  --network skillverse-network \
  nginx:alpine
```

## ✅ Step 4: Test HTTPS
```bash
# Test SSL connection
curl -I https://skillverse.vn
curl -I http://skillverse.vn  # Should redirect to HTTPS

# Check certificate
curl -vI https://skillverse.vn 2>&1 | grep -i certificate

# Test API through SSL proxy
curl https://skillverse.vn/api/health
```

## 🔄 Step 5: Auto-renewal setup
```bash
# Create renewal script
sudo tee /etc/cron.d/letsencrypt-renewal << 'EOF'
# Renew Let's Encrypt certificates and restart SSL proxy
0 2 * * 1 root certbot renew --quiet && docker restart skillverse-ssl-proxy
EOF

# Test renewal (dry run)
sudo certbot renew --dry-run
```

## 🛠️ Troubleshooting
```bash
# Check container logs
docker logs skillverse-ssl-proxy

# Check nginx config
docker exec skillverse-ssl-proxy nginx -t

# Check certificate expiry
sudo certbot certificates

# Restart SSL proxy if needed
docker restart skillverse-ssl-proxy
```