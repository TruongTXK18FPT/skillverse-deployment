# 🚀 SkillVerse PowerShell Deployment Script with SSL Support
# Usage: .\deploy.ps1 [-SSL] [-Staging] [-Help]

param(
    [switch]$SSL,
    [switch]$Staging,
    [switch]$Help
)

Write-Host "🚀 Starting SkillVerse deployment..." -ForegroundColor Cyan

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Status "Docker is running."
} catch {
    Write-Error-Custom "Docker is not running. Please start Docker Desktop first."
    exit 1
}

# Check if Docker Compose is available
try {
    docker compose version | Out-Null
    Write-Status "Docker Compose is available."
} catch {
    Write-Error-Custom "Docker Compose is not available. Please install Docker Compose."
    exit 1
}

# Stop and remove existing containers
Write-Status "Stopping existing containers..."
docker compose down -v --remove-orphans

# Clean up old images (optional)
Write-Warning-Custom "Cleaning up old images..."
docker image prune -f

# Build images
Write-Status "Building Docker images..."
docker compose build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to build Docker images."
    exit 1
}

Write-Status "Docker images built successfully."

# Start services
Write-Status "Starting services..."
docker compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to start services."
    exit 1
}

Write-Status "Services started successfully."

# Wait for services to be healthy
Write-Status "Waiting for services to be healthy..."
Start-Sleep -Seconds 30

# Check container status
Write-Status "Checking container status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test endpoints
Write-Status "Testing endpoints..."

# Get the local IP address
try {
    $IP = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne "Disconnected" }).IPv4Address.IPAddress | Select-Object -First 1
    if (-not $IP) {
        $IP = "localhost"
    }
} catch {
    $IP = "localhost"
}

Write-Status "Testing frontend at http://$IP"
try {
    $response = Invoke-WebRequest -Uri "http://$IP/" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Status "✅ Frontend is accessible at http://$IP"
    }
} catch {
    Write-Error-Custom "❌ Frontend is not accessible"
}

Write-Status "Testing backend API at http://$IP/api"
try {
    $response = Invoke-WebRequest -Uri "http://$IP/api/actuator/health" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Status "✅ Backend API is accessible at http://$IP/api"
    }
} catch {
    Write-Error-Custom "❌ Backend API is not accessible"
}

# Show logs for debugging
Write-Status "Recent logs from services:"
docker compose logs --tail=10

Write-Status "🎉 Deployment completed!" 
Write-Status "Access your application:"
Write-Status "  - Frontend: http://$IP"
Write-Status "  - Backend API: http://$IP/api"
Write-Status "  - Backend Direct: http://$IP:8080"
Write-Status ""
Write-Status "To view logs: docker compose logs -f [service_name]"
Write-Status "To stop services: docker compose down"
Write-Status "To restart services: docker compose restart"