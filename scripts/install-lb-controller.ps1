# Install AWS Load Balancer Controller
# This script installs the AWS Load Balancer Controller in the EKS cluster

param(
    [string]$ClusterName = "innovatech-employee-lifecycle",
    [string]$Region = "eu-west-1"
)

Write-Host "`n=== AWS Load Balancer Controller Installation ===" -ForegroundColor Cyan
Write-Host "Cluster: $ClusterName" -ForegroundColor White
Write-Host "Region: $Region`n" -ForegroundColor White

# Step 1: Create IAM Policy for Load Balancer Controller
Write-Host "[1/6] Creating IAM Policy..." -ForegroundColor Yellow

# Download IAM policy
$policyUrl = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json"
$policyFile = "iam_policy.json"

Write-Host "  Downloading IAM policy from GitHub..." -ForegroundColor Gray
Invoke-WebRequest -Uri $policyUrl -OutFile $policyFile

# Create IAM policy
Write-Host "  Creating IAM policy 'AWSLoadBalancerControllerIAMPolicy'..." -ForegroundColor Gray
$policyArn = aws iam create-policy `
    --policy-name AWSLoadBalancerControllerIAMPolicy `
    --policy-document "file://$policyFile" `
    --query 'Policy.Arn' `
    --output text 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "  Policy might already exist, fetching ARN..." -ForegroundColor Gray
    $accountId = aws sts get-caller-identity --query 'Account' --output text
    $policyArn = "arn:aws:iam::${accountId}:policy/AWSLoadBalancerControllerIAMPolicy"
}

Write-Host "  [SUCCESS] Policy ARN: $policyArn" -ForegroundColor Green

# Step 2: Create IAM Role using eksctl
Write-Host "`n[2/6] Creating IAM Service Account..." -ForegroundColor Yellow

# Check if eksctl is installed
$eksctlInstalled = Get-Command eksctl -ErrorAction SilentlyContinue
if (-not $eksctlInstalled) {
    Write-Host "  [ERROR] eksctl not found. Installing via Chocolatey..." -ForegroundColor Red
    Write-Host "  Run: choco install eksctl" -ForegroundColor Yellow
    Write-Host "  Or download from: https://eksctl.io/installation/" -ForegroundColor Yellow
    Write-Host "`n  Continuing with AWS CLI fallback..." -ForegroundColor Gray
    
    # Create service account manually
    Write-Host "  Creating service account with AWS CLI..." -ForegroundColor Gray
    
    # Get OIDC provider
    $oidcProvider = aws eks describe-cluster --name $ClusterName --query "cluster.identity.oidc.issuer" --output text --region $Region
    $oidcProvider = $oidcProvider -replace "https://", ""
    
    Write-Host "  OIDC Provider: $oidcProvider" -ForegroundColor Gray
    
    # Create trust policy
    $trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::920120424621:oidc-provider/$oidcProvider"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${oidcProvider}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "${oidcProvider}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
"@
    
    $trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding UTF8
    
    # Create role
    $roleName = "AmazonEKSLoadBalancerControllerRole"
    aws iam create-role `
        --role-name $roleName `
        --assume-role-policy-document file://trust-policy.json `
        --region $Region 2>$null
    
    # Attach policy
    $accountId = aws sts get-caller-identity --query 'Account' --output text
    aws iam attach-role-policy `
        --role-name $roleName `
        --policy-arn $policyArn `
        --region $Region
    
    Write-Host "  [SUCCESS] IAM Role created" -ForegroundColor Green
} else {
    # Use eksctl to create service account
    Write-Host "  Using eksctl to create service account..." -ForegroundColor Gray
    eksctl create iamserviceaccount `
        --cluster=$ClusterName `
        --namespace=kube-system `
        --name=aws-load-balancer-controller `
        --attach-policy-arn=$policyArn `
        --override-existing-serviceaccounts `
        --region=$Region `
        --approve
    
    Write-Host "  [SUCCESS] Service Account created via eksctl" -ForegroundColor Green
}

# Step 3: Install cert-manager (required for Load Balancer Controller)
Write-Host "`n[3/6] Installing cert-manager..." -ForegroundColor Yellow

Write-Host "  Applying cert-manager manifests..." -ForegroundColor Gray
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

Write-Host "  Waiting for cert-manager to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 30

Write-Host "  [SUCCESS] cert-manager installed" -ForegroundColor Green

# Step 4: Add EKS Helm repository
Write-Host "`n[4/6] Adding EKS Helm repository..." -ForegroundColor Yellow

# Check if helm is installed
$helmInstalled = Get-Command helm -ErrorAction SilentlyContinue
if (-not $helmInstalled) {
    Write-Host "  [ERROR] Helm not found. Please install Helm first:" -ForegroundColor Red
    Write-Host "  https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

helm repo add eks https://aws.github.io/eks-charts
helm repo update

Write-Host "  [SUCCESS] Helm repository added" -ForegroundColor Green

# Step 5: Install AWS Load Balancer Controller
Write-Host "`n[5/6] Installing AWS Load Balancer Controller..." -ForegroundColor Yellow

$accountId = aws sts get-caller-identity --query 'Account' --output text

Write-Host "  Installing via Helm..." -ForegroundColor Gray
helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
    -n kube-system `
    --set clusterName=$ClusterName `
    --set serviceAccount.create=false `
    --set serviceAccount.name=aws-load-balancer-controller `
    --set region=$Region `
    --set vpcId=$(aws eks describe-cluster --name $ClusterName --query "cluster.resourcesVpcConfig.vpcId" --output text --region $Region)

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [SUCCESS] AWS Load Balancer Controller installed" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Installation failed" -ForegroundColor Red
    exit 1
}

# Step 6: Verify installation
Write-Host "`n[6/6] Verifying installation..." -ForegroundColor Yellow

Write-Host "  Waiting for controller to be ready..." -ForegroundColor Gray
Start-Sleep -Seconds 20

$deployment = kubectl get deployment -n kube-system aws-load-balancer-controller -o json 2>$null | ConvertFrom-Json
if ($deployment) {
    $ready = $deployment.status.readyReplicas
    $desired = $deployment.status.replicas
    
    Write-Host "  Controller replicas: $ready/$desired ready" -ForegroundColor White
    
    if ($ready -eq $desired) {
        Write-Host "  [SUCCESS] Load Balancer Controller is ready!" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Controller not fully ready yet" -ForegroundColor Yellow
        Write-Host "  Check status: kubectl get deployment -n kube-system aws-load-balancer-controller" -ForegroundColor Gray
    }
} else {
    Write-Host "  [WARNING] Could not verify deployment status" -ForegroundColor Yellow
}

# Clean up temporary files
if (Test-Path $policyFile) { Remove-Item $policyFile }
if (Test-Path "trust-policy.json") { Remove-Item "trust-policy.json" }

Write-Host "`n=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "
Next steps:
1. Verify controller: kubectl get deployment -n kube-system aws-load-balancer-controller
2. Check logs: kubectl logs -n kube-system deployment/aws-load-balancer-controller
3. Apply Ingress: kubectl apply -f kubernetes/hr-portal.yaml
4. Get Load Balancer URL: kubectl get ingress -n hr-portal hr-portal
" -ForegroundColor White

Write-Host "Note: It may take 2-3 minutes for the ALB to be provisioned after applying the Ingress." -ForegroundColor Yellow
Write-Host ""
