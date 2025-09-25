# SkillVerse SSL Proxy Setup Script (PowerShell)
# This script runs a standalone nginx SSL proxy for SkillVerse

param(
    [string]$DomainName = "skillverse.vn",
    [string]$ContainerName = "skillverse-ssl-proxy",
    [string]$NetworkName = "skillverse-network"
)

# Configuration
$NginxConfigPath = "..\nginx\nginx-ssl-simple.conf"
$SSLCertPath = "/etc/letsencrypt"

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Cyan"

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

Write-Host "🔧 Setting up SSL Proxy for SkillVerse..." -ForegroundColor $Blue

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Error "Docker is not running. Please start Docker Desktop first."
    exit 1
}

# Check if nginx config exists
$NginxConfigFullPath = Resolve-Path $NginxConfigPath -ErrorAction SilentlyContinue
if (-not $NginxConfigFullPath) {
    Write-Error "Nginx configuration not found: $NginxConfigPath"
    Write-Status "Current directory: $(Get-Location)"
    Write-Status "Looking for: $NginxConfigPath"
    exit 1
}

# Stop and remove existing container if it exists
$ExistingContainer = docker ps -a --format "table {{.Names}}" | Select-String "^$ContainerName$"
if ($ExistingContainer) {
    Write-Warning "Stopping existing container: $ContainerName"
    docker stop $ContainerName 2>$null
    docker rm $ContainerName 2>$null
}

# Create network if it doesn't exist
$ExistingNetwork = docker network ls --format "table {{.Name}}" | Select-String "^$NetworkName$"
if (-not $ExistingNetwork) {
    Write-Status "Creating network: $NetworkName"
    docker network create --driver bridge $NetworkName
} else {
    Write-Status "Network $NetworkName already exists"
}

Write-Status "Starting SSL Proxy container..."
Write-Status "Container name: $ContainerName"
Write-Status "Network: $NetworkName"
Write-Status "Nginx config: $NginxConfigFullPath"
Write-Status "SSL certificates: $SSLCertPath"

# Convert Windows path to Unix-style for Docker
$NginxConfigUnixPath = $NginxConfigFullPath.Path -replace '\\', '/' -replace '^([A-Z]):', '/$1'

# Run the SSL proxy container
$DockerCommand = @(
    "run", "-d",
    "--name", $ContainerName,
    "--restart", "unless-stopped",
    "-p", "80:80",
    "-p", "443:443",
    "-v", "$($SSLCertPath):/etc/letsencrypt:ro",
    "-v", "$($NginxConfigFullPath.Path):/etc/nginx/nginx.conf:ro",
    "--network", $NetworkName,
    "nginx:alpine"
)

try {
    $ContainerId = & docker @DockerCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Container started with ID: $ContainerId"
    } else {
        throw "Docker command failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Failed to start container: $_"
    exit 1
}

# Wait for container to start
Start-Sleep -Seconds 3

# Check if container is running
$RunningContainer = docker ps --format "table {{.Names}}" | Select-String "$ContainerName"
if ($RunningContainer) {
    Write-Success "SSL Proxy container started successfully!"
    Write-Status "Container status:"
    docker ps --filter name=$ContainerName --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Test nginx configuration
    Write-Status "Testing nginx configuration..."
    try {
        docker exec $ContainerName nginx -t
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Nginx configuration is valid!"
        } else {
            throw "Nginx configuration test failed"
        }
    } catch {
        Write-Error "Nginx configuration test failed!"
        Write-Status "Container logs:"
        docker logs $ContainerName --tail 20
        exit 1
    }
    
    # Show container logs
    Write-Status "Recent container logs:"
    docker logs $ContainerName --tail 10
    
    Write-Host ""
    Write-Success "SSL Proxy is ready!"
    Write-Status "You can now test HTTPS access:"
    Write-Host "  curl -I https://$DomainName" -ForegroundColor White
    Write-Host "  curl -I http://$DomainName (should redirect to HTTPS)" -ForegroundColor White
    Write-Host ""
    Write-Status "Management commands:"
    Write-Host "  View logs: docker logs -f $ContainerName" -ForegroundColor White
    Write-Host "  Stop: docker stop $ContainerName" -ForegroundColor White
    Write-Host "  Restart: docker restart $ContainerName" -ForegroundColor White
    
} else {
    Write-Error "Failed to start SSL Proxy container!"
    Write-Status "Container logs:"
    docker logs $ContainerName --tail 20
    exit 1
}