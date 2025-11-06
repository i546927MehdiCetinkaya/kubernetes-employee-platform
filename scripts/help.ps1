# Employee Management Helper Script
# Quick reference for managing employees

Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║         Employee Management - Quick Reference Guide              ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "Available Commands:" -ForegroundColor Green
Write-Host ""

Write-Host "1. CREATE A NEW EMPLOYEE" -ForegroundColor Yellow
Write-Host "   .\scripts\create-employee.ps1 \`" -ForegroundColor White
Write-Host "     -FirstName `"John`" \`" -ForegroundColor White
Write-Host "     -LastName `"Doe`" \`" -ForegroundColor White
Write-Host "     -Email `"john.doe@innovatech.com`" \`" -ForegroundColor White
Write-Host "     -Role `"developer`" \`" -ForegroundColor White
Write-Host "     -Department `"Engineering`"" -ForegroundColor White
Write-Host ""
Write-Host "   Available Roles: developer, manager, admin, hr" -ForegroundColor Gray
Write-Host ""

Write-Host "2. LIST ALL EMPLOYEES" -ForegroundColor Yellow
Write-Host "   .\scripts\list-employees.ps1" -ForegroundColor White
Write-Host ""

Write-Host "3. DELETE AN EMPLOYEE" -ForegroundColor Yellow
Write-Host "   .\scripts\delete-employee.ps1 -EmployeeId `"EMP-20251106123456`"" -ForegroundColor White
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

Write-Host "AWS CLI Direct Commands:" -ForegroundColor Green
Write-Host ""

Write-Host "• Scan all employees:" -ForegroundColor Yellow
Write-Host "  aws dynamodb scan --table-name innovatech-employees --region eu-west-1" -ForegroundColor White
Write-Host ""

Write-Host "• Get specific employee:" -ForegroundColor Yellow
Write-Host "  aws dynamodb get-item \`" -ForegroundColor White
Write-Host "    --table-name innovatech-employees \`" -ForegroundColor White
Write-Host "    --key '{`"employeeId`": {`"S`": `"EMP-123`"}}' \`" -ForegroundColor White
Write-Host "    --region eu-west-1" -ForegroundColor White
Write-Host ""

Write-Host "• Count employees:" -ForegroundColor Yellow
Write-Host "  aws dynamodb scan --table-name innovatech-employees --select COUNT --region eu-west-1" -ForegroundColor White
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

Write-Host "Quick Examples:" -ForegroundColor Green
Write-Host ""

Write-Host "Example 1: Create a Developer" -ForegroundColor Cyan
Write-Host @"
  .\scripts\create-employee.ps1 \`
    -FirstName "Alice" \`
    -LastName "Johnson" \`
    -Email "alice.johnson@innovatech.com" \`
    -Role "developer" \`
    -Department "Platform Engineering"
"@ -ForegroundColor White
Write-Host ""

Write-Host "Example 2: Create a Manager" -ForegroundColor Cyan
Write-Host @"
  .\scripts\create-employee.ps1 \`
    -FirstName "Bob" \`
    -LastName "Smith" \`
    -Email "bob.smith@innovatech.com" \`
    -Role "manager" \`
    -Department "Engineering"
"@ -ForegroundColor White
Write-Host ""

Write-Host "Example 3: Create HR Representative" -ForegroundColor Cyan
Write-Host @"
  .\scripts\create-employee.ps1 \`
    -FirstName "Carol" \`
    -LastName "Davis" \`
    -Email "carol.davis@innovatech.com" \`
    -Role "hr" \`
    -Department "Human Resources"
"@ -ForegroundColor White
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

Write-Host "Infrastructure Commands:" -ForegroundColor Green
Write-Host ""

Write-Host "• Check EKS Cluster Status:" -ForegroundColor Yellow
Write-Host "  aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1" -ForegroundColor White
Write-Host ""

Write-Host "• Check DynamoDB Table:" -ForegroundColor Yellow
Write-Host "  aws dynamodb describe-table --table-name innovatech-employees --region eu-west-1" -ForegroundColor White
Write-Host ""

Write-Host "• List All Tables:" -ForegroundColor Yellow
Write-Host "  aws dynamodb list-tables --region eu-west-1" -ForegroundColor White
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

Write-Host "Need Help?" -ForegroundColor Cyan
Write-Host "  • Check README.md for full documentation" -ForegroundColor White
Write-Host "  • See Quick Reference section for more commands" -ForegroundColor White
Write-Host "  • Review FAQ for common questions" -ForegroundColor White
Write-Host ""
