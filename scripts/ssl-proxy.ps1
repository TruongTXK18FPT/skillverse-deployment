# SkillVerse SSL Proxy - Quick Setup
$ContainerName = "skillverse-ssl-proxy"
$NetworkName = "skillverse-network"
$DomainName = "skillverse.vn"

Write-Host "Setting up SSL Proxy for SkillVerse..." -ForegroundColor Green

# Check Docker
Write-Host "Checking Docker..." -ForegroundColor Cyan
try {
    docker info | Out-Null
    Write-Host "Docker is running." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    exit 1
}

# Clean up existing container
Write-Host "Cleaning up existing container..." -ForegroundColor Cyan
docker stop $ContainerName 2>$null | Out-Null
docker rm $ContainerName 2>$null | Out-Null

# Create network
Write-Host "Setting up network..." -ForegroundColor Cyan
$networkExists = docker network ls --filter name=$NetworkName -q
if (-not $networkExists) {
    docker network create --driver bridge $NetworkName | Out-Null
    Write-Host "Network created: $NetworkName" -ForegroundColor Green
} else {
    Write-Host "Network exists: $NetworkName" -ForegroundColor Green
}

# Get nginx config path
$configPath = "..\nginx\nginx-ssl-simple.conf"
$fullPath = Resolve-Path $configPath -ErrorAction SilentlyContinue
if (-not $fullPath) {
    Write-Host "ERROR: Config not found: $configPath" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using config: $fullPath" -ForegroundColor Cyan

# Start container
Write-Host "Starting SSL Proxy container..." -ForegroundColor Cyan
$containerId = docker run -d --name $ContainerName --restart unless-stopped -p 80:80 -p 443:443 -v "/etc/letsencrypt:/etc/letsencrypt:ro" -v "${fullPath}:/etc/nginx/nginx.conf:ro" --network $NetworkName nginx:alpine

if ($LASTEXITCODE -eq 0) {
    Write-Host "Container started: $containerId" -ForegroundColor Green
    
    Start-Sleep 3
    
    # Check status
    $running = docker ps --filter name=$ContainerName -q
    if ($running) {
        Write-Host "SUCCESS: SSL Proxy is running!" -ForegroundColor Green
        docker ps --filter name=$ContainerName
        
        Write-Host "`nTest nginx config..." -ForegroundColor Cyan
        docker exec $ContainerName nginx -t
        
        Write-Host "`nRecent logs:" -ForegroundColor Cyan
        docker logs $ContainerName --tail 5
        
        Write-Host "`nTesting URLs:" -ForegroundColor Yellow
        Write-Host "curl -I https://$DomainName" -ForegroundColor White
        Write-Host "curl -I http://$DomainName" -ForegroundColor White
        
    } else {
        Write-Host "ERROR: Container not running!" -ForegroundColor Red
        docker logs $ContainerName --tail 10
    }
} else {
    Write-Host "ERROR: Failed to start container!" -ForegroundColor Red
}