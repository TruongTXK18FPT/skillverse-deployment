#!/bin/bash

# 🚀 SkillVerse Multi-Repository Setup Script for Ubuntu
# This script sets up SkillVerse with separate backend and frontend repositories

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WORKSPACE_DIR="skillverse-workspace"
BACKEND_REPO="https://github.com/TruongTXK18FPT/SkillVerse_BackEnd.git"
FRONTEND_REPO="https://github.com/TruongTXK18FPT/skillverse-prototype.git"
DEPLOYMENT_REPO="https://github.com/TruongTXK18FPT/skillverse-deployment.git"

echo -e "${BLUE}🚀 SkillVerse Multi-Repository Setup${NC}"
echo -e "${BLUE}=====================================${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please don't run this script as root${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo apt update -qq

# Install required packages
echo -e "${YELLOW}🔧 Installing required packages...${NC}"
sudo apt install -y git curl wget unzip build-essential

# Install Docker if not exists
if ! command_exists docker; then
    echo -e "${YELLOW}🐳 Installing Docker...${NC}"
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ Docker installed. Please logout and login again.${NC}"
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

# Install Docker Compose if not exists
if ! command_exists "docker compose"; then
    echo -e "${YELLOW}🔧 Installing Docker Compose...${NC}"
    sudo apt install -y docker-compose-plugin
else
    echo -e "${GREEN}✅ Docker Compose already installed${NC}"
fi

# Create workspace directory
echo -e "${YELLOW}📁 Creating workspace directory...${NC}"
if [ -d "$WORKSPACE_DIR" ]; then
    echo -e "${YELLOW}⚠️  Workspace directory already exists${NC}"
    read -p "Do you want to remove it and start fresh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$WORKSPACE_DIR"
        echo -e "${GREEN}✅ Old workspace removed${NC}"
    else
        echo -e "${BLUE}📂 Using existing workspace${NC}"
    fi
fi

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Clone repositories
echo -e "${YELLOW}📥 Cloning repositories...${NC}"

# Clone backend
if [ ! -d "backend" ]; then
    echo -e "${BLUE}   Cloning backend repository...${NC}"
    git clone "$BACKEND_REPO" backend
    echo -e "${GREEN}   ✅ Backend repository cloned${NC}"
else
    echo -e "${BLUE}   📂 Backend repository already exists${NC}"
fi

# Clone frontend
if [ ! -d "frontend" ]; then
    echo -e "${BLUE}   Cloning frontend repository...${NC}"
    git clone "$FRONTEND_REPO" frontend
    echo -e "${GREEN}   ✅ Frontend repository cloned${NC}"
else
    echo -e "${BLUE}   📂 Frontend repository already exists${NC}"
fi

# Clone deployment repo if URL provided
if [ -n "$DEPLOYMENT_REPO" ]; then
    if [ ! -d "deployment" ]; then
        echo -e "${BLUE}   Cloning deployment repository...${NC}"
        git clone "$DEPLOYMENT_REPO" deployment
        echo -e "${GREEN}   ✅ Deployment repository cloned${NC}"
    else
        echo -e "${BLUE}   📂 Deployment repository already exists${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  No deployment repository URL provided${NC}"
    echo -e "${BLUE}   📂 Creating deployment directory...${NC}"
    mkdir -p deployment
fi

# Create deployment files structure
echo -e "${YELLOW}📂 Setting up deployment structure...${NC}"
cd deployment

# Create directories
mkdir -p docker nginx scripts .github/workflows docs

# Create docker-compose.yml that references the other repos
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
      test: ["CMD-SHELL", "pg_isready -U ${DOCKER_DB_USER:-skillverse_user} -d ${DOCKER_DB_NAME:-skillverse_db}"]
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
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:${DB_PORT:-5432}/${DOCKER_DB_NAME:-skillverse_db}
      - SPRING_DATASOURCE_USERNAME=${DOCKER_DB_USER:-skillverse_user}
      - SPRING_DATASOURCE_PASSWORD=${DOCKER_DB_PASSWORD:-secret_password}
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
      - SPRING_JPA_SHOW_SQL=false
      - SPRING_REDIS_HOST=${REDIS_HOST:-redis}
      - SPRING_REDIS_PORT=${REDIS_PORT:-6379}
      - SPRING_REDIS_PASSWORD=${REDIS_PASSWORD:-secret_password}
      - SERVER_PORT=8080
      - JWT_SECRET=${JWT_SECRET}
      - SPRING_MAIL_HOST=${SMTP_HOST}
      - SPRING_MAIL_PORT=${SMTP_PORT}
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
    volumes:
      - ../nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - /var/www/certbot:/var/www/certbot:ro

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

# Copy deployment files from parent directory if they exist
echo -e "${YELLOW}📋 Copying deployment files...${NC}"
cd ..

# List of files to copy to deployment repo
DEPLOYMENT_FILES=(
    "deploy.sh:scripts/"
    "deploy.ps1:scripts/"
    "setup-ssl.sh:scripts/"
    "nginx-ssl.conf:nginx/"
    "DEPLOYMENT_GUIDE.md:docs/"
    ".env.example:."
    ".github/workflows/deploy.yml:.github/workflows/"
)

for file_mapping in "${DEPLOYMENT_FILES[@]}"; do
    IFS=':' read -r src_file dest_dir <<< "$file_mapping"
    if [ -f "$src_file" ]; then
        mkdir -p "deployment/$dest_dir"
        cp "$src_file" "deployment/$dest_dir"
        echo -e "${GREEN}   ✅ Copied $src_file to deployment/$dest_dir${NC}"
    else
        echo -e "${YELLOW}   ⚠️  File $src_file not found${NC}"
    fi
done

# Create .env file
echo -e "${YELLOW}⚙️  Creating environment file...${NC}"
if [ ! -f "deployment/.env" ]; then
    if [ -f "deployment/.env.example" ]; then
        cp "deployment/.env.example" "deployment/.env"
        echo -e "${GREEN}✅ Environment file created from example${NC}"
    else
        cat > deployment/.env << 'EOF'
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
        echo -e "${GREEN}✅ Default environment file created${NC}"
    fi
else
    echo -e "${BLUE}📂 Environment file already exists${NC}"
fi

# Make scripts executable
echo -e "${YELLOW}🔧 Making scripts executable...${NC}"
find deployment/scripts -name "*.sh" -type f -exec chmod +x {} \;

# Create main deployment script
cat > deploy-all.sh << 'EOF'
#!/bin/bash

# Main deployment script for SkillVerse multi-repo setup
set -e

echo "🚀 SkillVerse Multi-Repository Deployment"
echo "========================================="

# Check if we're in the right directory
if [ ! -d "deployment" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ Error: Please run this script from the skillverse-workspace directory"
    echo "Expected structure:"
    echo "  skillverse-workspace/"
    echo "  ├── backend/"
    echo "  ├── frontend/"
    echo "  └── deployment/"
    exit 1
fi

# Change to deployment directory
cd deployment

# Check if docker-compose file exists
if [ ! -f "docker/docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found in deployment/docker/"
    exit 1
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Environment variables loaded"
else
    echo "⚠️  Warning: .env file not found, using defaults"
fi

# Run deployment
echo "🚀 Starting deployment..."
cd docker
docker compose down --remove-orphans
docker compose build --no-cache
docker compose up -d

# Wait for services
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check health
echo "🏥 Checking service health..."
docker compose ps

echo "✅ Deployment completed!"
echo ""
echo "🌐 Application URLs:"
echo "  Frontend: http://localhost"
echo "  Backend API: http://localhost/api"
echo "  Backend Direct: http://localhost:8080"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker compose logs -f"
echo "  Stop services: docker compose down"
echo "  Restart: docker compose restart"
EOF

chmod +x deploy-all.sh

# Display final information
echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo -e "${BLUE}📊 Project Structure:${NC}"
echo -e "${YELLOW}$(pwd)/${NC}"
echo -e "${BLUE}├── backend/           ${NC}# SkillVerse Backend Repository"
echo -e "${BLUE}├── frontend/          ${NC}# SkillVerse Frontend Repository"
echo -e "${BLUE}├── deployment/        ${NC}# Deployment Configuration"
echo -e "${BLUE}│   ├── docker/        ${NC}# Docker Compose files"
echo -e "${BLUE}│   ├── nginx/         ${NC}# Nginx configurations"
echo -e "${BLUE}│   ├── scripts/       ${NC}# Deployment scripts"
echo -e "${BLUE}│   └── .env           ${NC}# Environment variables"
echo -e "${BLUE}└── deploy-all.sh      ${NC}# Main deployment script"
echo ""
echo -e "${GREEN}🚀 Next Steps:${NC}"
echo -e "${YELLOW}1. Edit deployment/.env with your configuration${NC}"
echo -e "${YELLOW}2. Run: ./deploy-all.sh${NC}"
echo -e "${YELLOW}3. Access: http://localhost${NC}"
echo ""
echo -e "${BLUE}📖 For SSL setup, run: deployment/scripts/setup-ssl.sh your-domain.com${NC}"

# Check if user needs to logout for Docker group
if ! groups | grep -q docker; then
    echo -e "${RED}⚠️  Important: Please logout and login again for Docker group changes to take effect${NC}"
fi