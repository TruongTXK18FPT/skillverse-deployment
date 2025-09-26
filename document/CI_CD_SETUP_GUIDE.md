# 🚀 Hướng dẫn CI/CD Setup cho SkillVerse

## 📋 Tổng quan

Hệ thống CI/CD đã được thiết lập với 3 workflows riêng biệt:

### 1. **Frontend CI/CD** (`skillverse-prototype/.github/workflows/frontend-ci.yml`)
- ✅ Linting với ESLint
- ✅ Build và test
- ✅ Security scanning
- ✅ Docker build
- ✅ Bundle size analysis

### 2. **Backend CI/CD** (`SkillVerse_BackEnd/.github/workflows/backend-ci.yml`)
- ✅ Maven compile, test, package
- ✅ Code coverage với JaCoCo
- ✅ Security scanning với OWASP
- ✅ API documentation generation
- ✅ Docker build và test

### 3. **Production Deployment** (`skillverse-deployment/.github/workflows/production-deploy.yml`)
- ✅ Manual deployment trigger
- ✅ Multi-repository deployment
- ✅ Health checks
- ✅ Auto rollback

## 🛠️ Setup Instructions

### Step 1: GitHub Secrets Setup

Mỗi repository cần các secrets sau:

#### **Frontend Repository Secrets:**
```
# Không cần secrets đặc biệt cho frontend CI
```

#### **Backend Repository Secrets:**
```
# Optional - for enhanced security scanning
SNYK_TOKEN=your-snyk-token-here
```

#### **Deployment Repository Secrets:**
```
VPS_HOST=your-server-ip-or-domain
VPS_USER=your-ssh-username  
VPS_SSH_KEY=your-private-ssh-key
VPS_PORT=22
VPS_PROJECT_PATH=/path/to/project/on/server

# Optional - for DockerHub
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-token
```

### Step 2: Cách setup GitHub Secrets

1. Vào repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Thêm từng secret theo danh sách trên

### Step 3: SSH Key Setup

```bash
# Tạo SSH key pair trên máy local
ssh-keygen -t rsa -b 4096 -C "deployment@skillverse"

# Copy public key lên server
ssh-copy-id -i ~/.ssh/id_rsa.pub username@your-server

# Copy private key vào GitHub Secret VPS_SSH_KEY
cat ~/.ssh/id_rsa
```

## 🚀 Cách sử dụng

### **Frontend Development:**
1. Tạo branch từ `main`
2. Code và commit changes
3. Tạo Pull Request → CI sẽ tự động chạy
4. Merge vào `main` → Docker build sẽ chạy

### **Backend Development:**  
1. Tạo branch từ `main`
2. Code và commit changes
3. Tạo Pull Request → CI sẽ tự động chạy (tests, security scan, etc.)
4. Merge vào `main` → Full CI + Docker build

### **Production Deployment:**
1. Vào **skillverse-deployment** repository
2. **Actions** → **Production Deployment**
3. Click **Run workflow**
4. Điền thông tin:
   - Frontend repo: `9m0m/skillverse-prototype`
   - Backend repo: `9m0m/SkillVerse_BackEnd`
   - Branches: `main` (hoặc tag/commit cụ thể)
5. Click **Run workflow**

## 📊 Monitoring & Health Checks

### **Swagger Documentation:**
```bash
# Truy cập Swagger UI
http://your-server/api/swagger-ui/index.html

# OpenAPI JSON
http://your-server/api/v3/api-docs

# Health Check
http://your-server/api/health
```

### **Server Health Check Script:**
```bash
# SSH vào server
ssh username@your-server

# Chạy health check script
cd /path/to/skillverse-deployment
chmod +x scripts/check-swagger.sh
./scripts/check-swagger.sh
```

### **Manual Health Checks:**
```bash
# Check containers
docker compose ps

# Check logs
docker compose logs backend --tail=50
docker compose logs frontend --tail=50

# Test endpoints
curl http://localhost/api/health
curl http://localhost/api/swagger-ui/index.html
```

## 🔧 Troubleshooting

### **CI/CD Failures:**

#### **Frontend CI fails:**
```bash
# Common issues:
- ESLint errors → Fix code style issues
- Build errors → Check TypeScript/dependencies
- Security vulnerabilities → Update packages
```

#### **Backend CI fails:**
```bash
# Common issues:
- Test failures → Fix unit tests
- Maven build errors → Check dependencies
- Security issues → Update vulnerable packages
```

#### **Deployment fails:**
```bash
# Check server resources
df -h
free -h
docker system df

# Check SSH connectivity
ssh username@your-server

# Check VPS secrets are correct
# Verify paths and permissions
```

### **Swagger Issues:**

#### **Swagger không load:**
```bash
# Check backend logs
docker compose logs backend --tail=50

# Restart backend
docker compose restart backend

# Check internal connectivity
docker compose exec backend curl http://localhost:8080/api/swagger-ui/index.html
```

#### **404 errors:**
```bash
# Check nginx config
docker compose logs nginx --tail=20

# Restart nginx
docker compose restart nginx
```

## 📝 Best Practices

### **Development Workflow:**
1. **Tạo feature branch** từ `main`
2. **Code + commit** với clear messages
3. **Test locally** trước khi push
4. **Create PR** và đợi CI pass
5. **Review code** và merge
6. **Deploy** qua deployment workflow

### **Commit Messages:**
```bash
feat: add user authentication
fix: resolve swagger documentation issue  
docs: update deployment guide
refactor: improve health check endpoints
test: add unit tests for user service
```

### **Branch Strategy:**
```
main (production)
├── develop (staging)
├── feature/user-auth
├── feature/swagger-docs
└── hotfix/critical-bug
```

## 🔐 Security Notes

1. **Secrets Management:** Không commit secrets vào code
2. **SSH Keys:** Sử dụng key riêng cho deployment
3. **Server Access:** Giới hạn SSH access
4. **Docker Images:** Regular security updates
5. **Dependencies:** Monitor cho vulnerabilities

## 📞 Support Commands

```bash
# View workflow runs
gh run list --repo 9m0m/skillverse-prototype

# Check deployment status
gh run view --repo 9m0m/skillverse-deployment

# Quick server check
ssh username@server 'docker compose ps && curl -s http://localhost/api/health'
```

---

## 🎯 Next Steps

1. ✅ **Test workflows** bằng cách tạo test commits
2. ✅ **Setup secrets** cho tất cả repositories  
3. ✅ **Run deployment** lần đầu để verify
4. ✅ **Monitor** và adjust theo cần thiết
5. ✅ **Document** custom configurations

**Happy Deploying! 🚀📚**