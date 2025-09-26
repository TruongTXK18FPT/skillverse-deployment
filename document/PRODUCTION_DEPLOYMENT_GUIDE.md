# 🌐 SkillVerse Production Deployment Guide - skillverse.vn

## 📋 Tổng quan

Hướng dẫn này sẽ giúp bạn deploy SkillVerse lên production server với domain **skillverse.vn** sử dụng 3 repositories:

- **Backend**: https://github.com/TruongTXK18FPT/SkillVerse_BackEnd.git
- **Frontend**: https://github.com/TruongTXK18FPT/skillverse-prototype.git
- **Deployment**: https://github.com/TruongTXK18FPT/skillverse-deployment.git

---

## 🔧 1. Chuẩn bị VPS Ubuntu 22.04

### 1.1 Thông tin VPS cần thiết

- **OS**: Ubuntu 22.04 LTS
- **RAM**: Tối thiểu 4GB (khuyến nghị 8GB)
- **Storage**: Tối thiểu 50GB SSD
- **CPU**: Tối thiểu 2 cores
- **Network**: Public IP address

### 1.2 Update và cài đặt packages cơ bản

```bash
# SSH vào VPS
ssh root@your-vps-ip

# Update system
apt update && apt upgrade -y

# Cài đặt packages cần thiết
apt install -y curl wget git unzip ufw htop nano vim

# Tạo user non-root (recommended)
adduser skillverse
usermod -aG sudo skillverse
su - skillverse
```

---

## 🌐 2. Cấu hình DNS cho skillverse.vn

### 2.1 Trỏ domain về VPS

Truy cập DNS provider của bạn (Cloudflare, GoDaddy, etc.) và thêm các records sau:

```dns
# A Records
Type    Name            Value               TTL
A       @               YOUR_VPS_IP         300
A       www             YOUR_VPS_IP         300
A       api             YOUR_VPS_IP         300

# CNAME Records (Optional)
CNAME   admin           skillverse.vn       300
CNAME   staging         skillverse.vn       300
```

### 2.2 Ví dụ với Cloudflare

1. Đăng nhập Cloudflare → chọn domain skillverse.vn
2. Vào **DNS** → **Records**
3. Thêm records:
   ```
   A     @       YOUR_VPS_IP    Auto
   A     www     YOUR_VPS_IP    Auto
   A     api     YOUR_VPS_IP    Auto
   ```
4. **SSL/TLS** → Set **Full (strict)** sau khi cài SSL certificate

### 2.3 Kiểm tra DNS propagation

```bash
# Kiểm tra từ local machine
nslookup skillverse.vn
ping skillverse.vn

# Hoặc dùng online tools
# https://dnschecker.org
# https://www.whatsmydns.net
```

---

## 🚀 3. Deployment Steps

### 3.1 Clone và setup repositories

```bash
# SSH vào VPS với user non-root
ssh skillverse@your-vps-ip

# Tải script setup
wget https://raw.githubusercontent.com/TruongTXK18FPT/skillverse-deployment/main/setup-multi-repo.sh
chmod +x setup-multi-repo.sh

# Chạy script setup
./setup-multi-repo.sh
```

Script sẽ tự động:

- ✅ Cài đặt Docker & Docker Compose
- ✅ Clone 3 repositories
- ✅ Tạo cấu trúc deployment
- ✅ Setup môi trường

### 3.2 Cấu hình environment

```bash
cd skillverse-workspace/deployment

# Chỉnh sửa .env với thông tin thực tế
nano .env
```

**Các thông số quan trọng cần cập nhật:**

```env
# === SSL Configuration ===
SSL_ENABLED=true
DOMAIN_NAME=skillverse.vn
SSL_EMAIL=admin@skillverse.vn

# === Database Configuration ===
DOCKER_DB_PASSWORD=your_super_secure_password_here

# === Redis Configuration ===
REDIS_PASSWORD=your_redis_password_here

# === Email Configuration ===
SMTP_USERNAME=skillverseexe@gmail.com
SMTP_PASSWORD=your_gmail_app_password

# === Security ===
JWT_SECRET=your_jwt_secret_key_32_characters_minimum
```

### 3.3 Cài đặt SSL Certificate

```bash
# Cài đặt SSL cho skillverse.vn
cd skillverse-workspace/deployment
sudo ./scripts/setup-ssl.sh skillverse.vn admin@skillverse.vn
```

### 3.4 Deploy application

```bash
# Deploy với SSL
cd skillverse-workspace
./deploy-all.sh --ssl
```

---

## 🔒 4. Firewall và Security Setup

### 4.1 Cấu hình UFW Firewall

```bash
# Enable firewall
sudo ufw enable

# Allow essential ports
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS

# Optional: Allow specific IPs only for SSH
# sudo ufw delete allow 22/tcp
# sudo ufw allow from YOUR_IP_ADDRESS to any port 22

# Check status
sudo ufw status verbose
```

### 4.2 SSH Security

```bash
# Tạo SSH key (từ local machine)
ssh-keygen -t ed25519 -C "skillverse-production"

# Copy public key lên VPS
ssh-copy-id -i ~/.ssh/id_ed25519.pub skillverse@your-vps-ip

# Cấu hình SSH security trên VPS
sudo nano /etc/ssh/sshd_config
```

**Cập nhật sshd_config:**

```
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
```

```bash
# Restart SSH service
sudo systemctl restart sshd
```

---

## 📊 5. Monitoring và Health Checks

### 5.1 Health Check Commands

```bash
# Container status
docker compose ps

# Application health
curl https://skillverse.vn/health
curl https://skillverse.vn/api/health

# SSL certificate check
openssl s_client -connect skillverse.vn:443 -servername skillverse.vn

# View logs
docker compose logs -f
```

### 5.2 Setup Monitoring (Optional)

```bash
# Enable monitoring trong .env
MONITORING_ENABLED=true

# Deploy với monitoring
docker compose --profile monitoring up -d

# Access
# Prometheus: http://your-vps-ip:9090
# Grafana: http://your-vps-ip:3000
```

---

## 🔄 6. CI/CD với GitHub Actions

### 6.1 Setup GitHub Secrets

Vào GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Thêm các secrets sau:

```
VPS_HOST=your-vps-ip
VPS_USER=skillverse
VPS_SSH_KEY=your-private-ssh-key-content
VPS_PORT=22
VPS_PROJECT_PATH=/home/skillverse/skillverse-workspace
```

### 6.2 GitHub Actions sẽ tự động deploy khi:

- Push code lên branch `main`
- Tạo pull request vào `main`

---

## 🛠️ 7. Maintenance và Backup

### 7.1 Regular Maintenance

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clean Docker
docker system prune -a

# Renew SSL certificate (tự động với cron)
sudo certbot renew --dry-run

# Backup database
docker compose exec db pg_dump -U skillverse_user skillverse_db > backup_$(date +%Y%m%d).sql
```

### 7.2 Auto Backup Script

```bash
# Tạo backup script
cat > /home/skillverse/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/skillverse/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker compose exec -T db pg_dump -U skillverse_user skillverse_db > $BACKUP_DIR/db_$DATE.sql

# Compress old backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -exec gzip {} \;

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /home/skillverse/backup.sh

# Setup cron job
crontab -e
# Add line: 0 2 * * * /home/skillverse/backup.sh >> /var/log/skillverse-backup.log 2>&1
```

---

## ✅ 8. Verification Checklist

- [ ] DNS records đã trỏ đúng IP
- [ ] SSL certificate đã cài đặt
- [ ] Firewall đã cấu hình
- [ ] Application accessible tại https://skillverse.vn
- [ ] API accessible tại https://skillverse.vn/api
- [ ] Health checks passing
- [ ] Logs không có error
- [ ] Database connection working
- [ ] Redis connection working
- [ ] Email service working
- [ ] Backup script working
- [ ] Monitoring (nếu enable) working

---

## 🆘 9. Troubleshooting

### Common Issues:

**🔴 SSL Certificate Issues:**

```bash
# Kiểm tra certificate
sudo certbot certificates

# Renew manually
sudo certbot renew

# Re-create certificate
sudo certbot delete --cert-name skillverse.vn
sudo ./scripts/setup-ssl.sh skillverse.vn admin@skillverse.vn
```

**🔴 Domain không accessible:**

```bash
# Kiểm tra DNS
nslookup skillverse.vn
dig skillverse.vn

# Kiểm tra nginx
docker compose logs frontend

# Kiểm tra firewall
sudo ufw status
```

**🔴 Database connection failed:**

```bash
# Kiểm tra database container
docker compose exec db pg_isready -U skillverse_user

# Reset database
docker compose down -v
docker compose up -d
```

**🔴 GitHub Actions deployment failed:**

```bash
# Kiểm tra SSH connection
ssh skillverse@your-vps-ip

# Kiểm tra project path
ls -la /home/skillverse/skillverse-workspace

# Xem deployment logs trong GitHub Actions
```

---

## 📞 Support

- **Production URL**: https://skillverse.vn
- **API Documentation**: https://skillverse.vn/swagger-ui.html
- **GitHub Issues**: [Create Issue](https://github.com/TruongTXK18FPT/skillverse-deployment/issues)
- **Emergency Contact**: admin@skillverse.vn

---

**🎉 Chúc mừng! SkillVerse đã sẵn sàng production!** 🚀
