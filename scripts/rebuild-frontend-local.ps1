# Frontend Rebuild Script
# Run this after starting Docker Desktop

Write-Host "`n=== Frontend Rebuild Script ===" -ForegroundColor Cyan
Write-Host "This will rebuild and deploy the frontend with the API URL fix`n" -ForegroundColor White

# Check if Docker is running
try {
    docker ps | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Desktop is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again.`n" -ForegroundColor Yellow
    exit 1
}

# Navigate to frontend directory
$FRONTEND_DIR = "c:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3\applications\hr-portal\frontend"
Set-Location $FRONTEND_DIR

Write-Host "`n1. Logging in to ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region eu-west-1 --profile fictisb_IsbUsersPS-920120424621 | docker login --username AWS --password-stdin 920120424621.dkr.ecr.eu-west-1.amazonaws.com

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ECR login failed! Make sure AWS SSO is active.`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Building frontend image..." -ForegroundColor Yellow
docker build -t 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-frontend:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n3. Pushing to ECR..." -ForegroundColor Yellow
docker push 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-frontend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker push failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n4. Updating kubeconfig..." -ForegroundColor Yellow
aws eks update-kubeconfig --name innovatech-employee-lifecycle --region eu-west-1 --profile fictisb_IsbUsersPS-920120424621

Write-Host "`n5. Restarting frontend deployment..." -ForegroundColor Yellow
kubectl rollout restart deployment/hr-portal-frontend -n hr-portal

Write-Host "`n6. Waiting for rollout..." -ForegroundColor Yellow
kubectl rollout status deployment/hr-portal-frontend -n hr-portal --timeout=5m

Write-Host "`n7. Checking pod status..." -ForegroundColor Yellow
kubectl get pods -n hr-portal -l app=hr-portal-frontend

Write-Host "`n✅ Frontend successfully rebuilt and deployed!" -ForegroundColor Green
Write-Host "`nWait 1-2 minutes for the new pods to be fully ready, then:" -ForegroundColor Yellow
Write-Host "1. Open: http://k8s-hrportal-hrportal-936a6c829f-1479683540.eu-west-1.elb.amazonaws.com" -ForegroundColor Cyan
Write-Host "2. Hard refresh in browser (Ctrl+Shift+R or Ctrl+F5)" -ForegroundColor Cyan
Write-Host "3. Try creating a new employee`n" -ForegroundColor Cyan
