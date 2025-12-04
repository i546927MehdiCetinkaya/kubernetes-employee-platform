# Script to update Kubernetes manifests with Terraform outputs
# This ensures that the Ingress resources have the correct ARNs and IDs for Zero Trust

param (
    [string]$OutputsFile = ""
)

$ErrorActionPreference = "Stop"

Write-Host "Fetching Terraform outputs..."

if ($OutputsFile -and (Test-Path $OutputsFile)) {
    Write-Host "Reading outputs from file: $OutputsFile"
    $jsonContent = Get-Content $OutputsFile -Raw
    $tfOutput = $jsonContent | ConvertFrom-Json
} else {
    Write-Host "Running 'terraform output'..."
    Set-Location "$PSScriptRoot/../terraform"
    $tfOutput = terraform output -json | ConvertFrom-Json
}

# Extract values
$userPoolArn = $tfOutput.cognito_user_pool_arn.value
$userPoolId = $tfOutput.cognito_user_pool_id.value
$userPoolDomain = $tfOutput.cognito_user_pool_domain.value
$hrPortalClientId = $tfOutput.cognito_hr_portal_client_id.value
$workspaceClientId = $tfOutput.cognito_workspace_client_id.value
$hrPortalSgId = $tfOutput.hr_portal_internal_alb_sg_id.value
$workspaceSgId = $tfOutput.workspace_internal_alb_sg_id.value
$awsRegion = "eu-west-1" # Or fetch from var

# Define file paths
$hrPortalManifest = "$PSScriptRoot/../kubernetes/hr-portal.yaml"
$workspacesManifest = "$PSScriptRoot/../kubernetes/workspaces.yaml"

Write-Host "Updating HR Portal manifest..."
$hrContent = Get-Content $hrPortalManifest -Raw

# Replace placeholders
$hrContent = $hrContent -replace "YOUR-USER-POOL-ID", $userPoolId
$hrContent = $hrContent -replace "YOUR-CLIENT-ID", $hrPortalClientId
$hrContent = $hrContent -replace "YOUR-DOMAIN", $userPoolDomain
$hrContent = $hrContent -replace "hr-portal-internal-alb-sg", $hrPortalSgId
# Note: Certificate ARN should be manually set or fetched if managed by Terraform
# $hrContent = $hrContent -replace "YOUR-CERT-ID", "..." 

Set-Content -Path $hrPortalManifest -Value $hrContent
Write-Host "HR Portal manifest updated."

Write-Host "Updating Workspaces manifest..."
$wsContent = Get-Content $workspacesManifest -Raw

# Replace placeholders
$wsContent = $wsContent -replace "YOUR-USER-POOL-ID", $userPoolId
$wsContent = $wsContent -replace "YOUR-WORKSPACE-CLIENT-ID", $workspaceClientId
$wsContent = $wsContent -replace "YOUR-DOMAIN", $userPoolDomain
$wsContent = $wsContent -replace "workspace-internal-alb-sg", $workspaceSgId

Set-Content -Path $workspacesManifest -Value $wsContent
Write-Host "Workspaces manifest updated."

Write-Host "Configuration update complete. You can now apply the manifests with kubectl."
