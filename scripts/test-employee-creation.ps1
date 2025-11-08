# Test employee creation with LoadBalancer service detection

Write-Host "Refreshing AWS credentials..." -ForegroundColor Cyan
& "c:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3\scripts\refresh-credentials.ps1"

Write-Host "`nCreating test employee..." -ForegroundColor Cyan

# Create employee via kubectl exec
$createCommand = @'
cat > /tmp/employee.json << 'EOF'
{
  "firstName": "Mehdi",
  "lastName": "Cetinkaya",
  "email": "mehdicetinkaya6132@gmail.com",
  "role": "developer"
}
EOF
wget -O- --post-file=/tmp/employee.json --header='Content-Type: application/json' http://localhost:3000/api/employees 2>&1
'@

Write-Host "Sending request via kubectl exec..." -ForegroundColor Yellow
kubectl exec -n hr-portal deployment/hr-portal-backend -- sh -c $createCommand

Write-Host "`nWaiting for provisioning logs..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

Write-Host "`nRecent backend logs:" -ForegroundColor Green
kubectl logs -n hr-portal deployment/hr-portal-backend --tail=50 --since=2m | Select-String "Employee|async|LoadBalancer|Welcome|provisioned|error|Waiting"

Write-Host "`nWorkspace resources:" -ForegroundColor Green
kubectl get pod,svc,pvc -n workspaces

Write-Host "`nDone! Check logs above for async LoadBalancer process." -ForegroundColor Cyan
