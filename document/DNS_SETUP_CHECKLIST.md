# 🌐 DNS Setup Checklist for skillverse.vn

## ⚡ Quick Setup (5 phút)

### 1. Lấy IP của VPS
```bash
# Từ VPS, chạy lệnh này để lấy IP public
curl ifconfig.me
# Hoặc
curl ipecho.net/plain
```

### 2. Cấu hình DNS Records

**Cần thêm vào DNS provider (Cloudflare, GoDaddy, etc.):**

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | `YOUR_VPS_IP` | 300 |
| A | www | `YOUR_VPS_IP` | 300 |
| A | api | `YOUR_VPS_IP` | 300 |

### 3. Kiểm tra DNS (Chờ 5-10 phút)

```bash
# Từ local machine hoặc VPS
nslookup skillverse.vn
ping skillverse.vn

# Hoặc dùng online tool:
# https://dnschecker.org
```

### 4. Deploy SkillVerse

```bash
# SSH vào VPS
ssh your-user@your-vps-ip

# Tải và chạy script deploy
wget https://raw.githubusercontent.com/your-repo/deploy-skillverse-production.sh
chmod +x deploy-skillverse-production.sh
./deploy-skillverse-production.sh
```

---

## 📋 Chi tiết cho từng DNS Provider

### Cloudflare
1. Login → chọn domain skillverse.vn
2. **DNS** → **Records** → **Add record**
3. Thêm 3 records như bảng trên
4. **SSL/TLS** → **Overview** → chọn **Full (strict)**

### GoDaddy
1. **My Products** → **DNS** → **Manage Zones**
2. Chọn skillverse.vn → **Add New Record**
3. Thêm 3 records A như trên

### Namecheap
1. **Domain List** → **Manage** → **Advanced DNS**
2. **Add New Record** → chọn **A Record**
3. Thêm records theo bảng

---

## ✅ Verification Commands

```bash
# Test DNS resolution
dig skillverse.vn
dig www.skillverse.vn

# Test HTTP/HTTPS (sau khi deploy)
curl -I http://skillverse.vn
curl -I https://skillverse.vn

# Test API
curl https://skillverse.vn/api/health
```

---

## 🚨 Common Issues

**DNS không resolve:**
- Chờ thêm 10-15 phút (DNS propagation)
- Xóa cache DNS: `ipconfig /flushdns` (Windows) hoặc `sudo systemctl restart systemd-resolved` (Ubuntu)

**SSL certificate error:**
- Đảm bảo DNS đã resolve đúng IP
- Chạy lại: `sudo certbot certificates` và `sudo certbot renew`

**Website không accessible:**
- Kiểm tra firewall: `sudo ufw status`
- Kiểm tra containers: `docker compose ps`
- Xem logs: `docker compose logs`

---

## 📞 Ready to Deploy?

1. ✅ VPS Ubuntu 22.04 ready
2. ✅ DNS records added  
3. ✅ Domain resolves to VPS IP

**Run this command:**
```bash
bash <(curl -s https://raw.githubusercontent.com/TruongTXK18FPT/skillverse-deployment/main/deploy-skillverse-production.sh)
```

🎉 **Sau 10-15 phút, SkillVerse sẽ live tại https://skillverse.vn!**