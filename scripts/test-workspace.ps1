# Test Workspace Access
# This script helps you access and test employee workspaces

Write-Host "=== Workspace Testing Tool ===" -ForegroundColor Cyan
Write-Host ""

# Check if we have any employees
Write-Host "Checking for employees..." -ForegroundColor Yellow
$employees = aws dynamodb scan --table-name innovatech-employees --region eu-west-1 --output json | ConvertFrom-Json

if ($employees.Count -eq 0) {
    Write-Host "No employees found. Create an employee first!" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($employees.Count) employee(s)" -ForegroundColor Green
Write-Host ""

# List employees
Write-Host "Available Employees:" -ForegroundColor Cyan
$index = 1
foreach ($item in $employees.Items) {
    Write-Host "  $index. $($item.firstName.S) $($item.lastName.S) - $($item.role.S) ($($item.employeeId.S))" -ForegroundColor White
    $index++
}
Write-Host ""

# Since kubectl doesn't work with SSO, let's check via AWS API
Write-Host "Checking EKS Cluster Status..." -ForegroundColor Yellow
$clusterStatus = aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1 --query 'cluster.status' --output text

if ($clusterStatus -eq "ACTIVE") {
    Write-Host "[OK] EKS Cluster is ACTIVE" -ForegroundColor Green
} else {
    Write-Host "[WARN] EKS Cluster status: $clusterStatus" -ForegroundColor Yellow
}
Write-Host ""

# Check node group
Write-Host "Checking Node Group..." -ForegroundColor Yellow
try {
    $nodeGroups = aws eks list-nodegroups --cluster-name innovatech-employee-lifecycle --region eu-west-1 --output json | ConvertFrom-Json
    if ($nodeGroups.nodegroups.Count -gt 0) {
        Write-Host "[OK] Node groups found: $($nodeGroups.nodegroups -join ', ')" -ForegroundColor Green
        
        foreach ($ng in $nodeGroups.nodegroups) {
            $ngStatus = aws eks describe-nodegroup --cluster-name innovatech-employee-lifecycle --nodegroup-name $ng --region eu-west-1 --query 'nodegroup.status' --output text
            Write-Host "  - $ng`: $ngStatus" -ForegroundColor $(if ($ngStatus -eq "ACTIVE") { "Green" } else { "Yellow" })
        }
    }
} catch {
    Write-Host "[WARN] Could not check node groups" -ForegroundColor Yellow
}
Write-Host ""

# Check Load Balancer (for accessing services)
Write-Host "Checking Load Balancers..." -ForegroundColor Yellow
try {
    $lbs = aws elbv2 describe-load-balancers --region eu-west-1 --output json | ConvertFrom-Json
    $k8sLBs = $lbs.LoadBalancers | Where-Object { $_.LoadBalancerName -like "*k8s*" }
    
    if ($k8sLBs) {
        Write-Host "[OK] Found Kubernetes Load Balancers:" -ForegroundColor Green
        foreach ($lb in $k8sLBs) {
            Write-Host "  - $($lb.LoadBalancerName)" -ForegroundColor White
            Write-Host "    DNS: $($lb.DNSName)" -ForegroundColor Cyan
            Write-Host "    State: $($lb.State.Code)" -ForegroundColor $(if ($lb.State.Code -eq "active") { "Green" } else { "Yellow" })
        }
        Write-Host ""
        Write-Host "You can access the HR Portal at:" -ForegroundColor Green
        Write-Host "  http://$($k8sLBs[0].DNSName)" -ForegroundColor Cyan
    } else {
        Write-Host "[INFO] No Kubernetes Load Balancers found yet" -ForegroundColor Yellow
        Write-Host "       Load Balancers may still be provisioning" -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARN] Could not check load balancers: $_" -ForegroundColor Yellow
}
Write-Host ""

# Suggest next steps
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Access HR Portal via Load Balancer (if available)" -ForegroundColor Yellow
Write-Host "   Check the DNS address above" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test DynamoDB directly (employees are already there!)" -ForegroundColor Yellow
Write-Host "   .\scripts\list-employees.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Check GitHub Actions deployment logs" -ForegroundColor Yellow
Write-Host "   gh run list --workflow=deploy.yml" -ForegroundColor Gray
Write-Host ""
Write-Host "4. View Kubernetes resources via AWS Console" -ForegroundColor Yellow
Write-Host "   https://console.aws.amazon.com/eks/home?region=eu-west-1" -ForegroundColor Gray
Write-Host ""

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "- Employees in DynamoDB: $($employees.Count)" -ForegroundColor White
Write-Host "- EKS Cluster: $clusterStatus" -ForegroundColor White
Write-Host "- Kubectl Access: Limited (SSO auth issue)" -ForegroundColor Yellow
Write-Host "- Alternative: Use AWS Console to view pods and services" -ForegroundColor Yellow
Write-Host ""
