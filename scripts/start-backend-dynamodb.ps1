# Start Real Backend with DynamoDB
# This starts the backend connected to AWS DynamoDB

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  ECHTE BACKEND - MET DYNAMODB" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$backendPath = "applications\hr-portal\backend"

if (-not (Test-Path $backendPath)) {
    Write-Host "[ERROR] Backend directory not found!" -ForegroundColor Red
    exit 1
}

Set-Location $backendPath

# Set environment variables
Write-Host "[1/3] Setting environment variables..." -ForegroundColor Yellow
$env:PORT = "3001"
$env:NODE_ENV = "production"
$env:AWS_REGION = "eu-west-1"
$env:DYNAMODB_TABLE = "innovatech-employees"
$env:DYNAMODB_WORKSPACES_TABLE = "innovatech-employees-workspaces"

Write-Host "      PORT = 3001" -ForegroundColor Green
Write-Host "      AWS_REGION = eu-west-1" -ForegroundColor Green
Write-Host "      DYNAMODB_TABLE = innovatech-employees" -ForegroundColor Green
Write-Host "      DYNAMODB_WORKSPACES_TABLE = innovatech-employees-workspaces" -ForegroundColor Green

# Check dependencies
Write-Host ""
Write-Host "[2/3] Checking dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "      Installing dependencies..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Failed to install dependencies!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      Dependencies installed" -ForegroundColor Green
}

# Start backend
Write-Host ""
Write-Host "[3/3] Starting REAL backend..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  REAL BACKEND - CONNECTED TO AWS" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API: http://localhost:3001" -ForegroundColor Green
Write-Host ""
Write-Host "Connected to:" -ForegroundColor Cyan
Write-Host "  - AWS DynamoDB (eu-west-1)" -ForegroundColor Green
Write-Host "  - Table: innovatech-employees" -ForegroundColor Green
Write-Host "  - Table: innovatech-employees-workspaces" -ForegroundColor Green
Write-Host ""
Write-Host "Data is now PERSISTENT!" -ForegroundColor Green
Write-Host "Employees created via UI will be saved to DynamoDB" -ForegroundColor Gray
Write-Host ""
Write-Host "NOTE: Workspace provisioning requires Kubernetes" -ForegroundColor Yellow
Write-Host "      Employees will be created, but workspace errors are expected" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Cyan
Write-Host ""

npm start
