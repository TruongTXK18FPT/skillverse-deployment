# 📦 SkillVerse Deployment Repository

Repo này chứa các file deployment và configuration cho SkillVerse system.

## 📁 Cấu trúc thư mục:

```
skillverse-deployment/
├── docker/
│   ├── docker-compose.yml           # Main compose file
│   ├── docker-compose.prod.yml      # Production compose
│   └── docker-compose.dev.yml       # Development compose
├── nginx/
│   ├── nginx.conf                   # HTTP configuration
│   └── nginx-ssl.conf               # HTTPS configuration
├── scripts/
│   ├── deploy.sh                    # Linux deployment script
│   ├── deploy.ps1                   # Windows deployment script
│   └── setup-ssl.sh                 # SSL setup script
├── .github/
│   └── workflows/
│       └── deploy.yml               # CI/CD pipeline
├── docs/
│   ├── DEPLOYMENT_GUIDE.md          # Deployment guide
│   └── DOCKER_DEPLOYMENT.md         # Docker guide
├── .env.example                     # Environment template
├── .gitignore
└── README.md
```

## 🚀 Quick Start:

1. **Clone repositories:**
```bash
# Create workspace
mkdir skillverse-workspace && cd skillverse-workspace

# Clone repositories
git clone https://github.com/TruongTXK18FPT/SkillVerse_Backend.git backend
git clone https://github.com/Sendudu2311/skillverse-prototype.git frontend  
git clone https://github.com/your-username/skillverse-deployment.git deployment

# Setup deployment
cd deployment
cp .env.example .env
# Edit .env with your values
```

2. **Deploy:**
```bash
cd deployment
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 📋 Repository Links:

- **Backend**: https://github.com/TruongTXK18FPT/SkillVerse_Backend
- **Frontend**: https://github.com/Sendudu2311/skillverse-prototype
- **Deployment**: https://github.com/your-username/skillverse-deployment