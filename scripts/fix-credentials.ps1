Write-Host ""
Write-Host "=========================================" -ForegroundColor Red
Write-Host "  CREDENTIAL PROBLEEM GEVONDEN!          " -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Red
Write-Host ""
Write-Host "Het probleem: Je hebt de PowerShell COMMANDS geplakt" -ForegroundColor Yellow
Write-Host "in plaats van alleen de VALUES!" -ForegroundColor Yellow
Write-Host ""
Write-Host "VERKEERD (wat je deed):" -ForegroundColor Red
Write-Host '  $Env:AWS_ACCESS_KEY_ID="ASIA5MO3TPCWYS4J26M3"' -ForegroundColor Red
Write-Host '  $Env:AWS_SECRET_ACCESS_KEY="..."' -ForegroundColor Red
Write-Host ""
Write-Host "GOED (wat je moet doen):" -ForegroundColor Green
Write-Host "  ASIA5MO3TPCWYS4J26M3" -ForegroundColor Green
Write-Host "  t5YNiZIkCLmI++2xXfBO7zEMqH/5gREg7B6PzrOS" -ForegroundColor Green
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  NIEUWE CREDENTIALS INVOEREN" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ik ga je nu stap voor stap vragen om de credentials." -ForegroundColor White
Write-Host "Plak ALLEEN de waarde, niet het hele command!" -ForegroundColor Yellow
Write-Host ""

# Ask for Access Key ID
Write-Host "1. AWS Access Key ID" -ForegroundColor Cyan
Write-Host "   (bijv: ASIA5MO3TPCWYS4J26M3)" -ForegroundColor Gray
$accessKeyId = Read-Host "   Plak hier"
$accessKeyId = $accessKeyId.Trim()

# Validate it doesn't contain PowerShell syntax
if ($accessKeyId -match '\$Env:' -or $accessKeyId -match '="') {
    Write-Host ""
    Write-Host "STOP! Je plakte het hele command!" -ForegroundColor Red
    Write-Host "Probeer opnieuw en plak ALLEEN de waarde tussen de quotes." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""

# Ask for Secret Access Key
Write-Host "2. AWS Secret Access Key" -ForegroundColor Cyan
Write-Host "   (bijv: t5YNiZIkCLmI++2xXfBO7zEMqH/5gREg7B6PzrOS)" -ForegroundColor Gray
$secretAccessKey = Read-Host "   Plak hier"
$secretAccessKey = $secretAccessKey.Trim()

# Validate it doesn't contain PowerShell syntax
if ($secretAccessKey -match '\$Env:' -or $secretAccessKey -match '="') {
    Write-Host ""
    Write-Host "STOP! Je plakte het hele command!" -ForegroundColor Red
    Write-Host "Probeer opnieuw en plak ALLEEN de waarde tussen de quotes." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""

# Ask for Session Token
Write-Host "3. AWS Session Token" -ForegroundColor Cyan
Write-Host "   (de HELE lange string die begint met IQoJb3JpZ2luX2VjE...)" -ForegroundColor Gray
$sessionToken = Read-Host "   Plak hier"
$sessionToken = $sessionToken.Trim()

# Validate it doesn't contain PowerShell syntax
if ($sessionToken -match '\$Env:' -or $sessionToken -match '="') {
    Write-Host ""
    Write-Host "STOP! Je plakte het hele command!" -ForegroundColor Red
    Write-Host "Probeer opnieuw en plak ALLEEN de waarde tussen de quotes." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Credentials ontvangen! Even testen..." -ForegroundColor Green
Write-Host ""

# Set the credentials
$env:AWS_ACCESS_KEY_ID = $accessKeyId
$env:AWS_SECRET_ACCESS_KEY = $secretAccessKey
$env:AWS_SESSION_TOKEN = $sessionToken
$env:AWS_REGION = "eu-west-1"

# Test the credentials
Write-Host "Testing AWS credentials..." -ForegroundColor Yellow
$testResult = aws sts get-caller-identity 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  SUCCES! CREDENTIALS WERKEN!          " -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "AWS Identity:" -ForegroundColor Cyan
    Write-Host $testResult
    Write-Host ""
    Write-Host "Nu de backend starten met deze credentials..." -ForegroundColor Green
    Write-Host ""
    
    # Navigate to backend directory
    Set-Location "C:\Users\Mehdi\OneDrive - Office 365 Fontys\fontys\semester3\case-study-3\casestudy3\applications\hr-portal\backend"
    
    # Set environment variables for the backend
    $env:PORT = "3001"
    $env:DYNAMODB_TABLE = "innovatech-employees"
    $env:DYNAMODB_WORKSPACES_TABLE = "innovatech-employees-workspaces"
    
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  BACKEND STARTING..." -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Backend: http://localhost:3001" -ForegroundColor Green
    Write-Host "Frontend: http://localhost:3000" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    # Start the backend
    npm start
    
} else {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "  CREDENTIALS WERKEN NOG NIET          " -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error:" -ForegroundColor Yellow
    Write-Host $testResult
    Write-Host ""
    Write-Host "Mogelijke oorzaken:" -ForegroundColor Yellow
    Write-Host "  1. Credentials zijn verlopen" -ForegroundColor White
    Write-Host "  2. Verkeerde credentials geplakt" -ForegroundColor White
    Write-Host "  3. Nog steeds PowerShell syntax erin" -ForegroundColor White
    Write-Host ""
    Write-Host "Probeer opnieuw met VERSE credentials!" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
