# Simplified AWS Load Balancer Controller Installation
# Uses kubectl only, no Helm required

param(
    [string]$ClusterName = "innovatech-employee-lifecycle",
    [string]$Region = "eu-west-1"
)

Write-Host "`n=== AWS Load Balancer Controller Installation (Simplified) ===" -ForegroundColor Cyan

# Get AWS Account ID
$accountId = aws sts get-caller-identity --query 'Account' --output text
$vpcId = aws eks describe-cluster --name $ClusterName --query "cluster.resourcesVpcConfig.vpcId" --output text --region $Region

Write-Host "Account ID: $accountId" -ForegroundColor White
Write-Host "VPC ID: $vpcId" -ForegroundColor White
Write-Host "Region: $Region`n" -ForegroundColor White

# Step 1: Download and create IAM policy
Write-Host "[1/5] Creating IAM Policy..." -ForegroundColor Yellow
$policyUrl = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json"
Invoke-WebRequest -Uri $policyUrl -OutFile "iam_policy.json"

$policyCheck = aws iam get-policy --policy-arn "arn:aws:iam::${accountId}:policy/AWSLoadBalancerControllerIAMPolicy" 2>$null
if (-not $policyCheck) {
    aws iam create-policy `
        --policy-name AWSLoadBalancerControllerIAMPolicy `
        --policy-document file://iam_policy.json | Out-Null
    Write-Host "  [SUCCESS] IAM Policy created" -ForegroundColor Green
} else {
    Write-Host "  [INFO] IAM Policy already exists" -ForegroundColor Gray
}

# Step 2: Create IAM role and service account
Write-Host "`n[2/5] Creating IAM Role and Service Account..." -ForegroundColor Yellow

# Get OIDC provider
$oidcProvider = aws eks describe-cluster --name $ClusterName --query "cluster.identity.oidc.issuer" --output text --region $Region
$oidcId = $oidcProvider -replace "https://oidc.eks.$Region.amazonaws.com/id/", ""

Write-Host "  OIDC ID: $oidcId" -ForegroundColor Gray

# Create trust policy
$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${accountId}:oidc-provider/oidc.eks.${Region}.amazonaws.com/id/${oidcId}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${Region}.amazonaws.com/id/${oidcId}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
          "oidc.eks.${Region}.amazonaws.com/id/${oidcId}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
"@

$trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding UTF8

# Create or update role
$roleName = "AmazonEKSLoadBalancerControllerRole"
$roleCheck = aws iam get-role --role-name $roleName 2>$null
if (-not $roleCheck) {
    aws iam create-role `
        --role-name $roleName `
        --assume-role-policy-document file://trust-policy.json | Out-Null
    Write-Host "  [SUCCESS] IAM Role created" -ForegroundColor Green
} else {
    Write-Host "  [INFO] IAM Role already exists" -ForegroundColor Gray
}

# Attach policy to role
aws iam attach-role-policy `
    --role-name $roleName `
    --policy-arn "arn:aws:iam::${accountId}:policy/AWSLoadBalancerControllerIAMPolicy" 2>$null

Write-Host "  [SUCCESS] Policy attached to role" -ForegroundColor Green

# Step 3: Create Kubernetes Service Account
Write-Host "`n[3/5] Creating Kubernetes Service Account..." -ForegroundColor Yellow

$serviceAccountYaml = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${accountId}:role/AmazonEKSLoadBalancerControllerRole
"@

$serviceAccountYaml | Out-File -FilePath "lb-controller-serviceaccount.yaml" -Encoding UTF8
kubectl apply -f lb-controller-serviceaccount.yaml

Write-Host "  [SUCCESS] Service Account created" -ForegroundColor Green

# Step 4: Install cert-manager
Write-Host "`n[4/5] Installing cert-manager..." -ForegroundColor Yellow
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml 2>$null

Write-Host "  Waiting for cert-manager to be ready (30 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

Write-Host "  [SUCCESS] cert-manager installed" -ForegroundColor Green

# Step 5: Install AWS Load Balancer Controller
Write-Host "`n[5/5] Installing AWS Load Balancer Controller..." -ForegroundColor Yellow

# Download controller manifest
$controllerUrl = "https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.0/v2_7_0_full.yaml"
Invoke-WebRequest -Uri $controllerUrl -OutFile "lb-controller.yaml"

# Update cluster name in manifest
(Get-Content "lb-controller.yaml") `
    -replace '--cluster-name=your-cluster-name', "--cluster-name=$ClusterName" `
    -replace 'ServiceAccount', '# ServiceAccount (already created)' `
    | Set-Content "lb-controller-modified.yaml"

# Remove the ServiceAccount section (we already created it)
$content = Get-Content "lb-controller-modified.yaml" -Raw
$content = $content -replace '(?ms)---\s*# ServiceAccount.*?---', '---'
$content | Out-File "lb-controller-modified.yaml" -Encoding UTF8

kubectl apply -f lb-controller-modified.yaml

Write-Host "  Waiting for controller to be ready (30 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Verify installation
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
$deployment = kubectl get deployment -n kube-system aws-load-balancer-controller -o json 2>$null | ConvertFrom-Json

if ($deployment) {
    $ready = $deployment.status.readyReplicas
    $desired = $deployment.status.replicas
    
    Write-Host "Controller replicas: $ready/$desired" -ForegroundColor White
    
    if ($ready -eq $desired -and $ready -gt 0) {
        Write-Host "[SUCCESS] AWS Load Balancer Controller is running!" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Controller not fully ready yet. Check logs:" -ForegroundColor Yellow
        Write-Host "kubectl logs -n kube-system deployment/aws-load-balancer-controller" -ForegroundColor Gray
    }
    
    # Show controller pods
    Write-Host "`nController Pods:" -ForegroundColor Cyan
    kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
} else {
    Write-Host "[WARNING] Could not find controller deployment" -ForegroundColor Yellow
}

# Clean up temporary files
Remove-Item "iam_policy.json" -ErrorAction SilentlyContinue
Remove-Item "trust-policy.json" -ErrorAction SilentlyContinue
Remove-Item "lb-controller-serviceaccount.yaml" -ErrorAction SilentlyContinue
Remove-Item "lb-controller.yaml" -ErrorAction SilentlyContinue
Remove-Item "lb-controller-modified.yaml" -ErrorAction SilentlyContinue

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Verify Ingress creation: kubectl get ingress -n hr-portal" -ForegroundColor White
Write-Host "2. Get ALB URL: kubectl get ingress hr-portal -n hr-portal -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'" -ForegroundColor White
Write-Host "3. Wait 2-3 minutes for ALB provisioning" -ForegroundColor White
Write-Host "4. Test API: curl http://<ALB-URL>/api/employees" -ForegroundColor White
Write-Host ""
