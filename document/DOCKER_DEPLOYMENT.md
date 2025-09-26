# SkillVerse Docker Deployment Guide

## Overview
This guide provides instructions for deploying the SkillVerse application using Docker containers.

### Architecture
- **Frontend**: React + TypeScript + Vite served by Nginx
- **Backend**: Spring Boot application (Java 17)
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Reverse Proxy**: Nginx (built into frontend container)

## Prerequisites
- Docker Desktop or Docker Engine (20.10+)
- Docker Compose (2.0+)
- 4GB+ RAM available
- 10GB+ disk space

## Quick Start

### 1. Clone and Navigate
```bash
cd c:\WorkSpace\EXE201
```

### 2. Build and Deploy (Windows PowerShell)
```powershell
# Make script executable and run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\deploy.ps1
```

### 3. Build and Deploy (Linux/Mac)
```bash
# Make script executable and run
chmod +x deploy.sh
./deploy.sh
```

### 4. Manual Deployment
```bash
# Stop existing containers
docker compose down -v

# Build images
docker compose build --no-cache

# Start services
docker compose up -d

# Check status
docker ps
```

## Services and Ports

| Service | Container Name | External Port | Internal Port | Description |
|---------|----------------|---------------|---------------|-------------|
| Frontend | skillverse-frontend | 80 | 80 | React app via Nginx |
| Backend | skillverse-backend | 8080 | 8080 | Spring Boot API |
| Database | skillverse-db | 5432 | 5432 | PostgreSQL |
| Redis | skillverse-redis | 6379 | 6379 | Redis Cache |

## Access URLs
- **Frontend**: http://localhost or http://YOUR_IP
- **Backend API**: http://localhost/api or http://YOUR_IP/api
- **Backend Direct**: http://localhost:8080 or http://YOUR_IP:8080
- **Database**: localhost:5432 (for external tools)

## Configuration

### Environment Variables
The application uses the following default configurations:

#### Database
- **Database**: skillverse_db
- **Username**: skillverse_user
- **Password**: secret_password
- **Host**: db (internal network)

#### Redis
- **Host**: redis (internal network)
- **Port**: 6379
- **Password**: secret_password

### Custom Configuration
To modify configurations, edit the `docker-compose.yml` file:

```yaml
# Example: Change database password
environment:
  - SPRING_DATASOURCE_PASSWORD=your_new_password
```

## Development Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app
docker compose logs -f frontend
docker compose logs -f db
docker compose logs -f redis
```

### Restart Services
```bash
# All services
docker compose restart

# Specific service
docker compose restart app
```

### Update Application
```bash
# Rebuild and restart
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Database Management
```bash
# Connect to database
docker exec -it skillverse-db psql -U skillverse_user -d skillverse_db

# Backup database
docker exec skillverse-db pg_dump -U skillverse_user skillverse_db > backup.sql

# Restore database
docker exec -i skillverse-db psql -U skillverse_user -d skillverse_db < backup.sql
```

## Health Checks
All services include health checks:

```bash
# Check service health
docker compose ps

# Manual health check
curl http://localhost/health          # Frontend
curl http://localhost/api/actuator/health  # Backend
```

## Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Find process using port
netstat -ano | findstr :80
netstat -ano | findstr :8080

# Kill process (Windows)
taskkill /PID <PID> /F
```

#### 2. Database Connection Issues
```bash
# Check database logs
docker compose logs db

# Verify database is running
docker exec skillverse-db pg_isready -U skillverse_user
```

#### 3. Frontend Build Issues
```bash
# Check frontend build logs
docker compose logs frontend

# Rebuild frontend only
docker compose build --no-cache frontend
docker compose up -d frontend
```

#### 4. Memory Issues
```bash
# Check container resource usage
docker stats

# Increase Docker memory limit in Docker Desktop settings
```

### Debugging
```bash
# Enter container shell
docker exec -it skillverse-backend /bin/sh
docker exec -it skillverse-frontend /bin/sh

# Check container files
docker exec skillverse-frontend ls -la /usr/share/nginx/html
docker exec skillverse-backend ls -la /app
```

## Production Considerations

### Security
1. Change default passwords in `docker-compose.yml`
2. Use Docker secrets for sensitive data
3. Enable SSL/TLS with proper certificates
4. Configure firewall rules
5. Regular security updates

### Performance
1. Increase container resource limits
2. Configure database connection pooling
3. Enable Redis clustering for high availability
4. Use CDN for static assets
5. Implement database backups

### Monitoring
1. Set up container monitoring (Prometheus + Grafana)
2. Configure log aggregation (ELK Stack)
3. Health check endpoints
4. Database performance monitoring

## Cleanup
```bash
# Stop and remove containers
docker compose down

# Remove volumes (WARNING: deletes data)
docker compose down -v

# Remove images
docker rmi skillverse-frontend skillverse-backend

# Complete cleanup
docker system prune -a --volumes
```

## Support
For issues and questions:
1. Check container logs first
2. Verify all services are healthy
3. Check network connectivity
4. Review this documentation