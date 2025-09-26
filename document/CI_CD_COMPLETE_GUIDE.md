# 🚀 SkillVerse Complete CI/CD System

## 📋 Overview

Hệ thống CI/CD hoàn chỉnh cho SkillVerse bao gồm:
- ✅ **Frontend CI/CD**: React/TypeScript application
- ✅ **Backend CI/CD**: Spring Boot application  
- ✅ **Full Stack Deployment**: Tự động deploy khi có thay đổi
- ✅ **Swagger Integration**: API documentation tự động

## 🏗️ CI/CD Workflows Structure

```
.github/workflows/
├── frontend-ci.yml        # 🌐 Frontend CI/CD pipeline
├── backend-ci.yml         # ☕ Backend CI/CD pipeline  
└── deploy-full-stack.yml  # 🚀 Full deployment pipeline
```

## 🌐 Frontend CI/CD Pipeline

**File**: `.github/workflows/frontend-ci.yml`

### 🔄 Trigger:
- Push/PR to `main`, `develop` branches
- Changes in `skillverse-prototype/**` directory

### 🚀 Jobs:
1. **🔍 Code Quality & Testing**
   - Lint checking với ESLint
   - TypeScript type checking
   - Build validation
   - Bundle size analysis

2. **🔒 Security Scan**
   - Dependency vulnerability scanning
   - Audit với npm audit

3. **🐳 Docker Build** (main branch only)
   - Build Docker image
   - Test container functionality
   - Push to registry (optional)

4. **📊 Deployment Status**
   - Report results
   - Comment on PRs

## ☕ Backend CI/CD Pipeline

**File**: `.github/workflows/backend-ci.yml`

### 🔄 Trigger:
- Push/PR to `main`, `develop` branches  
- Changes in `SkillVerse_BackEnd/**` directory

### 🚀 Jobs:
1. **🔍 Code Quality & Testing**
   - Maven compile & package
   - Unit tests với JUnit
   - Code coverage với JaCoCo
   - Code style với Checkstyle
   - Static analysis với SpotBugs

2. **🔒 Security & Dependency Scan**
   - OWASP dependency check
   - Snyk security scan (nếu có token)

3. **📚 API Documentation**
   - Generate OpenAPI specification
   - Extract Swagger docs
   - Upload API documentation artifacts

4. **🐳 Docker Build** (main branch only)
   - Build JAR file
   - Create Docker image
   - Test with PostgreSQL
   - Health checks

5. **⚡ Performance Testing** (main branch only)
   - JMH benchmarks (nếu có)

6. **📊 Deployment Status**
   - Report results
   - Comment on PRs

## 🚀 Full Stack Deployment Pipeline

**File**: `.github/workflows/deploy-full-stack.yml`

### 🔄 Trigger:
- Push to `main` branch
- After frontend/backend CI completion

### 🚀 Jobs:
1. **🔍 Pre-deployment Checks**
   - Detect what changed (frontend/backend)
   - Determine if deployment needed

2. **🏗️ Build All Components**
   - Build frontend (nếu có thay đổi)
   - Build backend (nếu có thay đổi)
   - Validate Docker Compose

3. **🚀 Deploy to VPS**
   - SSH to production server
   - Create backup
   - Update codebase
   - Stop current services
   - Build & start new services
   - Health checks & verification

4. **✅ Post-deployment Verification**
   - External health checks
   - Test critical endpoints
   - Verify Swagger accessibility

5. **🔄 Rollback on Failure**
   - Auto rollback nếu deployment fail
   - Restore từ backup

## 🔧 Setup Instructions

### 1. 📋 Required GitHub Secrets:

```bash
# VPS Access
VPS_HOST=your-server-ip-or-domain
VPS_USER=your-ssh-username  
VPS_SSH_KEY=your-private-ssh-key
VPS_PORT=22
VPS_PROJECT_PATH=/path/to/project/on/server

# Optional: Docker Registry
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-token

# Optional: Security Scanning
SNYK_TOKEN=your-snyk-token
```

### 2. 🖥️ Server Setup:

```bash
# Trên Ubuntu server
# Install Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Clone project
git clone https://github.com/yourusername/skillverse.git
cd skillverse

# Setup permissions
chmod +x skillverse-deployment/scripts/*.sh
```

### 3. 🚀 First Deployment:

```bash
# Manual first deployment
cd skillverse-deployment
./deploy.sh

# Or use Docker Compose directly
docker compose up -d --build
```

## 📊 Monitoring & Health Checks

### 🏥 Health Endpoints:

```bash
# Basic health
GET /api/health

# Detailed health  
GET /api/health/detailed

# Readiness check
GET /api/ready

# Liveness check  
GET /api/live
```

### 📚 Swagger/API Documentation:

```bash
# Swagger UI
http://your-server/api/swagger-ui/index.html

# OpenAPI JSON
http://your-server/api/v3/api-docs

# OpenAPI YAML
http://your-server/api/v3/api-docs.yaml
```

### 🔍 Quick Health Check Script:

```bash
# Chạy trên server
cd skillverse-deployment
chmod +x scripts/check-swagger.sh
./scripts/check-swagger.sh
```

## 🛠️ Development Workflow

### 🌟 Feature Development:
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes to frontend/backend
3. Push branch: `git push origin feature/new-feature`
4. Create Pull Request
5. CI/CD sẽ chạy tests và quality checks
6. Merge to `develop` để test staging
7. Merge to `main` để deploy production

### ⚡ Hotfix Workflow:
1. Create hotfix branch: `git checkout -b hotfix/urgent-fix`
2. Make minimal changes
3. Push và create PR
4. CI/CD checks pass
5. Merge directly to `main`
6. Auto deployment sẽ chạy

## 🔍 Troubleshooting

### ❌ CI/CD Pipeline Failures:

#### Frontend Issues:
```bash
# Lint errors
npm run lint --fix

# Build errors  
npm run build

# Type errors
npm run type-check
```

#### Backend Issues:
```bash
# Compile errors
./mvnw compile

# Test failures
./mvnw test

# Dependency issues
./mvnw dependency:tree
```

#### Deployment Issues:
```bash
# Check server logs
ssh user@server
cd /path/to/project
docker compose logs --tail=50

# Manual deployment
./deploy.sh

# Rollback
docker compose down
# Restore from backup
```

### 🔧 Common Fixes:

#### 1. Build Failures:
- Check dependency versions
- Clear caches: `npm ci` hoặc `./mvnw clean`
- Update Docker base images

#### 2. Test Failures:
- Check test database configuration
- Verify test data setup
- Review environment variables

#### 3. Deployment Failures:
- Verify SSH keys và permissions
- Check server disk space
- Validate Docker Compose file
- Check port conflicts

#### 4. Swagger Issues:
- Verify SpringDoc configuration
- Check nginx proxy settings
- Test internal connectivity

## 📈 Performance Monitoring

### 📊 Metrics to Watch:
- Build times (target: <5 minutes)
- Test execution time
- Docker image sizes
- Deployment duration
- Application startup time

### 🔍 Optimization Tips:
- Use Docker layer caching
- Parallel job execution
- Incremental builds
- Artifact caching

## 🔒 Security Best Practices

### 🛡️ Implemented:
- ✅ Dependency vulnerability scanning
- ✅ Static code analysis
- ✅ Secret management với GitHub Secrets
- ✅ Isolated test environments
- ✅ JWT authentication trong Swagger

### 🔐 Additional Recommendations:
- Enable branch protection rules
- Require PR reviews
- Use signed commits
- Regular security audits
- Monitor for suspicious activities

## 📞 Support & Maintenance

### 📋 Regular Tasks:
- Update dependencies monthly
- Review security scan results
- Monitor build/deployment times
- Check disk space on servers
- Backup database regularly

### 🆘 Emergency Procedures:
1. **Rollback**: Revert last deployment
2. **Hotfix**: Direct fix to production
3. **Incident Response**: Follow documented procedures
4. **Recovery**: Restore from backups

## 🎯 Future Enhancements

### 🚀 Planned Improvements:
- [ ] Multi-environment deployments (staging/prod)
- [ ] Blue-green deployment strategy
- [ ] Automated database migrations
- [ ] Performance regression testing
- [ ] Integration with monitoring tools
- [ ] Automated security updates

---

## 📞 Quick Reference

```bash
# Start development
npm run dev                 # Frontend
./mvnw spring-boot:run     # Backend

# Run tests
npm run test               # Frontend
./mvnw test               # Backend

# Build for production
npm run build             # Frontend
./mvnw package           # Backend

# Deploy manually
./deploy.sh              # Full deployment

# Check status
./scripts/check-swagger.sh   # Swagger check
docker compose ps           # Container status
```

**🎉 Happy Coding with Automated CI/CD! 🚀**