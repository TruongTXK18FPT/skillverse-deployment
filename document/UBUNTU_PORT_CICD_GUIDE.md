# 🌐 Ubuntu Server Port & CI/CD Configuration Guide

## 📋 **Port Mapping Summary:**

| Service | Container Port | Ubuntu Host Port | Access URL |
|---------|---------------|------------------|------------|
| **Frontend (Nginx)** | 80 | 80 | `http://your-server-ip/` |
| **Backend (Spring Boot)** | 8080 | 8080 | `http://your-server-ip:8080/api/` |
| **PostgreSQL** | 5432 | 5432 | Internal only |
| **Redis** | 6379 | 6379 | Internal only |

## 🌐 **Truy cập Application trên Ubuntu:**

### **Frontend (React):**
```bash
# Direct access
http://your-ubuntu-server-ip/

# With domain (if configured)
http://your-domain.com/
```

### **Backend API:**
```bash
# Via Frontend Nginx Proxy (Recommended)
http://your-ubuntu-server-ip/api/health
http://your-ubuntu-server-ip/api/swagger-ui/index.html

# Direct Backend Access
http://your-ubuntu-server-ip:8080/api/health
http://your-ubuntu-server-ip:8080/api/swagger-ui/index.html
```

### **Swagger Documentation:**
```bash
# Swagger UI (Interactive API Documentation)
http://your-ubuntu-server-ip/api/swagger-ui/index.html

# OpenAPI JSON Schema
http://your-ubuntu-server-ip/api/v3/api-docs

# Health Monitoring
http://your-ubuntu-server-ip/api/health
http://your-ubuntu-server-ip/api/health/detailed
```

## 🔄 **CI/CD Auto-Deployment:**

### ✅ **KHÔNG CẦN PULL MANUAL!** 

Khi bạn push code, hệ thống sẽ **TỰ ĐỘNG:**

1. **Frontend Push** → `skillverse-prototype` repo:
   ```bash
   git add .
   git commit -m "Update frontend"
   git push origin main
   ```
   ➡️ Tự động trigger **Frontend CI/CD**
   ➡️ Build, test, security scan
   ➡️ Trigger **Production Deployment**

2. **Backend Push** → `SkillVerse_BackEnd` repo:
   ```bash
   git add .
   git commit -m "Update backend" 
   git push origin main
   ```
   ➡️ Tự động trigger **Backend CI/CD**
   ➡️ Maven build, test, security scan
   ➡️ Trigger **Production Deployment**

### 🚀 **Production Deployment Process:**

#### **Auto-Deployment Workflow:**
```yaml
# Triggers automatically when CI completes successfully
on:
  workflow_run:
    workflows: 
      - "🎯 Frontend CI/CD Pipeline"
      - "🛠️ Backend CI/CD Pipeline"
    types: [completed]
    branches: [main]
```

#### **What happens automatically:**
1. **CI Completes** ✅
2. **Production Deployment Triggers** 🚀
3. **SSH to Ubuntu Server** 🔐
4. **Pull latest code** 📥
5. **Build new Docker images** 🐳
6. **Stop old containers** 🛑
7. **Start new containers** ▶️
8. **Health checks** 🔍
9. **Rollback if failed** ↩️

## 🛠️ **Manual Deployment (Optional):**

### **Via GitHub Actions:**
1. Go to `skillverse-deployment` repository
2. **Actions** → **🚀 Production Deployment**
3. Click **Run workflow**
4. Fill in (or use defaults):
   - Frontend repo: `9m0m/skillverse-prototype`
   - Backend repo: `9m0m/SkillVerse_BackEnd`
   - Frontbranch: `main`
   - Backend branch: `main`
5. Click **Run workflow**

### **Via SSH (Manual):**
```bash
# SSH to your Ubuntu server
ssh username@your-server-ip

# Navigate to project directory
cd /path/to/your/project

# Pull latest changes
git pull origin main

# Rebuild and restart containers
docker compose down
docker compose up --build -d
```

## 🔍 **Monitoring & Health Checks:**

### **Check Application Status:**
```bash
# SSH to server and check containers
ssh username@your-server-ip
docker compose ps

# Check logs
docker compose logs frontend --tail=50
docker compose logs app --tail=50
docker compose logs db --tail=50

# Health check via curl
curl http://localhost/api/health
curl http://localhost/api/health/detailed
```

### **Using Health Check Script:**
```bash
# On Ubuntu server
cd /path/to/skillverse-deployment
chmod +x scripts/check-swagger.sh
./scripts/check-swagger.sh
```

## 🔧 **Troubleshooting:**

### **Port Issues:**
```bash
# Check if ports are in use
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8080

# Check Docker port mapping
docker compose ps
```

### **Container Issues:**
```bash
# Check container status
docker compose ps

# Check logs for errors
docker compose logs frontend --tail=100
docker compose logs app --tail=100

# Restart specific service
docker compose restart frontend
docker compose restart app
```

### **CI/CD Issues:**
```bash
# View workflow runs
gh run list --repo username/skillverse-deployment

# View specific run details
gh run view RUN_ID --repo username/skillverse-deployment
```

## 🔐 **GitHub Secrets Required:**

### **For skillverse-deployment repository:**
```bash
VPS_HOST=your-ubuntu-server-ip
VPS_USER=your-ssh-username
VPS_SSH_KEY=your-private-ssh-key
VPS_PORT=22
VPS_PROJECT_PATH=/path/to/project/on/server
```

### **Setup SSH Key:**
```bash
# Generate SSH key pair (on local machine)
ssh-keygen -t rsa -b 4096 -C "deployment@skillverse"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_rsa.pub username@your-server

# Copy private key to GitHub Secret VPS_SSH_KEY
cat ~/.ssh/id_rsa
```

## 📝 **Development Workflow:**

### **Recommended Process:**
1. **Develop locally** 💻
2. **Test changes** 🧪
3. **Commit & push to main** 📤
4. **CI/CD runs automatically** 🤖
5. **Check deployment status** 👀
6. **Verify on server** ✅

### **Branch Strategy:**
```
main (production) ← Auto-deploy
├── develop (staging)
├── feature/new-feature
└── hotfix/urgent-fix
```

## 🎯 **Summary:**

✅ **Port 80:** Frontend (Nginx) - `http://server-ip/`  
✅ **Port 8080:** Backend (Spring Boot) - `http://server-ip:8080/api/`  
✅ **Auto CI/CD:** Push code → Automatic deployment  
✅ **No manual pull needed:** Everything automated  
✅ **Health monitoring:** Built-in endpoints  
✅ **Swagger access:** `http://server-ip/api/swagger-ui/index.html`  

**Your Ubuntu server is ready for continuous deployment! 🚀📚**