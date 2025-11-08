# kubectl helper script om AWS SSO profile te gebruiken
# Gebruik: .\kubectl-helper.ps1 get nodes

$env:AWS_PROFILE = "fictisb_IsbUsersPS-920120424621"
$env:AWS_REGION = "eu-west-1"

Write-Host "Using AWS Profile: $env:AWS_PROFILE" -ForegroundColor Cyan
Write-Host "Running: kubectl $args`n" -ForegroundColor Yellow

kubectl @args
