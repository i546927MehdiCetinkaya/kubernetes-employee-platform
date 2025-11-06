# Script to list all employees from DynamoDB
# Usage: .\list-employees.ps1

Write-Host "=== Fetching All Employees ===" -ForegroundColor Green
Write-Host ""

try {
    $result = aws dynamodb scan `
        --table-name innovatech-employees `
        --region eu-west-1 `
        --output json | ConvertFrom-Json
    
    if ($result.Count -eq 0 -or $result.Items.Count -eq 0) {
        Write-Host "No employees found in the system." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Found $($result.Count) employee(s):" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($item in $result.Items) {
        $employeeId = $item.employeeId.S
        $firstName = $item.firstName.S
        $lastName = $item.lastName.S
        $email = $item.email.S
        $role = $item.role.S
        $department = $item.department.S
        $status = if ($item.status.S) { $item.status.S } else { "N/A" }
        $startDate = if ($item.startDate.S) { $item.startDate.S } else { "N/A" }
        
        Write-Host "================================================================" -ForegroundColor Gray
        Write-Host "  ID:         $employeeId" -ForegroundColor White
        Write-Host "  Name:       $firstName $lastName" -ForegroundColor White
        Write-Host "  Email:      $email" -ForegroundColor White
        Write-Host "  Role:       $role" -ForegroundColor Cyan
        Write-Host "  Department: $department" -ForegroundColor Cyan
        Write-Host "  Status:     $status" -ForegroundColor $(if ($status -eq "active") { "Green" } else { "Red" })
        Write-Host "  Start Date: $startDate" -ForegroundColor Gray
        
        if ($item.workspaceUrl.S) {
            Write-Host "  Workspace:  $($item.workspaceUrl.S)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "================================================================" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Total: $($result.Count) employee(s)" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Error fetching employees: $_" -ForegroundColor Red
    exit 1
}
