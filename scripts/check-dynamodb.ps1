# Check DynamoDB Data
# Dit script laat zien welke employees in DynamoDB staan

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  DYNAMODB DATA CHECK" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check AWS credentials
Write-Host "[1/3] Checking AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
    Write-Host "      ✓ Connected as: $($identity.Arn)" -ForegroundColor Green
} catch {
    Write-Host "      ✗ AWS credentials not configured!" -ForegroundColor Red
    Write-Host "`nRun: aws configure" -ForegroundColor Yellow
    exit 1
}

# Find tables
Write-Host "`n[2/3] Finding DynamoDB tables..." -ForegroundColor Yellow
try {
    $allTables = aws dynamodb list-tables --output json | ConvertFrom-Json
    $employeesTable = $allTables.TableNames | Where-Object { $_ -like "*employees*" -and $_ -notlike "*workspaces*" } | Select-Object -First 1
    $workspacesTable = $allTables.TableNames | Where-Object { $_ -like "*workspaces*" } | Select-Object -First 1
    
    if ($employeesTable) {
        Write-Host "      ✓ Employees table: $employeesTable" -ForegroundColor Green
    } else {
        Write-Host "      ✗ No employees table found!" -ForegroundColor Red
        Write-Host "`nAvailable tables:" -ForegroundColor Yellow
        $allTables.TableNames | ForEach-Object { Write-Host "        - $_" -ForegroundColor Gray }
        exit 1
    }
    
    if ($workspacesTable) {
        Write-Host "      ✓ Workspaces table: $workspacesTable" -ForegroundColor Green
    }
} catch {
    Write-Host "      ✗ Cannot list tables!" -ForegroundColor Red
    exit 1
}

# Scan employees table
Write-Host "`n[3/3] Scanning employees table..." -ForegroundColor Yellow
try {
    $scanResult = aws dynamodb scan --table-name $employeesTable --output json | ConvertFrom-Json
    $count = $scanResult.Count
    
    Write-Host "      ✓ Found $count employees" -ForegroundColor Green
    Write-Host ""
    
    if ($count -eq 0) {
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host "  NO EMPLOYEES IN DYNAMODB" -ForegroundColor Yellow
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "The table is empty. Create employees via:" -ForegroundColor Yellow
        Write-Host "  1. The frontend UI (http://localhost:3000)" -ForegroundColor White
        Write-Host "  2. Or use: .\scripts\create-employee.ps1" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host "  EMPLOYEES IN DYNAMODB" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($item in $scanResult.Items) {
            Write-Host "Employee:" -ForegroundColor Cyan
            Write-Host "  ID: $($item.employeeId.S)" -ForegroundColor White
            Write-Host "  Name: $($item.firstName.S) $($item.lastName.S)" -ForegroundColor White
            Write-Host "  Email: $($item.email.S)" -ForegroundColor White
            Write-Host "  Role: $($item.role.S)" -ForegroundColor White
            Write-Host "  Department: $($item.department.S)" -ForegroundColor White
            Write-Host "  Status: $($item.status.S)" -ForegroundColor White
            Write-Host "  Created: $($item.createdAt.S)" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Host "Total: $count employees" -ForegroundColor Cyan
    }
    
    # Check workspaces if table exists
    if ($workspacesTable) {
        Write-Host "`n=========================================" -ForegroundColor Cyan
        Write-Host "  WORKSPACES" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
        
        $workspaceResult = aws dynamodb scan --table-name $workspacesTable --output json | ConvertFrom-Json
        $wsCount = $workspaceResult.Count
        
        Write-Host "Found $wsCount workspaces" -ForegroundColor Green
        Write-Host ""
        
        if ($wsCount -gt 0) {
            foreach ($ws in $workspaceResult.Items) {
                Write-Host "Workspace:" -ForegroundColor Cyan
                Write-Host "  ID: $($ws.workspaceId.S)" -ForegroundColor White
                Write-Host "  Employee: $($ws.employeeId.S)" -ForegroundColor White
                Write-Host "  Name: $($ws.name.S)" -ForegroundColor White
                Write-Host "  URL: $($ws.url.S)" -ForegroundColor White
                Write-Host "  Status: $($ws.status.S)" -ForegroundColor White
                Write-Host ""
            }
        }
    }
    
} catch {
    Write-Host "      ✗ Cannot scan table!" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands:" -ForegroundColor Cyan
Write-Host "  View again: .\scripts\check-dynamodb.ps1" -ForegroundColor White
Write-Host "  Create employee: .\scripts\create-employee.ps1" -ForegroundColor White
Write-Host "  Delete employee: .\scripts\delete-employee.ps1" -ForegroundColor White
Write-Host ""
