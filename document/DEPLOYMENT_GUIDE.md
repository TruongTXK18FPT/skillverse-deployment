# 🚀 SkillVerse CI/CD & SSL Setup Guide

## 📋 Overview
Hướng dẫn thiết lập CI/CD pipeline với GitHub Actions và SSL cho SkillVerse trên VPS Ubuntu 22.04.

---

## 🔧 1. VPS Setup (Ubuntu 22.04)

### 1.1 Update System & Install Dependencies
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Install Docker Compose V2
sudo apt install -y docker-compose-plugin

# Reboot to apply changes
sudo reboot
```

### 1.2 Create Project Directory
```bash
# Create project directory
sudo mkdir -p /opt/skillverse
sudo chown $USER:$USER /opt/skillverse
cd /opt/skillverse

# Clone repository
git clone https://github.com/your-username/skillverse.git .

# Make scripts executable
chmod +x deploy.sh setup-ssl.sh
```

### 1.3 Configure Firewall
```bash
# Enable UFW
sudo ufw enable

# Allow SSH, HTTP, HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check status
sudo ufw status
```

---

## 🔒 2. SSL Setup với Let's Encrypt

### 2.1 Domain Setup
- ✅ Point your domain to VPS IP
- ✅ Verify DNS propagation: `nslookup your-domain.com`

### 2.2 Run SSL Setup Script
```bash
# Replace with your actual domain and email
sudo ./setup-ssl.sh your-domain.com your-email@domain.com
```

### 2.3 Update Nginx Configuration
```bash
# Edit nginx-ssl.conf with your domain
sed -i 's/your-domain.com/youractual-domain.com/g' nginx-ssl.conf

# Verify configuration
grep "youractual-domain.com" nginx-ssl.conf
```

### 2.4 Test SSL Certificate
```bash
# Check certificate status
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run
```

---

## 🔄 3. GitHub Actions Setup

### 3.1 Repository Secrets
Go to GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
```
VPS_HOST=your-vps-ip-address
VPS_USER=your-username
VPS_SSH_KEY=your-private-ssh-key
VPS_PORT=22
VPS_PROJECT_PATH=/opt/skillverse
```

### 3.2 SSH Key Setup
```bash
# On your local machine, generate SSH key
ssh-keygen -t ed25519 -C "github-actions@skillverse"

# Copy public key to VPS
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@your-vps-ip

# Copy private key content to GitHub secret VPS_SSH_KEY
cat ~/.ssh/id_ed25519
```

### 3.3 Test SSH Connection
```bash
# Test connection from local machine
ssh -i ~/.ssh/id_ed25519 user@your-vps-ip

# Test from GitHub Actions (should work automatically after setup)
```

---

## 🚀 4. Deployment Process

### 4.1 Manual Deployment (HTTP)
```bash
cd /opt/skillverse
git pull origin main
./deploy.sh
```

### 4.2 Manual Deployment (HTTPS)
```bash
cd /opt/skillverse
git pull origin main
./deploy.sh --ssl
```

### 4.3 Automated Deployment
- Push code to `main` branch
- GitHub Actions will automatically deploy
- Check Actions tab for deployment status

---

## ✅ 5. Testing & Verification

### 5.1 Health Checks
```bash
# Test endpoints
curl http://localhost/health
curl http://localhost/api/health

# With SSL
curl https://your-domain.com/health
curl https://your-domain.com/api/health
```

### 5.2 SSL Verification
```bash
# Check SSL grade
curl -I https://your-domain.com

# SSL Labs test (online)
# https://www.ssllabs.com/ssltest/
```

### 5.3 Performance Testing
```bash
# Basic load test
ab -n 100 -c 10 https://your-domain.com/

# Check response times
curl -w "@curl-format.txt" -o /dev/null -s https://your-domain.com/
```

---

## 🔧 6. Monitoring & Logs

### 6.1 Container Logs
```bash
# View all logs
docker compose logs -f

# Specific service logs
docker compose logs -f frontend
docker compose logs -f app
docker compose logs -f db
```

### 6.2 Nginx Logs
```bash
# Access logs
docker compose exec frontend tail -f /var/log/nginx/access.log

# Error logs
docker compose exec frontend tail -f /var/log/nginx/error.log
```

### 6.3 System Monitoring
```bash
# Container stats
docker stats

# System resources
htop
df -h
free -m
```

---

## 🛠️ 7. Troubleshooting

### 7.1 Common Issues

**🔴 SSL Certificate Issues:**
```bash
# Regenerate certificate
sudo certbot delete
sudo ./setup-ssl.sh your-domain.com

# Check certificate expiry
sudo certbot certificates
```

**🔴 Container Health Check Failures:**
```bash
# Check container status
docker compose ps

# Restart specific service
docker compose restart app

# Rebuild and restart
docker compose down
docker compose up --build -d
```

**🔴 GitHub Actions SSH Issues:**
```bash
# Test SSH connection manually
ssh -i ~/.ssh/id_ed25519 user@vps-ip

# Check VPS firewall
sudo ufw status

# Verify SSH key in GitHub secrets
```

### 7.2 Performance Issues
```bash
# Clean up Docker
docker system prune -a

# Check disk space
df -h

# Monitor resource usage
docker stats --no-stream
```

---

## 📊 8. Security Checklist

- ✅ SSL/TLS certificates configured
- ✅ Firewall enabled (UFW)
- ✅ SSH key-based authentication
- ✅ Security headers in nginx
- ✅ Content Security Policy enabled
- ✅ Rate limiting configured
- ✅ Container running as non-root
- ✅ Secrets stored securely
- ✅ Regular security updates

---

## 🎯 9. Quick Commands

```bash
# Deployment
./deploy.sh --ssl              # HTTPS deployment
./deploy.sh                    # HTTP deployment

# SSL
sudo ./setup-ssl.sh domain.com email@domain.com

# Monitoring
docker compose logs -f         # All logs
docker compose ps              # Container status
docker stats                   # Resource usage

# Maintenance
docker system prune -a         # Clean up
sudo certbot renew            # Renew SSL
git pull && ./deploy.sh --ssl  # Update & deploy
```

---

## 📞 Support

For issues or questions:
- 📧 Email: support@skillverse.com
- 🐛 GitHub Issues: [Create Issue](https://github.com/your-repo/issues)
- 📖 Documentation: [Wiki](https://github.com/your-repo/wiki)

---

**🎉 Happy Deploying!** 🚀