# SkillVerse HTTP Proxy for Local Development
$ContainerName = "skillverse-http-proxy"
$NetworkName = "skillverse-network"

Write-Host "Setting up HTTP Proxy for Local SkillVerse Development..." -ForegroundColor Green

# Check Docker
try {
    docker info | Out-Null
    Write-Host "Docker is running." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    exit 1
}

# Clean up existing containers
Write-Host "Cleaning up existing containers..." -ForegroundColor Cyan
@("skillverse-ssl-proxy", $ContainerName) | ForEach-Object {
    docker stop $_ 2>$null | Out-Null
    docker rm $_ 2>$null | Out-Null
}

# Create network
$networkExists = docker network ls --filter name=$NetworkName -q
if (-not $networkExists) {
    docker network create --driver bridge $NetworkName | Out-Null
    Write-Host "Network created: $NetworkName" -ForegroundColor Green
} else {
    Write-Host "Network exists: $NetworkName" -ForegroundColor Green
}

# Get nginx config path
$configPath = "..\nginx\nginx-http-dev.conf"
$fullPath = Resolve-Path $configPath -ErrorAction SilentlyContinue
if (-not $fullPath) {
    Write-Host "ERROR: Config not found: $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "Using config: $fullPath" -ForegroundColor Cyan

# Start container (HTTP only - no SSL port)
Write-Host "Starting HTTP Proxy container..." -ForegroundColor Cyan
$containerId = docker run -d --name $ContainerName --restart unless-stopped -p 80:80 -v "${fullPath}:/etc/nginx/nginx.conf:ro" --network $NetworkName nginx:alpine

if ($LASTEXITCODE -eq 0) {
    Write-Host "Container started: $containerId" -ForegroundColor Green
    
    Start-Sleep 3
    
    # Check status
    $running = docker ps --filter name=$ContainerName -q
    if ($running) {
        Write-Host "SUCCESS: HTTP Proxy is running!" -ForegroundColor Green
        docker ps --filter name=$ContainerName
        
        Write-Host "`nTest nginx config..." -ForegroundColor Cyan
        docker exec $ContainerName nginx -t
        
        Write-Host "`nRecent logs:" -ForegroundColor Cyan
        docker logs $ContainerName --tail 5
        
        Write-Host "`nTesting URLs:" -ForegroundColor Yellow
        Write-Host "  http://localhost" -ForegroundColor White
        Write-Host "  http://localhost/health" -ForegroundColor White
        Write-Host "  http://localhost/api/health (if backend running)" -ForegroundColor White
        
        # Test the service
        Write-Host "`nTesting HTTP service..." -ForegroundColor Cyan
        try {
            $response = Invoke-WebRequest -Uri "http://localhost/health" -Method Get -TimeoutSec 5
            Write-Host "✅ Service is responding: $($response.StatusCode)" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Service test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "ERROR: Container not running!" -ForegroundColor Red
        docker logs $ContainerName --tail 10
    }
} else {
    Write-Host "ERROR: Failed to start container!" -ForegroundColor Red
}