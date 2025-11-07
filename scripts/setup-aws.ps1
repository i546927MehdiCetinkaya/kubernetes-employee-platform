# AWS Setup Helper
# Dit script helpt je AWS credentials te configureren

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  AWS CREDENTIALS SETUP" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Je AWS credentials zijn niet (correct) geconfigureerd." -ForegroundColor Yellow
Write-Host ""
Write-Host "Je hebt nodig:" -ForegroundColor Cyan
Write-Host "  1. AWS Access Key ID" -ForegroundColor White
Write-Host "  2. AWS Secret Access Key" -ForegroundColor White
Write-Host "  3. Default region (bijv: eu-west-1)" -ForegroundColor White
Write-Host ""

Write-Host "Waar kun je deze krijgen?" -ForegroundColor Yellow
Write-Host "  - Van je AWS administrator/docent" -ForegroundColor Gray
Write-Host "  - Of via AWS Console → IAM → Users → Security credentials" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Wil je AWS credentials nu configureren? (y/n)"

if ($choice -eq "y" -or $choice -eq "Y") {
    Write-Host "`nStarting AWS configuration..." -ForegroundColor Green
    Write-Host "Je wordt gevraagd om in te voeren:" -ForegroundColor Gray
    Write-Host ""
    
    aws configure
    
    Write-Host "`n=========================================" -ForegroundColor Cyan
    Write-Host "Testing credentials..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
        Write-Host "✓ SUCCESS! Credentials are configured correctly" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your AWS Identity:" -ForegroundColor Cyan
        Write-Host "  Account: $($identity.Account)" -ForegroundColor White
        Write-Host "  User ARN: $($identity.Arn)" -ForegroundColor White
        Write-Host "  User ID: $($identity.UserId)" -ForegroundColor White
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Check DynamoDB: .\scripts\check-dynamodb.ps1" -ForegroundColor White
        Write-Host "  2. Start real backend: .\scripts\start-backend-real.ps1" -ForegroundColor White
        Write-Host ""
    } catch {
        Write-Host "✗ FAILED! Credentials are not working" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please:" -ForegroundColor Yellow
        Write-Host "  - Check if your credentials are correct" -ForegroundColor White
        Write-Host "  - Ask your administrator for valid credentials" -ForegroundColor White
        Write-Host "  - Try again: .\scripts\setup-aws.ps1" -ForegroundColor White
        Write-Host ""
    }
} else {
    Write-Host "`nOke, geen probleem!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Je kunt nu 2 dingen doen:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1: Gebruik de MOCK SERVER (aanbevolen voor nu)" -ForegroundColor Green
    Write-Host "  - Werkt zonder AWS credentials" -ForegroundColor Gray
    Write-Host "  - Perfect voor lokaal testen" -ForegroundColor Gray
    Write-Host "  - Start met: .\scripts\start-backend.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Configureer AWS later" -ForegroundColor Yellow
    Write-Host "  - Vraag credentials aan je docent/admin" -ForegroundColor Gray
    Write-Host "  - Run dit script opnieuw: .\scripts\setup-aws.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Voor nu blijf je de mock server gebruiken - en dat werkt perfect! 🎉" -ForegroundColor Green
    Write-Host ""
}
