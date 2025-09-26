# 🐧 Ubuntu Setup Guide cho SkillVerse Multi-Repository

## 📋 Tổng quan

SkillVerse sử dụng 3 repositories riêng biệt:
- **Backend**: `TruongTXK18FPT/SkillVerse_Backend`
- **Frontend**: `Sendudu2311/skillverse-prototype`  
- **Deployment**: `your-username/skillverse-deployment` (tùy chọn)

## 🚀 Setup nhanh trên Ubuntu

### Option 1: Sử dụng script tự động (Khuyến nghị)

```bash
# Tải và chạy script setup
wget https://raw.githubusercontent.com/your-repo/setup-multi-repo.sh
chmod +x setup-multi-repo.sh
./setup-multi-repo.sh
```

### Option 2: Setup thủ công

#### Bước 1: Cài đặt dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Cài đặt packages cần thiết
sudo apt install -y git curl wget unzip build-essential

# Cài đặt Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Cài đặt Docker Compose
sudo apt install -y docker-compose-plugin

# Logout và login lại để áp dụng Docker group
exit
```

#### Bước 2: Clone repositories

```bash
# Tạo workspace
mkdir skillverse-workspace && cd skillverse-workspace

# Clone backend
git clone https://github.com/TruongTXK18FPT/SkillVerse_Backend.git backend

# Clone frontend  
git clone https://github.com/Sendudu2311/skillverse-prototype.git frontend

# Tạo deployment directory
mkdir deployment && cd deployment
```

#### Bước 3: Setup deployment files

```bash
# Tạo cấu trúc thư mục
mkdir -p docker nginx scripts .github/workflows docs

# Tạo docker-compose.yml
cat > docker/docker-compose.yml << 'EOF'
services:
  # PostgreSQL Database
  db:
    image: postgres:17-alpine
    container_name: skillverse-db
    environment:
      POSTGRES_DB: ${DOCKER_DB_NAME:-skillverse_db}
      POSTGRES_USER: ${DOCKER_DB_USER:-skillverse_user}
      POSTGRES_PASSWORD: ${DOCKER_DB_PASSWORD:-secret_password}
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:5432:5432"
    networks:
      - skillverse-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U skillverse_user -d skillverse_db"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: skillverse-redis
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-secret_password}
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"
    networks:
      - skillverse-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Spring Boot Backend
  app:
    build:
      context: ../../backend
      dockerfile: Dockerfile
    container_name: skillverse-backend
    environment:
      - SPRING_PROFILES_ACTIVE=docker
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/${DOCKER_DB_NAME:-skillverse_db}
      - SPRING_DATASOURCE_USERNAME=${DOCKER_DB_USER:-skillverse_user}
      - SPRING_DATASOURCE_PASSWORD=${DOCKER_DB_PASSWORD:-secret_password}
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
      - SPRING_REDIS_HOST=redis
      - SPRING_REDIS_PORT=6379
      - SPRING_REDIS_PASSWORD=${REDIS_PASSWORD:-secret_password}
      - JWT_SECRET=${JWT_SECRET}
      - SPRING_MAIL_HOST=${SMTP_HOST}
      - SPRING_MAIL_USERNAME=${SMTP_USERNAME}
      - SPRING_MAIL_PASSWORD=${SMTP_PASSWORD}
    ports:
      - "127.0.0.1:8080:8080"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - skillverse-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # React Frontend with Nginx
  frontend:
    build:
      context: ../../frontend
      dockerfile: Dockerfile
    container_name: skillverse-frontend
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      app:
        condition: service_healthy
    networks:
      - skillverse-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  skillverse-network:
    driver: bridge
    name: skillverse-network

volumes:
  postgres_data:
    driver: local
    name: skillverse-postgres-data
  redis_data:
    driver: local
    name: skillverse-redis-data
EOF
```

#### Bước 4: Tạo file môi trường

```bash
# Tạo .env file
cat > .env << 'EOF'
# === Application Version ===
VERSION=latest

# === Database Configuration ===
DB_PASSWORD=12345
DB_HOST=localhost
DB_PORT=5432
DB_NAME=SkillVerseDB
DB_USER=postgres

# Docker Database Configuration
DOCKER_DB_PASSWORD=secret_password
DOCKER_DB_HOST=db
DOCKER_DB_NAME=skillverse_db
DOCKER_DB_USER=skillverse_user

# === Redis Configuration ===
REDIS_PASSWORD=secret_password
REDIS_HOST=redis
REDIS_PORT=6379

# === JWT Configuration ===
JWT_SECRET=1TjXchw5FloESb63Kc+DFhTARvpWL4jUGCwfGWxuG5SIf/1y/LgJxHnMqaF6A/ij
JWT_ACCESS_TOKEN_EXPIRATION=3600
JWT_REFRESH_TOKEN_EXPIRATION=86400

# === Email Configuration ===
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=skillverseexe@gmail.com
SMTP_PASSWORD=fgbx gygh iglz dcou
EMAIL_FROM=skillverseexe@gmail.com
EMAIL_FROM_NAME=SkillVerse

# === SSL Configuration ===
SSL_ENABLED=false
DOMAIN_NAME=localhost
SSL_EMAIL=admin@localhost
EOF
```

#### Bước 5: Tạo script deployment

```bash
# Quay về workspace root
cd ..

# Tạo main deployment script
cat > deploy-all.sh << 'EOF'
#!/bin/bash

# Main deployment script for SkillVerse multi-repo setup
set -e

echo "🚀 SkillVerse Multi-Repository Deployment"
echo "========================================="

# Check directory structure
if [ ! -d "deployment" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ Error: Please run this script from the skillverse-workspace directory"
    exit 1
fi

# Change to deployment directory
cd deployment

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Environment variables loaded"
fi

# Run deployment
echo "🚀 Starting deployment..."
cd docker
docker compose down --remove-orphans
docker compose build --no-cache
docker compose up -d

# Wait and check health
echo "⏳ Waiting for services..."
sleep 30

echo "🏥 Service status:"
docker compose ps

echo "✅ Deployment completed!"
echo ""
echo "🌐 URLs:"
echo "  Frontend: http://localhost"
echo "  API: http://localhost/api/health"
echo "  Backend: http://localhost:8080/api/health"
EOF

chmod +x deploy-all.sh
```

## 🚀 Deployment

```bash
# Từ skillverse-workspace directory
./deploy-all.sh
```

## 🔧 Cấu trúc thư mục sau khi setup

```
skillverse-workspace/
├── backend/              # SkillVerse_Backend repository
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── frontend/             # skillverse-prototype repository  
│   ├── src/
│   ├── package.json
│   ├── nginx.conf
│   └── Dockerfile
├── deployment/           # Deployment configuration
│   ├── docker/
│   │   └── docker-compose.yml
│   ├── nginx/
│   ├── scripts/
│   ├── .env
│   └── docs/
└── deploy-all.sh         # Main deployment script
```

## 🧪 Testing

```bash
# Health checks
curl http://localhost/health                    # Frontend
curl http://localhost/api/health               # API through proxy
curl http://localhost:8080/api/health          # Backend direct

# View logs
cd deployment/docker
docker compose logs -f

# Check containers
docker compose ps
```

## 🔒 SSL Setup (Production)

```bash
# Install certbot
sudo apt install -y certbot

# Get certificate (replace with your domain)
sudo certbot certonly --standalone -d your-domain.com

# Update nginx config for SSL
# Copy nginx-ssl.conf to deployment/nginx/
# Update .env with your domain

# Deploy with SSL
./deploy-all.sh
```

## 🛠️ Troubleshooting

### Docker permission denied
```bash
sudo usermod -aG docker $USER
exit  # Logout and login again
```

### Port conflicts
```bash
# Check what's using port 80
sudo netstat -tulpn | grep :80

# Stop conflicting services
sudo systemctl stop apache2  # or nginx
```

### Build failures
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
cd deployment/docker
docker compose build --no-cache
```

## 📚 Repository Management

### Pull latest changes
```bash
# Update all repositories
cd skillverse-workspace

# Update backend
cd backend && git pull origin main && cd ..

# Update frontend  
cd frontend && git pull origin main && cd ..

# Update deployment (if using deployment repo)
cd deployment && git pull origin main && cd ..

# Redeploy
./deploy-all.sh
```

### Switch branches
```bash
# Switch backend to specific branch
cd backend
git checkout feature-branch
cd ..

# Redeploy
./deploy-all.sh
```

## 🎯 Production Checklist

- [ ] Setup proper domain and SSL certificates
- [ ] Update environment variables in `.env`
- [ ] Configure firewall (UFW)
- [ ] Setup automated backups
- [ ] Configure monitoring
- [ ] Setup CI/CD pipeline
- [ ] Review security settings

---

**🎉 Happy Deployment!** 🚀