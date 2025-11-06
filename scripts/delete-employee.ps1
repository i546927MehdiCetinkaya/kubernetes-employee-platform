# Script to delete an employee from DynamoDB
# Usage: .\delete-employee.ps1 -EmployeeId "EMP-20251106123456"

param(
    [Parameter(Mandatory=$true)]
    [string]$EmployeeId
)

Write-Host "=== Deleting Employee ===" -ForegroundColor Red
Write-Host "Employee ID: $EmployeeId"
Write-Host ""

# First, check if employee exists
Write-Host "Checking if employee exists..." -ForegroundColor Yellow

try {
    $exists = aws dynamodb get-item `
        --table-name innovatech-employees `
        --key "{`"employeeId`": {`"S`": `"$EmployeeId`"}}" `
        --region eu-west-1 `
        --output json | ConvertFrom-Json
    
    if (-not $exists.Item) {
        Write-Host ""
        Write-Host "[ERROR] Employee with ID '$EmployeeId' not found!" -ForegroundColor Red
        exit 1
    }
    
    $firstName = $exists.Item.firstName.S
    $lastName = $exists.Item.lastName.S
    $email = $exists.Item.email.S
    
    Write-Host ""
    Write-Host "Found employee:" -ForegroundColor Yellow
    Write-Host "  Name: $firstName $lastName"
    Write-Host "  Email: $email"
    Write-Host ""
    
    # Confirm deletion
    $confirmation = Read-Host "Are you sure you want to delete this employee? (yes/no)"
    
    if ($confirmation -ne "yes") {
        Write-Host ""
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host ""
    Write-Host "Deleting employee..." -ForegroundColor Yellow
    
    aws dynamodb delete-item `
        --table-name innovatech-employees `
        --key "{`"employeeId`": {`"S`": `"$EmployeeId`"}}" `
        --region eu-west-1
    
    Write-Host ""
    Write-Host "[SUCCESS] Employee deleted successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Note about workspace cleanup
    Write-Host "Note: Workspace pod cleanup (if any) should be done manually:" -ForegroundColor Cyan
    Write-Host "  kubectl delete pod workspace-$($EmployeeId.ToLower()) -n workspaces" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Error deleting employee: $_" -ForegroundColor Red
    exit 1
}
