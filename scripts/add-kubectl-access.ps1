# Script to add AWS SSO role to EKS cluster aws-auth ConfigMap
# This allows your local kubectl to access the EKS cluster

param(
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "innovatech-employee-lifecycle",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "eu-west-1",
    
    [Parameter(Mandatory=$false)]
    [string]$Profile = "fictisb_IsbUsersPS-920120424621"
)

$env:AWS_PROFILE = $Profile

Write-Host "`n=== EKS Cluster Access Script ===" -ForegroundColor Cyan
Write-Host "Cluster: $ClusterName" -ForegroundColor White
Write-Host "Region: $Region" -ForegroundColor White
Write-Host "Profile: $Profile`n" -ForegroundColor White

# Get current SSO role ARN
Write-Host "Step 1: Getting your SSO role ARN..." -ForegroundColor Yellow
$callerIdentity = aws sts get-caller-identity --query 'Arn' --output text
$roleArn = $callerIdentity -replace 'sts::(\d+):assumed-role/', 'iam::$1:role/' -replace '/.*$', ''
Write-Host "  Role ARN: $roleArn" -ForegroundColor Green

# Create temporary patch file for aws-auth ConfigMap
Write-Host "`nStep 2: Creating aws-auth ConfigMap patch..." -ForegroundColor Yellow

$awsAuthPatch = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $roleArn
      username: admin:{{SessionName}}
      groups:
        - system:masters
"@

$patchFile = "$PSScriptRoot\aws-auth-patch.yaml"
$awsAuthPatch | Out-File -FilePath $patchFile -Encoding utf8 -Force
Write-Host "  Patch file created: $patchFile" -ForegroundColor Green

# Show the patch content
Write-Host "`nConfigMap patch content:" -ForegroundColor Cyan
Write-Host $awsAuthPatch -ForegroundColor Gray

Write-Host "`n=== MANUAL STEPS REQUIRED ===" -ForegroundColor Red
Write-Host @"

Je lokale machine heeft geen kubectl toegang, dus we moeten dit via GitHub Actions doen.

OPTIE 1: Via GitHub Actions (AANBEVOLEN)
=========================================
1. Voeg dit bestand toe aan repository: .github/workflows/add-kubectl-access.yml

2. Commit en push naar GitHub

3. Run de workflow handmatig in GitHub Actions

4. Daarna werkt kubectl lokaal


OPTIE 2: Via AWS Console
=========================
1. Ga naar AWS Console → EKS → innovatech-employee-lifecycle
2. Access → Manage access
3. Add entry:
   - Type: IAM role
   - ARN: $roleArn
   - Access scope: Cluster
   - Policy: AmazonEKSClusterAdminPolicy


Wil je dat ik de GitHub Actions workflow aanmaak?
"@ -ForegroundColor Yellow
