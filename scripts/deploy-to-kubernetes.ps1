Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  KUBERNETES DEPLOYMENT VIA GITHUB" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deze deployment zal:" -ForegroundColor Yellow
Write-Host ""
Write-Host "STAP 1: Terraform Infrastructure (~15 min)" -ForegroundColor Cyan
Write-Host "  - VPC met publieke/private subnets" -ForegroundColor White
Write-Host "  - EKS Cluster met 2 worker nodes" -ForegroundColor White
Write-Host "  - ECR repositories voor Docker images" -ForegroundColor White
Write-Host "  - IAM roles en security groups" -ForegroundColor White
Write-Host "  - DynamoDB tables (al klaar!)" -ForegroundColor Green
Write-Host ""
Write-Host "STAP 2: Docker Images Builden (~5 min)" -ForegroundColor Cyan
Write-Host "  - hr-portal-backend" -ForegroundColor White
Write-Host "  - hr-portal-frontend" -ForegroundColor White
Write-Host "  - employee-workspace" -ForegroundColor White
Write-Host ""
Write-Host "STAP 3: Kubernetes Deploy (~5 min)" -ForegroundColor Cyan
Write-Host "  - Namespaces, RBAC, Network Policies" -ForegroundColor White
Write-Host "  - Backend deployment (2 replicas)" -ForegroundColor White
Write-Host "  - Frontend deployment (2 replicas)" -ForegroundColor White
Write-Host "  - Application Load Balancer" -ForegroundColor White
Write-Host ""
Write-Host "TOTALE TIJD: ~25 minuten" -ForegroundColor Yellow
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "VEREISTEN:" -ForegroundColor Yellow
Write-Host "  1. Code is gepusht naar GitHub (main branch)" -ForegroundColor White
Write-Host "  2. GitHub Actions heeft AWS toegang" -ForegroundColor White
Write-Host "     (via IAM role: githubrepo)" -ForegroundColor Gray
Write-Host ""
Write-Host "KOSTEN:" -ForegroundColor Yellow
Write-Host "  - EKS Cluster: ~$0.10/uur" -ForegroundColor White
Write-Host "  - EC2 instances (2x t3.medium): ~$0.08/uur" -ForegroundColor White
Write-Host "  - Load Balancer: ~$0.02/uur" -ForegroundColor White
Write-Host "  Totaal: ~$0.20/uur (~$5/dag)" -ForegroundColor Yellow
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "STAPPEN OM TE DEPLOYEN:" -ForegroundColor Green
Write-Host ""
Write-Host "1. Commit je huidige changes:" -ForegroundColor Cyan
Write-Host "   git add ." -ForegroundColor White
Write-Host '   git commit -m "Add frontend to workflow"' -ForegroundColor White
Write-Host "   git push origin main" -ForegroundColor White
Write-Host ""
Write-Host "2. Ga naar GitHub Actions:" -ForegroundColor Cyan
Write-Host "   https://github.com/i546927MehdiCetinkaya/casestudy3/actions" -ForegroundColor Blue
Write-Host ""
Write-Host "3. Klik op 'Deploy Infrastructure' workflow" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Klik op 'Run workflow'" -ForegroundColor Cyan
Write-Host "   Selecteer: Branch: main" -ForegroundColor White
Write-Host "   Klik: 'Run workflow'" -ForegroundColor White
Write-Host ""
Write-Host "5. Wacht tot deployment klaar is" -ForegroundColor Cyan
Write-Host "   (~25 minuten)" -ForegroundColor Gray
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NA DEPLOYMENT:" -ForegroundColor Green
Write-Host ""
Write-Host "Je krijgt een ALB URL zoals:" -ForegroundColor White
Write-Host "  http://k8s-hrportal-hrportal-xxxx.eu-west-1.elb.amazonaws.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "Die URL geeft toegang tot je frontend!" -ForegroundColor Green
Write-Host ""
Write-Host "Check deployment status:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n hr-portal" -ForegroundColor White
Write-Host "  kubectl get svc -n hr-portal" -ForegroundColor White
Write-Host "  kubectl get ingress -n hr-portal" -ForegroundColor White
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wil je nu de changes committen en pushen?" -ForegroundColor Yellow
Write-Host "(Dit start nog NIET de deployment, dat doe je daarna handmatig in GitHub)" -ForegroundColor Gray
Write-Host ""
$confirm = Read-Host "Type 'ja' om te committen"

if ($confirm -eq 'ja') {
    Write-Host ""
    Write-Host "Committing changes..." -ForegroundColor Green
    
    Set-Location "C:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3"
    
    git add .
    git commit -m "Add frontend to deployment workflow and fix role validation"
    git push origin main
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  CHANGES GEPUSHT!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nu naar GitHub gaan:" -ForegroundColor Cyan
    Write-Host "  https://github.com/i546927MehdiCetinkaya/casestudy3/actions" -ForegroundColor Blue
    Write-Host ""
    Write-Host "En daar de workflow handmatig starten!" -ForegroundColor Yellow
    Write-Host ""
    
    # Open browser
    Start-Process "https://github.com/i546927MehdiCetinkaya/casestudy3/actions"
    
} else {
    Write-Host ""
    Write-Host "Deployment cancelled. Je kan later committen met:" -ForegroundColor Yellow
    Write-Host "  git add ." -ForegroundColor White
    Write-Host '  git commit -m "Add frontend to workflow"' -ForegroundColor White
    Write-Host "  git push origin main" -ForegroundColor White
    Write-Host ""
}
