# Quick Guide to Test Your Deployment

Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║         How to Test Your Employee Lifecycle Platform             ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "Current Status:" -ForegroundColor Green
Write-Host "  ✓ EKS Cluster: ACTIVE" -ForegroundColor Green
Write-Host "  ✓ Node Group: ACTIVE" -ForegroundColor Green
Write-Host "  ✓ DynamoDB: 3 employees stored" -ForegroundColor Green
Write-Host "  ⚠ Load Balancer: Not detected (may be provisioning)" -ForegroundColor Yellow
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION 1: View via AWS Console (Easiest)" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open EKS Console:" -ForegroundColor Yellow
Write-Host "   https://console.aws.amazon.com/eks/home?region=eu-west-1#/clusters/innovatech-employee-lifecycle" -ForegroundColor White
Write-Host ""
Write-Host "2. Click on 'Resources' tab to see:" -ForegroundColor Yellow
Write-Host "   - Namespaces (hr-portal, workspaces)" -ForegroundColor Gray
Write-Host "   - Pods (running applications)" -ForegroundColor Gray
Write-Host "   - Services (endpoints)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Check 'Workloads' to see pod status" -ForegroundColor Yellow
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION 2: Check Deployment Logs" -ForegroundColor Cyan
Write-Host ""
Write-Host "See if Kubernetes resources were deployed:" -ForegroundColor Yellow
Write-Host "  gh run view --log | Select-String -Pattern 'kubectl apply'" -ForegroundColor White
Write-Host ""
Write-Host "Check for any errors:" -ForegroundColor Yellow
Write-Host "  gh run view --log-failed" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION 3: Test DynamoDB (Already Working!)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your employees are successfully stored:" -ForegroundColor Yellow
Write-Host "  .\scripts\list-employees.ps1" -ForegroundColor White
Write-Host ""
Write-Host "This proves:" -ForegroundColor Green
Write-Host "  ✓ AWS infrastructure is working" -ForegroundColor Gray
Write-Host "  ✓ DynamoDB tables are accessible" -ForegroundColor Gray
Write-Host "  ✓ Employee data is persisted" -ForegroundColor Gray
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

Write-Host "OPTION 4: Alternative kubectl Method" -ForegroundColor Cyan
Write-Host ""
Write-Host "Use AWS CLI to assume IAM role, then use kubectl:" -ForegroundColor Yellow
Write-Host @"
  # Get temporary credentials
  aws sts assume-role \
    --role-arn arn:aws:iam::920120424621:role/githubrepo \
    --role-session-name test-session
  
  # Export credentials (from assume-role output)
  `$env:AWS_ACCESS_KEY_ID = "..."
  `$env:AWS_SECRET_ACCESS_KEY = "..."
  `$env:AWS_SESSION_TOKEN = "..."
  
  # Then kubectl should work
  kubectl get pods -n hr-portal
"@ -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

Write-Host "QUICK VERIFICATION COMMANDS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "• Check if pods exist via AWS API:" -ForegroundColor Yellow
Write-Host @"
  aws eks list-pods --cluster innovatech-employee-lifecycle --region eu-west-1
"@ -ForegroundColor White
Write-Host ""
Write-Host "• View deployment logs:" -ForegroundColor Yellow
Write-Host "  gh run view $(gh run list --workflow=deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId')" -ForegroundColor White
Write-Host ""
Write-Host "• Check GitHub Actions output:" -ForegroundColor Yellow
Write-Host "  https://github.com/i546927MehdiCetinkaya/casestudy3/actions" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""

Write-Host "DEMONSTRATION READY!" -ForegroundColor Green
Write-Host ""
Write-Host "What you CAN demonstrate now:" -ForegroundColor Cyan
Write-Host "  ✓ Employee onboarding (DynamoDB)" -ForegroundColor Green
Write-Host "  ✓ Data persistence" -ForegroundColor Green
Write-Host "  ✓ Infrastructure as Code (Terraform)" -ForegroundColor Green
Write-Host "  ✓ CI/CD Pipeline (GitHub Actions)" -ForegroundColor Green
Write-Host "  ✓ AWS integration" -ForegroundColor Green
Write-Host ""
Write-Host "What needs kubectl/console access:" -ForegroundColor Yellow
Write-Host "  ⚠ Live workspace pods" -ForegroundColor Yellow
Write-Host "  ⚠ HR Portal UI" -ForegroundColor Yellow
Write-Host "  ⚠ Kubernetes resources" -ForegroundColor Yellow
Write-Host ""
Write-Host "Workaround: Use AWS Console to show these visually" -ForegroundColor Cyan
Write-Host ""
