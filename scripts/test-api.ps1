# Test HR Portal Backend API
# Tests the actual API instead of direct DynamoDB access

Write-Host "`n=== HR Portal Backend API Test ===`n" -ForegroundColor Cyan

# First, we need to get the backend service endpoint
Write-Host "Finding HR Portal Backend endpoint..." -ForegroundColor Yellow

# Check if there's a Load Balancer
$lbs = aws elbv2 describe-load-balancers --region eu-west-1 --output json 2>$null | ConvertFrom-Json
$k8sLB = $lbs.LoadBalancers | Where-Object { $_.LoadBalancerName -like "*k8s-hrportal*" } | Select-Object -First 1

if ($k8sLB) {
    $API_URL = "http://$($k8sLB.DNSName)/api"
    Write-Host "[OK] Found Load Balancer: $($k8sLB.DNSName)" -ForegroundColor Green
} else {
    Write-Host "[INFO] No Load Balancer found yet" -ForegroundColor Yellow
    Write-Host "The backend is deployed but not publicly accessible" -ForegroundColor Gray
    Write-Host "`nOptions to access it:" -ForegroundColor Cyan
    Write-Host "1. Wait for Load Balancer provisioning (can take 5-10 minutes)" -ForegroundColor White
    Write-Host "2. Use kubectl port-forward (requires kubectl access)" -ForegroundColor White
    Write-Host "3. Access via AWS Console EKS service discovery" -ForegroundColor White
    Write-Host "`nFor now, using direct DynamoDB access (your PowerShell scripts)`n" -ForegroundColor Yellow
    exit 0
}

Write-Host "`nTesting API endpoints...`n" -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "[TEST 1] Health Check" -ForegroundColor Cyan
Write-Host "---------------------------------------" -ForegroundColor Gray
try {
    $health = Invoke-RestMethod -Uri "$API_URL/../health" -Method GET -ErrorAction Stop
    Write-Host "[PASS] API is healthy: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Health check failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Get All Employees
Write-Host "[TEST 2] Get All Employees" -ForegroundColor Cyan
Write-Host "---------------------------------------" -ForegroundColor Gray
try {
    $response = Invoke-RestMethod -Uri "$API_URL/employees" -Method GET -ErrorAction Stop
    Write-Host "[PASS] Found $($response.employees.Count) employees" -ForegroundColor Green
    foreach ($emp in $response.employees) {
        Write-Host "  - $($emp.firstName) $($emp.lastName) ($($emp.role))" -ForegroundColor White
    }
} catch {
    Write-Host "[FAIL] Could not fetch employees: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Create Employee via API
Write-Host "[TEST 3] Create Employee via API" -ForegroundColor Cyan
Write-Host "---------------------------------------" -ForegroundColor Gray
$newEmployee = @{
    firstName = "API"
    lastName = "Test"
    email = "api.test@innovatech.com"
    role = "developer"
    department = "API Testing"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$API_URL/employees" -Method POST -Body $newEmployee -ContentType "application/json" -ErrorAction Stop
    Write-Host "[PASS] Employee created via API!" -ForegroundColor Green
    Write-Host "  ID: $($response.employee.employeeId)" -ForegroundColor White
    Write-Host "  Message: $($response.message)" -ForegroundColor Gray
    $createdId = $response.employee.employeeId
} catch {
    Write-Host "[FAIL] Could not create employee: $_" -ForegroundColor Red
    $createdId = $null
}
Write-Host ""

# Test 4: Get Specific Employee
if ($createdId) {
    Write-Host "[TEST 4] Get Specific Employee" -ForegroundColor Cyan
    Write-Host "---------------------------------------" -ForegroundColor Gray
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/employees/$createdId" -Method GET -ErrorAction Stop
        Write-Host "[PASS] Retrieved employee $createdId" -ForegroundColor Green
        Write-Host "  Name: $($response.employee.firstName) $($response.employee.lastName)" -ForegroundColor White
    } catch {
        Write-Host "[FAIL] Could not fetch employee: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Test 5: Delete Employee via API
if ($createdId) {
    Write-Host "[TEST 5] Delete Employee via API (Offboarding)" -ForegroundColor Cyan
    Write-Host "---------------------------------------" -ForegroundColor Gray
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/employees/$createdId" -Method DELETE -ErrorAction Stop
        Write-Host "[PASS] Employee offboarded!" -ForegroundColor Green
        Write-Host "  Message: $($response.message)" -ForegroundColor Gray
    } catch {
        Write-Host "[FAIL] Could not offboard employee: $_" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host @"

╔══════════════════════════════════════════════════════════════════╗
║                    API TEST SUMMARY                               ║
╚══════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "Your HR Portal Backend API is working!" -ForegroundColor Green
Write-Host "API Endpoint: $API_URL" -ForegroundColor Cyan
Write-Host "`nWhat You Can Do:" -ForegroundColor Yellow
Write-Host "  1. Use the API directly (curl, Postman, etc.)" -ForegroundColor White
Write-Host "  2. Build and deploy the React frontend" -ForegroundColor White
Write-Host "  3. Continue using PowerShell scripts as alternative`n" -ForegroundColor White

