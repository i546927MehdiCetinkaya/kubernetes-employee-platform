# Quick Deployment Guide for Case Study 3

This guide provides step-by-step instructions to deploy the GCP infrastructure for your Case Study 3 project.

## Prerequisites

Before you begin, ensure you have:
- [ ] GCP account with $300 free credits
- [ ] Active GCP project
- [ ] Billing enabled on your project
- [ ] `gcloud` CLI installed and authenticated
- [ ] GitHub account with access to this repository

## Step 1: Set Up GCP Project (5 minutes)

```bash
# Set your project ID
export PROJECT_ID="your-project-id-here"

# Authenticate and set project
gcloud auth login
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
    compute.googleapis.com \
    sqladmin.googleapis.com \
    servicenetworking.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com \
    monitoring.googleapis.com \
    storage.googleapis.com \
    iamcredentials.googleapis.com
```

## Step 2: Create Terraform State Bucket (2 minutes)

```bash
# Create bucket for Terraform state
gsutil mb -p $PROJECT_ID -c STANDARD -l europe-west4 gs://${PROJECT_ID}-terraform-state

# Enable versioning (important for state file protection)
gsutil versioning set on gs://${PROJECT_ID}-terraform-state
```

## Step 3: Set Up Workload Identity Federation (10 minutes)

This enables GitHub Actions to authenticate to GCP without service account keys.

```bash
# Get your project number
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# The Workload Identity Pool and Provider will be created by Terraform
# But we need the resource names for GitHub secrets

# After Terraform creates them, get the provider name:
WIF_PROVIDER="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"

# Service account email (will be created by Terraform)
WIF_SERVICE_ACCOUNT="github-actions@${PROJECT_ID}.iam.gserviceaccount.com"
```

## Step 4: Configure GitHub Secrets (5 minutes)

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
1. **GCP_PROJECT_ID**: `your-project-id`
2. **WIF_PROVIDER**: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider`
3. **WIF_SERVICE_ACCOUNT**: `github-actions@PROJECT_ID.iam.gserviceaccount.com`
4. **GCP_TF_STATE_BUCKET**: `PROJECT_ID-terraform-state`

## Step 5: Deploy Infrastructure (15 minutes)

### Option A: Via GitHub Actions (Recommended)

1. Push changes to `main` branch
2. GitHub Actions will automatically:
   - Validate Terraform code
   - Run security scans
   - Deploy infrastructure
3. Monitor progress in the Actions tab

### Option B: Manual Deployment

```bash
# Clone repository
git clone https://github.com/i546927MehdiCetinkaya/casestudy3.git
cd casestudy3/terraform

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project ID
nano terraform.tfvars

# Initialize Terraform
terraform init \
    -backend-config="bucket=${PROJECT_ID}-terraform-state" \
    -backend-config="prefix=terraform/state"

# Review the plan
terraform plan

# Apply (this takes ~15 minutes for Cloud SQL)
terraform apply
```

## Step 6: Initialize Database (5 minutes)

```bash
# Get connection info
INSTANCE_CONNECTION=$(terraform output -raw cloudsql_instance_connection_name)
DB_PASSWORD=$(terraform output -raw database_admin_password)

# Download Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy

# Start proxy in background
./cloud-sql-proxy $INSTANCE_CONNECTION --port 5432 &

# Wait for proxy to start
sleep 5

# Initialize schema
PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U postgres -d hr_database \
    -f ../migration/mock_data/hr_schema.sql

# Load seed data
PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U postgres -d hr_database \
    -f ../migration/mock_data/seed_data.sql

# Validate data
PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U postgres -d hr_database \
    -f ../migration/mock_data/validation_queries.sql
```

## Step 7: Verify Deployment (5 minutes)

### Check Cloud SQL Instance
```bash
# List instances
gcloud sql instances list

# Get instance details
gcloud sql instances describe $(terraform output -raw cloudsql_instance_name)
```

### Access Monitoring Dashboard
```bash
# Get dashboard URL
terraform output monitoring_dashboard_url

# Or open directly
echo "https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT_ID"
```

### Test Database Connection
```bash
# Query employee count
PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U postgres -d hr_database \
    -c "SELECT COUNT(*) FROM employees WHERE status = 'active';"
```

## Troubleshooting

### Issue: API not enabled
```bash
# Re-run the API enable commands from Step 1
gcloud services enable <API_NAME>
```

### Issue: Permission denied
```bash
# Verify you have required roles
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:user:YOUR_EMAIL"
```

### Issue: Terraform state locked
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue: Cloud SQL connection timeout
```bash
# Check if proxy is running
ps aux | grep cloud-sql-proxy

# Verify network connectivity
gcloud compute networks describe innovatech-vpc
```

## Cost Monitoring

### Set Budget Alert
```bash
BILLING_ACCOUNT=$(gcloud billing accounts list --format="value(name)" --limit=1)

gcloud billing budgets create \
    --billing-account=$BILLING_ACCOUNT \
    --display-name="CS3 Budget" \
    --budget-amount=50EUR \
    --threshold-rule=percent=50 \
    --threshold-rule=percent=90
```

### View Current Costs
```bash
# View billing in console
echo "https://console.cloud.google.com/billing?project=$PROJECT_ID"
```

## Cleanup (When Done)

⚠️ **WARNING**: This will delete all resources and data!

```bash
# Destroy all infrastructure
cd terraform
terraform destroy

# Delete state bucket
gsutil -m rm -r gs://${PROJECT_ID}-terraform-state

# Disable APIs (optional)
gcloud services disable compute.googleapis.com
```

## Next Steps

1. ✅ Infrastructure deployed
2. ✅ Database initialized
3. ⏭️ Phase 2: Deploy application backend
4. ⏭️ Phase 3: GKE Autopilot cluster
5. ⏭️ Phase 4: CI/CD for application

## Support

- **Documentation**: See README.md and ARCHITECTURE.md
- **Issues**: Create GitHub issue
- **GCP Support**: https://cloud.google.com/support

## Estimated Deployment Time

- GCP Setup: 5 minutes
- Terraform State: 2 minutes
- Workload Identity: 10 minutes
- GitHub Secrets: 5 minutes
- Infrastructure Deploy: 15 minutes
- Database Init: 5 minutes
- Verification: 5 minutes

**Total: ~45 minutes** (most time is Cloud SQL creation)
