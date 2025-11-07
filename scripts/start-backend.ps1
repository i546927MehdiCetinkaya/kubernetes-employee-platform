# Quick Backend Start Script
# Starts MOCK backend server on port 3001
# No AWS credentials needed!

Write-Host "`n=== STARTING MOCK BACKEND ON PORT 3001 ===" -ForegroundColor Cyan

$backendPath = "applications\hr-portal\backend"

if (-not (Test-Path $backendPath)) {
    Write-Host "[ERROR] Backend directory not found!" -ForegroundColor Red
    exit 1
}

Set-Location $backendPath

Write-Host "[1/2] Checking dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "      Installing dependencies..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ERROR] Failed to install dependencies!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      [OK] Dependencies installed" -ForegroundColor Green
}

Write-Host "`n[2/2] Starting MOCK backend server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Mock Backend API: http://localhost:3001" -ForegroundColor Green
Write-Host "Endpoints:" -ForegroundColor Cyan
Write-Host "  - GET  /health" -ForegroundColor White
Write-Host "  - GET  /api/employees" -ForegroundColor White
Write-Host "  - GET  /api/employees/:id" -ForegroundColor White
Write-Host "  - POST /api/employees" -ForegroundColor White
Write-Host "  - PUT  /api/employees/:id" -ForegroundColor White
Write-Host "  - DELETE /api/employees/:id" -ForegroundColor White
Write-Host ""
Write-Host "This is a MOCK server - no AWS needed!" -ForegroundColor Green
Write-Host "Initial data: 2 test employees loaded" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Cyan

npm run mock
