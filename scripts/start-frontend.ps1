# Start HR Portal Frontend in Browser
# Quick script to launch the frontend for testing

Write-Host "`n=== HR PORTAL FRONTEND - BROWSER TEST ===" -ForegroundColor Cyan
Write-Host ""

# Navigate to frontend directory
$frontendPath = "applications\hr-portal\frontend"

if (-not (Test-Path $frontendPath)) {
    Write-Host "[ERROR] Frontend directory not found!" -ForegroundColor Red
    Write-Host "Expected: $frontendPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/3] Navigating to frontend directory..." -ForegroundColor Yellow
Set-Location $frontendPath
Write-Host "      Current location: $(Get-Location)" -ForegroundColor Gray

# Check if node_modules exists
Write-Host "`n[2/3] Checking dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "      Installing dependencies (this may take a few minutes)..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ERROR] Failed to install dependencies!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      [OK] Dependencies already installed" -ForegroundColor Green
}

# Start the development server
Write-Host "`n[3/3] Starting React development server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=== FRONTEND INFORMATION ===" -ForegroundColor Cyan
Write-Host "URL: http://localhost:3000" -ForegroundColor Green
Write-Host "Browser will open automatically" -ForegroundColor Gray
Write-Host ""
Write-Host "Features available:" -ForegroundColor Cyan
Write-Host "  - View employee list" -ForegroundColor White
Write-Host "  - Create new employee" -ForegroundColor White
Write-Host "  - Delete employee (with confirmation)" -ForegroundColor White
Write-Host "  - Role badges (developer, manager, hr, admin)" -ForegroundColor White
Write-Host "  - Status indicators" -ForegroundColor White
Write-Host "  - Material-UI design" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: Backend API is expected at http://localhost:3001" -ForegroundColor Yellow
Write-Host "      If backend is not running, API calls will fail" -ForegroundColor Yellow
Write-Host "      Start backend first: .\scripts\start-backend.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Cyan
Write-Host "=================================`n" -ForegroundColor Cyan

# Start the server
npm start
