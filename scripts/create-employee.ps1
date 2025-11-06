# Script to create a new employee in DynamoDB
# Usage: .\create-employee.ps1 -FirstName "John" -LastName "Doe" -Email "john.doe@innovatech.com" -Role "developer" -Department "Engineering"

param(
    [Parameter(Mandatory=$true)]
    [string]$FirstName,
    
    [Parameter(Mandatory=$true)]
    [string]$LastName,
    
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("developer", "manager", "admin", "hr")]
    [string]$Role,
    
    [Parameter(Mandatory=$true)]
    [string]$Department
)

# Generate unique employee ID
$EmployeeId = "EMP-" + (Get-Date -Format "yyyyMMddHHmmss")
$CurrentDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"

Write-Host "=== Creating Employee ===" -ForegroundColor Green
Write-Host "Employee ID: $EmployeeId"
Write-Host "Name: $FirstName $LastName"
Write-Host "Email: $Email"
Write-Host "Role: $Role"
Write-Host "Department: $Department"
Write-Host ""

# Create JSON for DynamoDB
$item = @{
    "employeeId" = @{ "S" = $EmployeeId }
    "firstName" = @{ "S" = $FirstName }
    "lastName" = @{ "S" = $LastName }
    "email" = @{ "S" = $Email }
    "role" = @{ "S" = $Role }
    "department" = @{ "S" = $Department }
    "status" = @{ "S" = "active" }
    "startDate" = @{ "S" = $CurrentDate }
    "createdAt" = @{ "S" = $CurrentDate }
    "workspaceUrl" = @{ "S" = "http://workspace-$($EmployeeId.ToLower()).innovatech.local" }
}

$itemJson = $item | ConvertTo-Json -Compress

Write-Host "Adding to DynamoDB..." -ForegroundColor Yellow

# Create temporary JSON file to avoid PowerShell escaping issues
$tempFile = [System.IO.Path]::GetTempFileName()
$item | ConvertTo-Json -Compress | Out-File -FilePath $tempFile -Encoding ASCII

try {
    aws dynamodb put-item `
        --table-name innovatech-employees `
        --item file://$tempFile `
        --region eu-west-1
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "[SUCCESS] Employee created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Employee Details:" -ForegroundColor Cyan
    Write-Host "  ID: $EmployeeId"
    Write-Host "  Name: $FirstName $LastName"
    Write-Host "  Email: $Email"
    Write-Host "  Role: $Role"
    Write-Host "  Department: $Department"
    Write-Host "  Workspace URL: http://workspace-$($EmployeeId.ToLower()).innovatech.local"
    Write-Host ""
    
    # Verify creation
    Write-Host "Verifying creation..." -ForegroundColor Yellow
    $keyFile = [System.IO.Path]::GetTempFileName()
    @{"employeeId" = @{"S" = $EmployeeId}} | ConvertTo-Json -Compress | Out-File -FilePath $keyFile -Encoding ASCII
    
    aws dynamodb get-item `
        --table-name innovatech-employees `
        --key file://$keyFile `
        --region eu-west-1 `
        --output json
    
    Remove-Item $keyFile -ErrorAction SilentlyContinue
        
} catch {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "[ERROR] Error creating employee: $_" -ForegroundColor Red
    exit 1
}
