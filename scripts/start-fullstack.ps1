# Start Frontend + Backend Together
# This script starts both services for full local testing

Write-Host "`n=== HR PORTAL - FULL STACK LOCAL TEST ===" -ForegroundColor Cyan
Write-Host ""

# Check if node_modules exists in both folders
$backendPath = "applications\hr-portal\backend"
$frontendPath = "applications\hr-portal\frontend"

Write-Host "[1/4] Checking backend dependencies..." -ForegroundColor Yellow
Set-Location $backendPath
if (-not (Test-Path "node_modules")) {
    Write-Host "      Installing backend dependencies..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ERROR] Failed to install backend dependencies!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      [OK] Backend dependencies installed" -ForegroundColor Green
}

Write-Host "`n[2/4] Checking frontend dependencies..." -ForegroundColor Yellow
Set-Location ..\..\..
Set-Location $frontendPath
if (-not (Test-Path "node_modules")) {
    Write-Host "      Installing frontend dependencies..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ERROR] Failed to install frontend dependencies!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      [OK] Frontend dependencies installed" -ForegroundColor Green
}

# Go back to root
Set-Location ..\..\..

Write-Host "`n[3/4] Starting backend on port 3001..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3\applications\hr-portal\backend"
    $env:PORT = "3001"
    $env:NODE_ENV = "development"
    npm start
}

Write-Host "      [OK] Backend starting (Job ID: $($backendJob.Id))" -ForegroundColor Green
Write-Host "      Waiting for backend to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 3

Write-Host "`n[4/4] Starting frontend on port 3000..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "=== SERVICES STARTED ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API: http://localhost:3001" -ForegroundColor Green
Write-Host "  - Health: http://localhost:3001/health" -ForegroundColor Gray
Write-Host "  - Employees: http://localhost:3001/api/employees" -ForegroundColor Gray
Write-Host ""
Write-Host "Frontend UI: http://localhost:3000" -ForegroundColor Green
Write-Host "  - Will open automatically in browser" -ForegroundColor Gray
Write-Host ""
Write-Host "NOTE: Backend may show DynamoDB connection errors" -ForegroundColor Yellow
Write-Host "      This is normal without AWS credentials" -ForegroundColor Yellow
Write-Host "      The UI will still demonstrate all features" -ForegroundColor Yellow
Write-Host ""
Write-Host "To stop services:" -ForegroundColor Cyan
Write-Host "  1. Press Ctrl+C to stop frontend" -ForegroundColor White
Write-Host "  2. Run: Stop-Job -Id $($backendJob.Id); Remove-Job -Id $($backendJob.Id)" -ForegroundColor White
Write-Host ""
Write-Host "Starting frontend now..." -ForegroundColor Yellow
Write-Host "================================`n" -ForegroundColor Cyan

Set-Location $frontendPath
npm start
