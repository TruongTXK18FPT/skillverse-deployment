# SkillVerse SSL Proxy Setup Script (PowerShell) - Simplified
param(
    [string]$DomainName = "skillverse.vn",
    [string]$ContainerName = "skillverse-ssl-proxy",
    [string]$NetworkName = "skillverse-network"
)

Write-Host "🔧 Setting up SSL Proxy for SkillVerse..." -ForegroundColor Cyan

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "[ERROR] Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Stop and remove existing container if it exists
Write-Host "[INFO] Checking for existing container..." -ForegroundColor Cyan
$ExistingContainer = docker ps -a -q --filter name=$ContainerName
if ($ExistingContainer) {
    Write-Host "[INFO] Stopping and removing existing container..." -ForegroundColor Yellow
    docker stop $ContainerName | Out-Null
    docker rm $ContainerName | Out-Null
}

# Create network if it doesn't exist
Write-Host "[INFO] Setting up Docker network..." -ForegroundColor Cyan
$ExistingNetwork = docker network ls -q --filter name=$NetworkName
if (-not $ExistingNetwork) {
    Write-Host "[INFO] Creating network: $NetworkName" -ForegroundColor Cyan
    docker network create --driver bridge $NetworkName | Out-Null
} else {
    Write-Host "[INFO] Network $NetworkName already exists" -ForegroundColor Cyan
}

# Get nginx config path
$NginxConfigPath = Resolve-Path "..\nginx\nginx-ssl-simple.conf" -ErrorAction SilentlyContinue
if (-not $NginxConfigPath) {
    Write-Host "[ERROR] Nginx config not found: ..\nginx\nginx-ssl-simple.conf" -ForegroundColor Red
    Write-Host "[INFO] Current directory: $(Get-Location)" -ForegroundColor Cyan
    exit 1
}

Write-Host "[INFO] Using nginx config: $($NginxConfigPath.Path)" -ForegroundColor Cyan

# Run the SSL proxy container
Write-Host "[INFO] Starting SSL Proxy container..." -ForegroundColor Cyan
$Result = docker run -d `
    --name $ContainerName `
    --restart unless-stopped `
    -p 80:80 `
    -p 443:443 `
    -v "/etc/letsencrypt:/etc/letsencrypt:ro" `
    -v "$($NginxConfigPath.Path):/etc/nginx/nginx.conf:ro" `
    --network $NetworkName `
    nginx:alpine

if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Container started with ID: $Result" -ForegroundColor Green
    
    # Wait for container to start
    Start-Sleep -Seconds 3
    
    # Check if container is running
    $RunningContainer = docker ps -q --filter name=$ContainerName
    if ($RunningContainer) {
        Write-Host "[SUCCESS] SSL Proxy is running!" -ForegroundColor Green
        
        # Show container status
        Write-Host "[INFO] Container status:" -ForegroundColor Cyan
        docker ps --filter name=$ContainerName --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Test nginx configuration
        Write-Host "[INFO] Testing nginx configuration..." -ForegroundColor Cyan
        $ConfigTest = docker exec $ContainerName nginx -t 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Nginx configuration is valid!" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Nginx configuration test failed:" -ForegroundColor Yellow
            Write-Host $ConfigTest -ForegroundColor Yellow
        }
        
        # Show recent logs
        Write-Host "[INFO] Recent container logs:" -ForegroundColor Cyan
        docker logs $ContainerName --tail 10
        
        Write-Host ""
        Write-Host "[SUCCESS] SSL Proxy is ready!" -ForegroundColor Green
        Write-Host "Test commands:" -ForegroundColor Cyan
        Write-Host "  curl -I https://$DomainName" -ForegroundColor White
        Write-Host "  curl -I http://$DomainName" -ForegroundColor White
        Write-Host ""
        Write-Host "Management:" -ForegroundColor Cyan
        Write-Host "  View logs: docker logs -f $ContainerName" -ForegroundColor White
        Write-Host "  Stop: docker stop $ContainerName" -ForegroundColor White
        Write-Host "  Restart: docker restart $ContainerName" -ForegroundColor White
        
    } else {
        Write-Host "[ERROR] Container failed to start properly!" -ForegroundColor Red
        Write-Host "[INFO] Container logs:" -ForegroundColor Cyan
        docker logs $ContainerName --tail 20
        exit 1
    }
} else {
    Write-Host "[ERROR] Failed to start container!" -ForegroundColor Red
    exit 1
}