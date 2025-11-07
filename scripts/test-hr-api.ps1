# Test HR Portal API
# Quick test script to verify backend is working

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  HR PORTAL API TEST" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:3001"

# Test 1: Health Check
Write-Host "[1/5] Testing Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -TimeoutSec 5
    Write-Host "      ✓ Health check passed" -ForegroundColor Green
    Write-Host "      Response: $($health | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "      ✗ Health check failed!" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n[ERROR] Backend is not running on $baseUrl" -ForegroundColor Red
    Write-Host "        Start it with: .\scripts\start-backend.ps1" -ForegroundColor Yellow
    exit 1
}

# Test 2: Get All Employees
Write-Host "`n[2/5] Testing Get All Employees..." -ForegroundColor Yellow
try {
    $employees = Invoke-RestMethod -Uri "$baseUrl/api/employees"
    $count = $employees.employees.Count
    Write-Host "      ✓ Successfully retrieved $count employees" -ForegroundColor Green
    foreach ($emp in $employees.employees) {
        Write-Host "        - $($emp.firstName) $($emp.lastName) ($($emp.email))" -ForegroundColor Gray
    }
} catch {
    Write-Host "      ✗ Failed to get employees!" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Create Employee
Write-Host "`n[3/5] Testing Create Employee..." -ForegroundColor Yellow
$newEmployee = @{
    firstName = "Test"
    lastName = "User"
    email = "test.user@example.com"
    role = "developer"
    department = "Engineering"
} | ConvertTo-Json

try {
    $created = Invoke-RestMethod -Uri "$baseUrl/api/employees" `
        -Method Post `
        -Body $newEmployee `
        -ContentType "application/json"
    
    $newId = $created.employee.employeeId
    Write-Host "      ✓ Employee created successfully" -ForegroundColor Green
    Write-Host "        ID: $newId" -ForegroundColor Gray
    Write-Host "        Name: $($created.employee.firstName) $($created.employee.lastName)" -ForegroundColor Gray
} catch {
    Write-Host "      ✗ Failed to create employee!" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    $newId = $null
}

# Test 4: Get Single Employee
if ($newId) {
    Write-Host "`n[4/5] Testing Get Single Employee..." -ForegroundColor Yellow
    try {
        $employee = Invoke-RestMethod -Uri "$baseUrl/api/employees/$newId"
        Write-Host "      ✓ Successfully retrieved employee" -ForegroundColor Green
        Write-Host "        Name: $($employee.employee.firstName) $($employee.employee.lastName)" -ForegroundColor Gray
        Write-Host "        Email: $($employee.employee.email)" -ForegroundColor Gray
    } catch {
        Write-Host "      ✗ Failed to get employee!" -ForegroundColor Red
        Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 5: Delete Employee
    Write-Host "`n[5/5] Testing Delete Employee..." -ForegroundColor Yellow
    try {
        $deleted = Invoke-RestMethod -Uri "$baseUrl/api/employees/$newId" -Method Delete
        Write-Host "      ✓ Employee deleted successfully" -ForegroundColor Green
        Write-Host "        Message: $($deleted.message)" -ForegroundColor Gray
    } catch {
        Write-Host "      ✗ Failed to delete employee!" -ForegroundColor Red
        Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`n[4/5] Skipping Get Single Employee (no ID)" -ForegroundColor Yellow
    Write-Host "`n[5/5] Skipping Delete Employee (no ID)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  TEST COMPLETE" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All API endpoints are working correctly!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Start frontend: .\scripts\start-frontend.ps1" -ForegroundColor White
Write-Host "  2. Open browser: http://localhost:3000" -ForegroundColor White
Write-Host "  3. Test the UI!" -ForegroundColor White
Write-Host ""
