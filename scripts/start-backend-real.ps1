# Start Echte Backend (met AWS DynamoDB en Kubernetes)
# Dit script checkt of alles is geconfigureerd voordat het start

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  HR PORTAL - ECHTE BACKEND STARTUP" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Dit start de ECHTE backend met:" -ForegroundColor Yellow
Write-Host "  - AWS DynamoDB voor data storage" -ForegroundColor White
Write-Host "  - Kubernetes voor workspace provisioning" -ForegroundColor White
Write-Host ""

$errors = @()

# Check 1: AWS CLI
Write-Host "[1/5] Checking AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    Write-Host "      ✓ AWS CLI installed: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "      ✗ AWS CLI not found!" -ForegroundColor Red
    $errors += "AWS CLI is not installed. Install from: https://aws.amazon.com/cli/"
}

# Check 2: AWS Credentials
Write-Host "`n[2/5] Checking AWS Credentials..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
    Write-Host "      ✓ AWS Credentials configured" -ForegroundColor Green
    Write-Host "        Account: $($awsIdentity.Account)" -ForegroundColor Gray
    Write-Host "        User: $($awsIdentity.Arn)" -ForegroundColor Gray
} catch {
    Write-Host "      ✗ AWS Credentials not configured!" -ForegroundColor Red
    $errors += "AWS credentials not found. Run: aws configure"
}

# Check 3: DynamoDB Tables
Write-Host "`n[3/5] Checking DynamoDB Tables..." -ForegroundColor Yellow
try {
    $tables = aws dynamodb list-tables --output json 2>&1 | ConvertFrom-Json
    $employeesTable = $tables.TableNames | Where-Object { $_ -like "*employees*" -and $_ -notlike "*workspaces*" }
    $workspacesTable = $tables.TableNames | Where-Object { $_ -like "*workspaces*" }
    
    if ($employeesTable) {
        Write-Host "      ✓ Employees table found: $employeesTable" -ForegroundColor Green
    } else {
        Write-Host "      ✗ Employees table not found!" -ForegroundColor Red
        $errors += "DynamoDB employees table not found. Deploy with Terraform first."
    }
    
    if ($workspacesTable) {
        Write-Host "      ✓ Workspaces table found: $workspacesTable" -ForegroundColor Green
    } else {
        Write-Host "      ⚠ Workspaces table not found (optional)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ✗ Cannot access DynamoDB!" -ForegroundColor Red
    $errors += "Cannot access DynamoDB. Check credentials and permissions."
}

# Check 4: Kubernetes
Write-Host "`n[4/5] Checking Kubernetes..." -ForegroundColor Yellow
try {
    $k8sVersion = kubectl version --client --short 2>&1
    Write-Host "      ✓ kubectl installed" -ForegroundColor Green
    
    # Try to connect to cluster
    try {
        $nodes = kubectl get nodes 2>&1
        Write-Host "      ✓ Connected to Kubernetes cluster" -ForegroundColor Green
    } catch {
        Write-Host "      ⚠ Cannot connect to cluster (workspace provisioning will fail)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ⚠ kubectl not found (workspace provisioning will be disabled)" -ForegroundColor Yellow
}

# Check 5: Backend Dependencies
Write-Host "`n[5/5] Checking Backend Dependencies..." -ForegroundColor Yellow
$backendPath = "applications\hr-portal\backend"
if (Test-Path "$backendPath\node_modules") {
    Write-Host "      ✓ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "      ⚠ Dependencies not installed" -ForegroundColor Yellow
    Write-Host "        Installing now..." -ForegroundColor Gray
    Set-Location $backendPath
    npm install
    if ($LASTEXITCODE -ne 0) {
        $errors += "Failed to install dependencies"
    } else {
        Write-Host "      ✓ Dependencies installed successfully" -ForegroundColor Green
    }
    Set-Location ..\..\..\
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "  ALL CHECKS PASSED ✓" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Starting REAL backend..." -ForegroundColor Green
    Write-Host ""
    
    # Set environment variables
    $env:PORT = "3001"
    $env:NODE_ENV = "development"
    $env:AWS_REGION = "eu-west-1"
    
    # Find table names
    try {
        $tables = aws dynamodb list-tables --output json | ConvertFrom-Json
        $employeesTable = $tables.TableNames | Where-Object { $_ -like "*employees*" -and $_ -notlike "*workspaces*" } | Select-Object -First 1
        $workspacesTable = $tables.TableNames | Where-Object { $_ -like "*workspaces*" } | Select-Object -First 1
        
        if ($employeesTable) {
            $env:DYNAMODB_TABLE = $employeesTable
            Write-Host "Using employees table: $employeesTable" -ForegroundColor Cyan
        }
        if ($workspacesTable) {
            $env:DYNAMODB_WORKSPACES_TABLE = $workspacesTable
            Write-Host "Using workspaces table: $workspacesTable" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Using default table names" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Backend API: http://localhost:3001" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Cyan
    
    Set-Location $backendPath
    npm start
    
} else {
    Write-Host "  ERRORS FOUND!" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please fix the following issues:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($error in $errors) {
        Write-Host "  ✗ $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Quick fixes:" -ForegroundColor Cyan
    Write-Host "  1. Install AWS CLI: https://aws.amazon.com/cli/" -ForegroundColor White
    Write-Host "  2. Configure credentials: aws configure" -ForegroundColor White
    Write-Host "  3. Deploy infrastructure: cd terraform && terraform apply" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use mock server: .\scripts\start-backend.ps1" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
