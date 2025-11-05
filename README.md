# Case Study 3 - Employee Lifecycle Automation

**Student**: Mehdi Cetinkaya (mehdi6132)  
**Course**: Network & Cloud Architectures  
**Platform**: 100% Google Cloud Platform (GCP)  
**Region**: europe-west4 (Netherlands)

## Overview

This project implements an automated Employee Lifecycle Management system on Google Cloud Platform, demonstrating Zero Trust Architecture, micro-segmentation, and GDPR-compliant data handling. The system automates employee onboarding, offboarding, access management, and audit logging using GCP-native services.

**Key Features:**
- 🔐 **Zero Trust Architecture** - Private networking, least privilege IAM, encrypted data
- 🗄️ **Cloud SQL PostgreSQL** - HA Multi-AZ database with automated backups
- 🌐 **VPC Micro-segmentation** - Isolated subnets for database and application tiers
- 📊 **Cloud Monitoring** - Real-time dashboards and automated alerting
- 🚀 **CI/CD Pipeline** - GitHub Actions with Workload Identity Federation (OIDC)
- 📜 **GDPR Compliance** - Encrypted PII, audit logs, change tracking

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPC: innovatech-vpc (10.100.0.0/16)          │
│                                                                   │
│  ┌──────────────────────────┐  ┌──────────────────────────┐    │
│  │  GKE Subnet (Phase 3)    │  │  Database Subnet         │    │
│  │  10.100.1.0/24           │  │  10.100.2.0/24           │    │
│  │                          │  │                          │    │
│  │  ┌────────────────────┐ │  │  ┌────────────────────┐ │    │
│  │  │ GKE Autopilot      │ │  │  │ Cloud SQL          │ │    │
│  │  │ (Future Phase)     │─┼──┼─▶│ PostgreSQL 15      │ │    │
│  │  └────────────────────┘ │  │  │ HA Multi-AZ        │ │    │
│  │                          │  │  │ Private IP Only    │ │    │
│  └──────────────────────────┘  │  └────────────────────┘ │    │
│                                  └──────────────────────────┘    │
│                                                                   │
│  Firewall Rules: Default Deny, Explicit Allow (Zero Trust)      │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │  Cloud Monitoring       │
              │  - CPU/Memory metrics   │
              │  - Connection tracking  │
              │  - Automated alerts     │
              └─────────────────────────┘
```

## Prerequisites

### Required Tools
- **GCP Account** - Free tier with $300 credits ([Sign up](https://cloud.google.com/free))
- **gcloud CLI** - [Installation guide](https://cloud.google.com/sdk/docs/install)
- **Terraform** - Version 1.6.0 or later ([Download](https://www.terraform.io/downloads))
- **PostgreSQL Client** - psql command-line tool ([Installation](https://www.postgresql.org/download/))
- **Cloud SQL Proxy** - For secure database connections ([Download](https://cloud.google.com/sql/docs/postgres/sql-proxy))

### GCP Permissions
Your GCP account needs the following roles:
- `roles/owner` or `roles/editor` (for initial setup)
- `roles/iam.serviceAccountAdmin` (for service account creation)
- `roles/resourcemanager.projectIamAdmin` (for IAM bindings)

## Deployment Instructions

### Step 1: GCP Project Setup

```bash
# Set your GCP project ID
export PROJECT_ID="your-gcp-project-id"

# Authenticate with GCP
gcloud auth login
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable storage.googleapis.com
```

### Step 2: Create Terraform State Bucket

```bash
# Create GCS bucket for Terraform state
gsutil mb -p $PROJECT_ID -c STANDARD -l europe-west4 gs://${PROJECT_ID}-terraform-state

# Enable versioning for state file protection
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Set lifecycle policy to retain old versions for 30 days
cat > /tmp/lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "isLive": false
        }
      }
    ]
  }
}
EOF
gsutil lifecycle set /tmp/lifecycle.json gs://${PROJECT_ID}-terraform-state
```

### Step 3: Configure Workload Identity Federation for GitHub Actions

```bash
# Create Workload Identity Pool (already in Terraform, but can be pre-created)
gcloud iam workload-identity-pools create github-pool \
    --location="global" \
    --description="GitHub Actions Pool" \
    --display-name="GitHub Actions Pool"

# Create OIDC Provider
gcloud iam workload-identity-pools providers create-oidc github-provider \
    --location="global" \
    --workload-identity-pool="github-pool" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --display-name="GitHub OIDC Provider"

# Get the Workload Identity Provider resource name
gcloud iam workload-identity-pools providers describe github-provider \
    --location="global" \
    --workload-identity-pool="github-pool" \
    --format="value(name)"
```

### Step 4: Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets → Actions):

```
GCP_PROJECT_ID: your-gcp-project-id
WIF_PROVIDER: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider
WIF_SERVICE_ACCOUNT: github-actions@PROJECT_ID.iam.gserviceaccount.com
GCP_TF_STATE_BUCKET: PROJECT_ID-terraform-state
```

### Step 5: Deploy Infrastructure with Terraform

```bash
# Clone the repository
git clone https://github.com/i546927MehdiCetinkaya/casestudy3.git
cd casestudy3/terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project details
nano terraform.tfvars

# Initialize Terraform
terraform init \
    -backend-config="bucket=${PROJECT_ID}-terraform-state" \
    -backend-config="prefix=terraform/state"

# Review the execution plan
terraform plan

# Apply the infrastructure
terraform apply
```

**Expected deployment time**: 10-15 minutes (Cloud SQL creation is the longest step)

### Step 6: Initialize Database

```bash
# Get Cloud SQL connection information
INSTANCE_CONNECTION_NAME=$(terraform output -raw cloudsql_instance_connection_name)
DB_PASSWORD=$(terraform output -raw database_admin_password)

# Download and start Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy
./cloud-sql-proxy $INSTANCE_CONNECTION_NAME --port 5432 &

# Wait for proxy to start
sleep 5

# Create database schema
PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U postgres -d hr_database -f ../migration/mock_data/hr_schema.sql

# Load seed data
PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U postgres -d hr_database -f ../migration/mock_data/seed_data.sql

# Validate data integrity
PGPASSWORD=$DB_PASSWORD psql -h 127.0.0.1 -U postgres -d hr_database -f ../migration/mock_data/validation_queries.sql
```

## Accessing Cloud SQL

### Option 1: Cloud SQL Proxy (Recommended for Development)

```bash
# Start Cloud SQL Proxy
./cloud-sql-proxy <PROJECT>:<REGION>:<INSTANCE> --port 5432

# Connect with psql
PGPASSWORD='<password>' psql -h 127.0.0.1 -U hr_app_user -d hr_database

# Example queries
SELECT COUNT(*) FROM employees WHERE status = 'active';
SELECT * FROM departments;
SELECT * FROM access_logs ORDER BY timestamp DESC LIMIT 10;
```

### Option 2: From GKE (Phase 3)

```yaml
# Application deployment will use Cloud SQL Proxy sidecar
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  serviceAccountName: gke-workload
  containers:
  - name: app
    image: app:latest
    env:
    - name: DB_HOST
      value: "127.0.0.1"
  - name: cloud-sql-proxy
    image: gcr.io/cloud-sql-connectors/cloud-sql-proxy:latest
    args:
    - "--private-ip"
    - "<INSTANCE_CONNECTION_NAME>"
```

### Option 3: Compute Engine VM (Bastion)

```bash
# SSH to Compute Engine instance in the same VPC
gcloud compute ssh bastion-vm --zone europe-west4-a

# Connect directly to Cloud SQL private IP
PGPASSWORD='<password>' psql -h <PRIVATE_IP> -U hr_app_user -d hr_database
```

## Monitoring

### Cloud Monitoring Dashboard

Access the monitoring dashboard:
```bash
terraform output monitoring_dashboard_url
```

**Dashboard Widgets:**
- Cloud SQL CPU utilization (%)
- Cloud SQL memory usage (%)
- Cloud SQL active connections
- Cloud SQL disk usage (GB)
- Cloud SQL replication lag (HA)
- VPC firewall dropped packets

### Alerts

Pre-configured alerts:
- **High CPU** - Alert when CPU > 80% for 5 minutes
- **High Memory** - Alert when memory > 90% for 5 minutes
- **Disk Usage** - Alert when disk > 85%

Configure email notifications:
```bash
# Create notification channel
gcloud alpha monitoring channels create \
    --display-name="Email Notification" \
    --type=email \
    --channel-labels=email_address=your-email@example.com
```

### Logging

```bash
# View Cloud SQL logs
gcloud logging read "resource.type=cloudsql_database" --limit 50 --format json

# View audit logs
gcloud logging read "protoPayload.serviceName=cloudsql.googleapis.com" --limit 50
```

## Cost Management

### Monthly Cost Breakdown (EUR)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| Cloud SQL | db-f1-micro, HA, 20GB SSD | €25-30 |
| VPC | Standard VPC + subnets | €0 |
| Cloud Storage | Terraform state + backups | €0.50 |
| Cloud Monitoring | Dashboard + 3 alerts | €3-5 |
| NAT Gateway | Outbound internet (minimal) | €2-3 |
| **Total** | | **€30-38** |

**Cost Optimization Tips:**
- Use `ZONAL` availability instead of `REGIONAL` for non-prod (saves ~40%)
- Schedule database to stop during non-business hours (dev/test only)
- Use `PD_HDD` instead of `PD_SSD` for lower cost (slower performance)
- Enable auto-scaling to reduce over-provisioning

### Budget Alerts

```bash
# Create budget alert
gcloud billing budgets create \
    --billing-account=BILLING_ACCOUNT_ID \
    --display-name="CS3 Monthly Budget" \
    --budget-amount=50EUR \
    --threshold-rule=percent=50 \
    --threshold-rule=percent=90 \
    --threshold-rule=percent=100
```

## Troubleshooting

### Issue: Terraform apply fails with "quota exceeded"

**Solution:**
```bash
# Check quotas
gcloud compute project-info describe --project=$PROJECT_ID

# Request quota increase
https://console.cloud.google.com/iam-admin/quotas
```

### Issue: Cloud SQL instance won't start

**Solution:**
```bash
# Check Cloud SQL logs
gcloud sql operations list --instance=<INSTANCE_NAME>

# Verify networking
gcloud compute networks subnets describe database-subnet --region=europe-west4
```

### Issue: Cannot connect to Cloud SQL via proxy

**Solution:**
```bash
# Verify proxy is running
ps aux | grep cloud-sql-proxy

# Check IAM permissions
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:cloud-sql-admin@*"

# Test connectivity
nc -zv 127.0.0.1 5432
```

### Issue: Terraform state is locked

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or delete the lock file in GCS
gsutil rm gs://${PROJECT_ID}-terraform-state/terraform/state/default.tflock
```

## Security Considerations

### Zero Trust Implementation
- ✅ Private IP only for Cloud SQL (no public internet access)
- ✅ VPC firewall rules: default deny, explicit allow
- ✅ IAM service accounts with least privilege
- ✅ Encrypted data at rest (AES-256)
- ✅ Encrypted data in transit (TLS 1.3)
- ✅ Audit logging enabled

### GDPR Compliance
- ✅ Encrypted SSN field (base64 mock, use AES-256 in production)
- ✅ Access logs for audit trail
- ✅ Employee history for change tracking
- ✅ Data minimization (only essential fields)
- ⚠️ Implement data retention policies (future)
- ⚠️ Add "right to be forgotten" functionality (future)

## Next Steps

### Phase 2: Application Backend (Planned)
- Deploy Cloud Run or GKE Autopilot
- Implement REST API for employee management
- Add authentication (Firebase Auth or Identity Platform)
- Integrate with Cloud SQL

### Phase 3: GKE Autopilot Deployment (Planned)
- Deploy Kubernetes cluster in gke-subnet
- Configure Workload Identity for Cloud SQL access
- Implement auto-scaling and load balancing
- Add Istio service mesh for advanced traffic management

### Phase 4: Advanced Features (Planned)
- Implement Cloud Functions for automated workflows
- Add Pub/Sub for event-driven architecture
- Integrate with Cloud Scheduler for periodic tasks
- Add Secret Manager for credentials management

## References

- [Cloud SQL PostgreSQL Documentation](https://cloud.google.com/sql/docs/postgres)
- [VPC Network Documentation](https://cloud.google.com/vpc/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Case Study 2 (AWS SOAR)](https://github.com/mehdi6132/casestudy2) - Previous work

## License

This project is for educational purposes as part of Network & Cloud Architectures coursework.

## Author

**Mehdi Cetinkaya**  
Student ID: mehdi6132  
Course: Network & Cloud Architectures  
Institution: [Your Institution]  
Year: 2024