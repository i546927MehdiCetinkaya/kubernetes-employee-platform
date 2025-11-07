# Restart Frontend with New Configuration
# This restarts the frontend to pick up the new .env file

Write-Host "`n=== RESTARTING FRONTEND WITH BACKEND CONNECTION ===" -ForegroundColor Cyan
Write-Host ""

$frontendPath = "applications\hr-portal\frontend"

Write-Host "[INFO] Backend is running on: http://localhost:3001" -ForegroundColor Green
Write-Host "[INFO] Frontend will connect to backend via .env configuration" -ForegroundColor Green
Write-Host ""

Set-Location $frontendPath

Write-Host "Starting frontend on http://localhost:3000 ..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=== TESTING INSTRUCTIONS ===" -ForegroundColor Cyan
Write-Host "1. Browser will open automatically" -ForegroundColor White
Write-Host "2. Click 'REFRESH' to load employees from backend" -ForegroundColor White  
Write-Host "3. Click 'ADD EMPLOYEE' to create a new employee" -ForegroundColor White
Write-Host "4. Fill the form and click 'CREATE EMPLOYEE'" -ForegroundColor White
Write-Host "5. Employee should appear in the list!" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: If you see DynamoDB errors, that's expected" -ForegroundColor Yellow
Write-Host "      The backend needs AWS credentials for full functionality" -ForegroundColor Yellow
Write-Host "==============================`n" -ForegroundColor Cyan

npm start
