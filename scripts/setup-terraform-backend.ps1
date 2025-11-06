# Setup Terraform S3 Backend
# Run this ONCE before enabling the backend in terraform/backend.tf

$ErrorActionPreference = "Stop"
$BUCKET_NAME = "innovatech-terraform-state-920120424621"
$TABLE_NAME = "terraform-state-lock"
$REGION = "eu-west-1"

Write-Host "=== Setting Up Terraform Backend ===" -ForegroundColor Cyan
Write-Host ""

# Check AWS credentials
Write-Host "Checking AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "✅ Authenticated as: $($identity.UserId)" -ForegroundColor Green
    Write-Host "   Account: $($identity.Account)" -ForegroundColor Gray
} catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "Run: .\scripts\refresh-credentials.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Create S3 bucket for state
Write-Host "Creating S3 bucket: $BUCKET_NAME..." -ForegroundColor Yellow
$ErrorActionPreference = "Continue"
$bucketCheck = aws s3api head-bucket --bucket $BUCKET_NAME --region $REGION 2>&1
$bucketExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($bucketExitCode -eq 0) {
    Write-Host "ℹ️  Bucket already exists" -ForegroundColor Gray
} else {
    $createResult = aws s3api create-bucket `
        --bucket $BUCKET_NAME `
        --region $REGION `
        --create-bucket-configuration LocationConstraint=$REGION 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ S3 bucket created" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create S3 bucket" -ForegroundColor Red
        Write-Host "Error: $createResult" -ForegroundColor Red
        exit 1
    }
}

# Enable versioning
Write-Host "Enabling versioning on S3 bucket..." -ForegroundColor Yellow
aws s3api put-bucket-versioning `
    --bucket $BUCKET_NAME `
    --versioning-configuration Status=Enabled `
    --region $REGION

Write-Host "✅ Versioning enabled" -ForegroundColor Green

# Enable encryption
Write-Host "Enabling encryption on S3 bucket..." -ForegroundColor Yellow
aws s3api put-bucket-encryption `
    --bucket $BUCKET_NAME `
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' `
    --region $REGION

Write-Host "✅ Encryption enabled" -ForegroundColor Green

# Block public access
Write-Host "Blocking public access..." -ForegroundColor Yellow
aws s3api put-public-access-block `
    --bucket $BUCKET_NAME `
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }' `
    --region $REGION

Write-Host "✅ Public access blocked" -ForegroundColor Green

Write-Host ""

# Create DynamoDB table for state locking
Write-Host "Creating DynamoDB table: $TABLE_NAME..." -ForegroundColor Yellow
$ErrorActionPreference = "Continue"
$tableCheck = aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION 2>&1
$tableExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($tableExitCode -eq 0) {
    Write-Host "ℹ️  Table already exists" -ForegroundColor Gray
} else {
    aws dynamodb create-table `
        --table-name $TABLE_NAME `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $REGION | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ DynamoDB table created" -ForegroundColor Green
        Write-Host "   Waiting for table to be active..." -ForegroundColor Gray
        aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION
        Write-Host "   ✅ Table is active" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create DynamoDB table" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Backend Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "✅ S3 Bucket: $BUCKET_NAME" -ForegroundColor Green
Write-Host "   - Versioning: Enabled" -ForegroundColor Gray
Write-Host "   - Encryption: Enabled" -ForegroundColor Gray
Write-Host "   - Public Access: Blocked" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ DynamoDB Table: $TABLE_NAME" -ForegroundColor Green
Write-Host "   - Billing: Pay-per-request" -ForegroundColor Gray
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Uncomment the backend config in terraform/backend.tf" -ForegroundColor White
Write-Host "2. Run: cd terraform && terraform init -migrate-state" -ForegroundColor White
Write-Host "3. Commit and push changes" -ForegroundColor White
Write-Host "4. Deploy workflows will now use persistent state!" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT: Don't delete the S3 bucket or DynamoDB table!" -ForegroundColor Yellow
Write-Host "   They contain your Terraform state." -ForegroundColor Yellow
