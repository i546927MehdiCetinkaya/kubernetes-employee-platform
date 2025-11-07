# Complete Local Testing Setup
# Starts mock backend + frontend for full UI testing

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   HR PORTAL - COMPLETE LOCAL SETUP        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Step 1: Stop any existing processes
Write-Host "[1/3] Cleaning up existing processes..." -ForegroundColor Yellow
Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*casestudy3*" } | ForEach-Object {
    Write-Host "      Stopping node process (PID: $($_.Id))..." -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
Write-Host "      OK - Cleanup complete" -ForegroundColor Green

# Step 2: Start Mock Backend
Write-Host "`n[2/3] Starting Mock Backend Server..." -ForegroundColor Yellow

$backendPath = "C:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3\applications\hr-portal\backend"

$backendScript = @"
Set-Location '$backendPath'
node mock-server.js
"@

$backendJob = Start-Job -ScriptBlock ([scriptblock]::Create($backendScript))

Write-Host "      OK - Mock Backend starting (Job ID: $($backendJob.Id))" -ForegroundColor Green
Write-Host "      URL: http://localhost:3001" -ForegroundColor Cyan
Write-Host "      Waiting for backend to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# Test backend
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "      OK - Backend is responding!" -ForegroundColor Green
} catch {
    Write-Host "      [WARNING] Backend not responding yet, continuing anyway..." -ForegroundColor Yellow
}

# Step 3: Start Frontend
Write-Host "`n[3/3] Starting Frontend..." -ForegroundColor Yellow

$frontendPath = "C:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3\applications\hr-portal\frontend"

Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           SERVICES STARTED                 ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🔧 Mock Backend:" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:3001" -ForegroundColor White
Write-Host "   Health: http://localhost:3001/health" -ForegroundColor Gray
Write-Host "   API: http://localhost:3001/api/employees" -ForegroundColor Gray
Write-Host "   Initial Data: 2 sample employees" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 Frontend:" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:3000" -ForegroundColor White
Write-Host "   Opening in browser..." -ForegroundColor Gray
Write-Host ""
Write-Host "✅ TESTING INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "   1. Browser will open automatically" -ForegroundColor White
Write-Host "   2. You should see 2 sample employees (John Doe, Jane Smith)" -ForegroundColor White
Write-Host "   3. Click 'ADD EMPLOYEE' to create new employee" -ForegroundColor White
Write-Host "   4. Fill the form and click 'CREATE EMPLOYEE'" -ForegroundColor White
Write-Host "   5. New employee appears instantly!" -ForegroundColor White
Write-Host "   6. Click delete icon to remove employee" -ForegroundColor White
Write-Host ""
Write-Host "📝 NOTE:" -ForegroundColor Cyan
Write-Host "   - This uses IN-MEMORY storage (data resets on restart)" -ForegroundColor Gray
Write-Host "   - No AWS credentials needed" -ForegroundColor Gray
Write-Host "   - Perfect for UI testing and demos" -ForegroundColor Gray
Write-Host ""
Write-Host "🛑 TO STOP:" -ForegroundColor Red
Write-Host "   1. Press Ctrl+C here to stop frontend" -ForegroundColor White
Write-Host "   2. Run: Stop-Job $($backendJob.Id); Remove-Job $($backendJob.Id)" -ForegroundColor White
Write-Host ""
Write-Host "════════════════════════════════════════════`n" -ForegroundColor Green

Set-Location $frontendPath
npm start

# Cleanup on exit
Stop-Job $backendJob -ErrorAction SilentlyContinue
Remove-Job $backendJob -ErrorAction SilentlyContinue
