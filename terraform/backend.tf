# Terraform S3 Backend Configuration
# This stores Terraform state in S3 so it persists between workflow runs

terraform {
  backend "s3" {
    bucket         = "innovatech-terraform-state-920120424621"
    key            = "employee-lifecycle/terraform.tfstate"
    region         = "eu-west-1"
    
    # DynamoDB table for state locking (prevents concurrent modifications)
    dynamodb_table = "terraform-state-lock"
    
    # Encrypt state file at rest
    encrypt        = true
    
    # Note: Create the S3 bucket and DynamoDB table before enabling this!
    # See: scripts/setup-terraform-backend.ps1
  }
}
