# Auto-refresh AWS Credentials and Start Backend
# This script keeps credentials fresh and backend running

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  AUTO-REFRESH BACKEND WITH DYNAMODB" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$backendPath = "C:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3\applications\hr-portal\backend"

# Function to check if credentials are valid
function Test-AWSCredentials {
    try {
        $null = aws sts get-caller-identity 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Function to get fresh credentials
function Get-FreshCredentials {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "  CREDENTIALS VERLOPEN - REFRESH NODIG" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Plak hieronder je NIEUWE AWS credentials:" -ForegroundColor Cyan
    Write-Host "(krijg je van AWS Console → IAM → Security Credentials)" -ForegroundColor Gray
    Write-Host ""
    
    aws configure
    
    if (Test-AWSCredentials) {
        Write-Host ""
        Write-Host "Credentials bijgewerkt!" -ForegroundColor Green
        return $true
    } else {
        Write-Host ""
        Write-Host "Credentials werken nog steeds niet!" -ForegroundColor Red
        return $false
    }
}

# Check credentials
Write-Host "Checking AWS credentials..." -ForegroundColor Yellow

if (-not (Test-AWSCredentials)) {
    Write-Host "Credentials zijn verlopen!" -ForegroundColor Red
    
    if (-not (Get-FreshCredentials)) {
        Write-Host ""
        Write-Host "Kan niet starten zonder geldige credentials." -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternatief: Gebruik mock server" -ForegroundColor Yellow
        Write-Host "  cd '$backendPath'" -ForegroundColor Gray
        Write-Host "  npm run mock" -ForegroundColor White
        Write-Host ""
        exit 1
    }
} else {
    Write-Host "Credentials zijn geldig!" -ForegroundColor Green
}

# Navigate to backend
Set-Location $backendPath

# Set environment variables
Write-Host ""
Write-Host "Setting environment variables..." -ForegroundColor Yellow
$env:PORT = "3001"
$env:NODE_ENV = "production"
$env:AWS_REGION = "eu-west-1"
$env:DYNAMODB_TABLE = "innovatech-employees"
$env:DYNAMODB_WORKSPACES_TABLE = "innovatech-employees-workspaces"

Write-Host "  PORT = 3001" -ForegroundColor Green
Write-Host "  AWS_REGION = eu-west-1" -ForegroundColor Green
Write-Host "  DYNAMODB_TABLE = innovatech-employees" -ForegroundColor Green

# Start backend
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "  STARTING BACKEND WITH DYNAMODB" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend: http://localhost:3001" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data wordt opgeslagen in AWS DynamoDB!" -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: Als credentials verlopen (na paar uur):" -ForegroundColor Yellow
Write-Host "      - Stop backend (Ctrl+C)" -ForegroundColor Gray
Write-Host "      - Run dit script opnieuw" -ForegroundColor Gray
Write-Host "      - Script vraagt om nieuwe credentials" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Cyan
Write-Host ""

npm start
