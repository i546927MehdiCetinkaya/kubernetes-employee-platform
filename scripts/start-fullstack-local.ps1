# Start Full HR Portal Stack (Frontend + Backend)
# Starts both frontend and backend for local development
# This script opens two PowerShell windows

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  HR PORTAL - FULL STACK STARTUP" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if backend script exists
$backendScript = Join-Path $scriptDir "start-backend.ps1"
$frontendScript = Join-Path $scriptDir "start-frontend.ps1"

if (-not (Test-Path $backendScript)) {
    Write-Host "[ERROR] Backend script not found: $backendScript" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $frontendScript)) {
    Write-Host "[ERROR] Frontend script not found: $frontendScript" -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Starting Backend (Mock Server)..." -ForegroundColor Yellow
Write-Host "      Opening new window for backend..." -ForegroundColor Gray

# Start backend in new PowerShell window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$backendScript'"

Write-Host "      [OK] Backend window opened" -ForegroundColor Green

# Wait for backend to start
Write-Host "`n[2/3] Waiting for backend to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$backendReady = $false

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "      Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3001/health" -TimeoutSec 2 -ErrorAction Stop
        Write-Host "      [OK] Backend is ready!" -ForegroundColor Green
        $backendReady = $true
        break
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $backendReady) {
    Write-Host "`n[WARNING] Backend didn't respond within 30 seconds" -ForegroundColor Yellow
    Write-Host "          Continuing anyway..." -ForegroundColor Yellow
}

Write-Host "`n[3/3] Starting Frontend..." -ForegroundColor Yellow
Write-Host "      Opening new window for frontend..." -ForegroundColor Gray

# Start frontend in new PowerShell window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$frontendScript'"

Write-Host "      [OK] Frontend window opened" -ForegroundColor Green

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  STARTUP COMPLETE!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
Write-Host "  Backend:  http://localhost:3001" -ForegroundColor White
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "The browser should open automatically to:" -ForegroundColor Gray
Write-Host "  http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "To stop the servers:" -ForegroundColor Cyan
Write-Host "  - Press Ctrl+C in each PowerShell window" -ForegroundColor White
Write-Host "  - Or close the PowerShell windows" -ForegroundColor White
Write-Host ""
Write-Host "Happy coding! 🚀" -ForegroundColor Green
Write-Host ""
