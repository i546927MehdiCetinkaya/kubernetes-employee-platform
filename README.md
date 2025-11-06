# Employee Lifecycle Automation & Virtual Workspaces on AWS EKS

## 🎯 Project Overview

**Innovatech Solutions** - End-to-End Employee Lifecycle Automation with Virtual Workspaces on AWS EKS using Zero Trust Architecture.

This project delivers a fully automated employee lifecycle management solution that includes:
- Automated employee onboarding and offboarding
- Virtual workspace provisioning (VS Code in browser)
- Zero Trust security architecture
- Kubernetes-based infrastructure on AWS EKS
- Infrastructure as Code with Terraform
- DynamoDB for employee data storage
- Secure VPC endpoints for private AWS service connectivity

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Guide](#deployment-guide)
- [Usage](#usage)
  - [Getting Access Information](#getting-access-information)
  - [HR Portal Access](#hr-portal-access)
  - [Employee Management](#-employee-management)
  - [Workspace Access](#️-workspace-access)
  - [Monitoring & Operations](#-monitoring--operations)
  - [CI/CD Workflows](#-cicd-workflows)
  - [Security Operations](#️-security-operations)
  - [Cost Monitoring](#-cost-monitoring)
- [Security](#security)
- [Cost Management](#cost-management)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Quick Reference](#-quick-reference)
- [FAQ](#-faq)
- [Contributing](#contributing)

---

## 🎬 Getting Started Tutorial

### 5-Minute Quickstart

**1. Deploy via GitHub Actions (Easiest)**
```bash
# Fork this repo, then:
git clone https://github.com/YOUR-USERNAME/casestudy3.git
cd casestudy3
git add .
git commit --allow-empty -m "Trigger deployment"
git push origin main

# Monitor
gh run watch
```

**2. Access Your Infrastructure**
```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle

# Check status
kubectl get pods --all-namespaces

# Get API URL
kubectl get ingress -n hr-portal
```

**3. Create Your First Employee**
```bash
export API_URL="http://$(kubectl get ingress hr-portal-ingress -n hr-portal -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

curl -X POST $API_URL/api/employees \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane.smith@innovatech.com",
    "role": "developer",
    "department": "Engineering"
  }'
```

**4. Access the Workspace**
```bash
# List workspaces
kubectl get pods -n workspaces

# Port forward to access
kubectl port-forward <workspace-pod> 8443:8080 -n workspaces
# Open browser: http://localhost:8443
```

**Done! 🎉** Your complete employee lifecycle automation platform is running!

---

## ❓ FAQ

### General Questions

**Q: How long does deployment take?**  
A: Full automated deployment via GitHub Actions takes ~8-10 minutes. Manual deployment takes ~30-40 minutes.

**Q: What does it cost to run this?**  
A: Approximately **$350-370/month** in AWS costs. See [Cost Management](#-cost-management) for breakdown and optimization tips.

**Q: Can I run this in a different AWS region?**  
A: Yes! Update the `AWS_REGION` variable in `.github/workflows/deploy.yml` and `terraform/variables.tf`. Recommended regions: `eu-west-1`, `us-east-1`, `us-west-2`.

**Q: Is this production-ready?**  
A: The infrastructure is production-ready. For production use, add:
- Authentication/Authorization (OAuth2, OIDC)
- TLS/SSL certificates (AWS ACM)
- Web Application Firewall (WAF)
- Backup and disaster recovery procedures
- Monitoring and alerting (PagerDuty, Slack)

### Deployment Questions

**Q: Why did my deployment fail?**  
A: Common causes:
1. AWS service quota limits (check EKS, VPC limits)
2. IAM permission issues (verify GitHub OIDC role)
3. S3 backend not initialized (run `setup-terraform-backend.ps1`)
4. Terraform state lock (check DynamoDB table)

Check deployment logs: `gh run view --log-failed`

**Q: How do I update just the application code?**  
A: Just push changes to the `applications/` directory. GitHub Actions will:
1. Rebuild only the changed container images
2. Push to ECR
3. Restart the affected pods

**Q: Can I deploy to an existing VPC/EKS cluster?**  
A: Yes! Modify `terraform/main.tf` to import existing resources or use data sources instead of creating new ones.

**Q: How do I roll back a deployment?**  
A: GitHub Actions approach:
```bash
# Via git revert
git revert HEAD
git push origin main

# Via re-running old deployment
gh run rerun <old-run-id>
```

Manual approach:
```bash
cd terraform
terraform state pull > backup.tfstate
# Restore infrastructure to previous state
terraform apply -state=backup.tfstate
```

### Usage Questions

**Q: How do I add authentication to the HR Portal?**  
A: Implement in `applications/hr-portal/backend/`:
1. Add auth middleware (JWT, OAuth2)
2. Integrate with identity provider (AWS Cognito, Auth0)
3. Update Kubernetes ingress with auth annotations
4. Add IRSA permissions for Cognito

**Q: Can employees access each other's workspaces?**  
A: No! Network policies enforce isolation:
- Each workspace runs in isolated pod
- NetworkPolicy blocks inter-workspace communication
- RBAC limits access to own resources only

**Q: How do I customize the workspace environment?**  
A: Edit `applications/workspace/Dockerfile`:
```dockerfile
# Add your tools
RUN apt-get install -y your-package
RUN pip3 install your-python-package
RUN npm install -g your-node-package

# Add custom extensions
RUN code-server --install-extension publisher.extension
```

**Q: How many employees can the system handle?**  
A: Current setup supports ~50-100 concurrent workspaces. To scale:
1. Increase node group size in `terraform/modules/eks/main.tf`
2. Use cluster autoscaler
3. Implement workspace hibernation for inactive users

### Operations Questions

**Q: How do I backup employee data?**  
A: DynamoDB has point-in-time recovery enabled:
```bash
# Create on-demand backup
aws dynamodb create-backup \
  --table-name innovatech-employees \
  --backup-name employees-backup-$(date +%Y%m%d)

# Restore from backup
aws dynamodb restore-table-from-backup \
  --target-table-name innovatech-employees-restored \
  --backup-arn <backup-arn>
```

**Q: How do I upgrade Kubernetes version?**  
A: Update `terraform/modules/eks/main.tf`:
```hcl
cluster_version = "1.29"  # Update version
```
Then: `terraform apply`. EKS handles rolling upgrade.

**Q: Where are logs stored?**  
A: Multiple locations:
- **Application logs**: CloudWatch Logs (`/aws/eks/innovatech-employee-lifecycle`)
- **Kubernetes logs**: `kubectl logs`
- **Infrastructure logs**: CloudTrail
- **VPC logs**: VPC Flow Logs

**Q: How do I set up alerts?**  
A: Add CloudWatch Alarms in `terraform/modules/monitoring/`:
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "eks-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
}
```

### Troubleshooting Questions

**Q: Pods are in CrashLoopBackOff state**  
A: Check logs and events:
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```
Common causes:
- Image pull errors (check ECR permissions)
- Missing environment variables
- Failed health checks
- Resource limits too low

**Q: Cannot connect to EKS cluster**  
A:
```bash
# 1. Verify cluster exists
aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1

# 2. Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle

# 3. Verify IAM permissions
aws sts get-caller-identity
```

**Q: Terraform state is locked**  
A:
```bash
# Check lock table
aws dynamodb scan --table-name terraform-state-lock --region eu-west-1

# Force unlock (use carefully!)
terraform force-unlock <lock-id>
```

**Q: Out of AWS service quota**  
A:
```bash
# Check quota
aws service-quotas list-service-quotas --service-code eks

# Request increase
aws service-quotas request-service-quota-increase \
  --service-code eks \
  --quota-code <quota-code> \
  --desired-value 10
```

### Security Questions

**Q: Is the system Zero Trust compliant?**  
A: Yes! Implements:
- ✅ Network segmentation (NetworkPolicies)
- ✅ Least privilege access (RBAC, IRSA)
- ✅ Encryption at rest and in transit
- ✅ Private VPC endpoints (no internet for data)
- ✅ Audit logging (CloudTrail, EKS audit logs)

**Q: How do I rotate credentials?**  
A:
```bash
# Rotate GitHub OIDC (update IAM role trust policy)
# Rotate ECR credentials (handled automatically by AWS)
# Rotate database credentials (DynamoDB uses IAM)
# Rotate Kubernetes service account tokens (automatic rotation)
```

**Q: Are workspaces isolated from each other?**  
A: Yes, through:
1. Namespace isolation
2. NetworkPolicies (deny-all by default)
3. PodSecurityPolicies/PodSecurityStandards
4. Separate service accounts per workspace

---

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Guide](#deployment-guide)
- [Usage](#usage)
- [Security](#security)
- [Cost Management](#cost-management)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## ✨ Features

### Functional Requirements
- ✅ **REQ-P3-01**: Automated employee onboarding and offboarding
- ✅ **REQ-P3-02**: Virtual workspaces as device alternative
- ✅ **REQ-P3-03**: DynamoDB for employee data storage
- ✅ **REQ-P3-10**: Full RBAC in cloud & Kubernetes
- ✅ **REQ-P3-11**: Zero Trust architecture with micro-segmentation

### Technical Features
- **HR Self-Service Portal**: Web-based interface for employee management
- **Workspace Automation**: Automatic provisioning of VS Code browser workspaces
- **Zero Trust Security**: Network policies, least privilege, encryption
- **Monitoring & Logging**: CloudWatch integration with detailed metrics
- **Cost Governance**: Tagged resources with cost tracking
- **High Availability**: Multi-AZ deployment with auto-scaling

## 🏗️ Architecture

![Architecture Diagram](docs/architecture-diagram.png)

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

### Key Components
- **AWS EKS Cluster**: Kubernetes control plane and worker nodes
- **VPC Architecture**: Public and private subnets across 3 AZs
- **DynamoDB**: Employee and workspace metadata storage
- **VPC Endpoints**: Private connectivity to AWS services (DynamoDB, ECR, CloudWatch)
- **Application Load Balancer**: HTTPS ingress for HR portal and workspaces
- **ECR**: Container image registry
- **CloudWatch**: Centralized logging and monitoring

## 🔧 Prerequisites

### Required Tools
- **AWS CLI** (v2.x): [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **Terraform** (v1.0+): [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **kubectl** (v1.28+): [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **Docker**: For building container images
- **Node.js** (v18+): For running the HR portal locally

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Sufficient service quotas for:
  - EKS clusters
  - VPC resources
  - EC2 instances
  - DynamoDB tables

### Permissions Required
- EKS full access
- VPC management
- DynamoDB access
- ECR access
- IAM role creation
- CloudWatch logs

## 🚀 Quick Start

### Option A: Automated Deployment via GitHub Actions (Recommended) ⚡

This project uses CI/CD workflows for automated deployment. Simply push to `main` branch!

**Prerequisites:**
- GitHub repository forked/cloned
- AWS OIDC provider configured for GitHub Actions
- IAM role: `arn:aws:iam::920120424621:role/githubrepo`

**Deploy Everything:**
```bash
# Just commit and push to main branch
git add .
git commit -m "Deploy infrastructure"
git push origin main

# GitHub Actions will automatically:
# 1. Validate Terraform configuration
# 2. Create infrastructure plan
# 3. Deploy AWS infrastructure (VPC, EKS, DynamoDB, etc.)
# 4. Deploy Kubernetes resources
# 5. Build and push container images to ECR
# 6. Run post-deployment health checks
# 7. Send deployment notification
```

**Monitor Deployment:**
```bash
# Check workflow status
gh run list --workflow="deploy.yml" --limit 5

# Watch live deployment
gh run watch

# View detailed logs
gh run view --log
```

**Destroy Everything:**
```bash
# Trigger destroy workflow manually
gh workflow run destroy.yml

# Or via GitHub UI:
# Actions → Destroy Infrastructure → Run workflow
```

---

### Option B: Manual Deployment (Advanced Users) 🛠️

For manual control or local testing:

#### 1. Clone the Repository
```bash
git clone https://github.com/i546927MehdiCetinkaya/casestudy3.git
cd casestudy3
```

#### 2. Setup Terraform Backend (One-time setup)
```bash
# PowerShell (Windows)
.\scripts\setup-terraform-backend.ps1

# Bash (Linux/Mac)
./scripts/setup-terraform-backend.sh
```

This creates:
- S3 bucket: `innovatech-terraform-state-920120424621`
- DynamoDB table: `terraform-state-lock`

#### 3. Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region (eu-west-1)
```

#### 4. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# Save cluster name for later
export CLUSTER_NAME=$(terraform output -raw cluster_name)
```

#### 5. Configure kubectl
```bash
aws eks update-kubeconfig --region eu-west-1 --name $CLUSTER_NAME
```

#### 6. Deploy Kubernetes Resources
```bash
cd ../kubernetes

# Deploy in order (namespaces first!)
kubectl apply -f namespaces.yaml
kubectl apply -f rbac.yaml
kubectl apply -f network-policies.yaml
kubectl apply -f hr-portal.yaml
kubectl apply -f workspaces.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=hr-portal-backend -n hr-portal --timeout=300s
```

#### 7. Build and Push Container Images
```bash
# Get your AWS account ID
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR login
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com

# Build and push HR Portal backend
cd applications/hr-portal/backend
docker build -t hr-portal-backend .
docker tag hr-portal-backend:latest $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest
docker push $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend:latest

# Build and push workspace image
cd ../../workspace
docker build -t employee-workspace .
docker tag employee-workspace:latest $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace:latest
docker push $ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace:latest
```

## 📖 Deployment Guide

### Step-by-Step Deployment

#### 1. Terraform Infrastructure (20-30 minutes)
```bash
cd terraform
terraform init
terraform apply
```

**What gets deployed:**
- VPC with public/private subnets
- EKS cluster with managed node group
- DynamoDB tables for employees and workspaces
- VPC endpoints for DynamoDB, ECR, CloudWatch
- IAM roles with IRSA
- Security groups
- CloudWatch log groups

#### 2. Kubernetes Resources (5-10 minutes)
```bash
# Deploy namespaces and RBAC
kubectl apply -f kubernetes/rbac.yaml

# Deploy network policies
kubectl apply -f kubernetes/network-policies.yaml

# Deploy HR Portal
kubectl apply -f kubernetes/hr-portal.yaml

# Verify deployments
kubectl get pods -n hr-portal
kubectl get pods -n workspaces
```

#### 3. Verify Installation
```bash
# Check EKS cluster
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Get ALB URL
kubectl get ingress -n hr-portal
```

## 💻 Usage

### Getting Access Information

After successful deployment, retrieve your application URLs:

```bash
# Get HR Portal URL
kubectl get ingress hr-portal-ingress -n hr-portal -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get all services
kubectl get svc -n hr-portal
kubectl get svc -n workspaces

# Get pods status
kubectl get pods -n hr-portal
kubectl get pods -n workspaces
```

### HR Portal Access

#### 1. **Access the HR Portal**

**Via Load Balancer (Production):**
```
http://<ALB-DNS-NAME>
# Example: http://k8s-hrportal-hrportal-abc123-1234567890.eu-west-1.elb.amazonaws.com
```

**Via Port Forwarding (Development/Testing):**
```bash
kubectl port-forward svc/hr-portal-backend 8080:80 -n hr-portal
# Access at: http://localhost:8080
```

#### 2. **Default Credentials**
- **API Endpoint**: `http://<ALB-DNS>/api`
- **Health Check**: `http://<ALB-DNS>/api/health`
- No authentication required for demo (add auth in production!)

---

### 👤 Employee Management

#### Create a New Employee (Onboarding)

**Via API:**
```bash
# Set your API endpoint
export API_URL="http://<ALB-DNS>"

# Create employee
curl -X POST $API_URL/api/employees \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@innovatech.com",
    "role": "developer",
    "department": "Engineering",
    "startDate": "2025-11-06"
  }'

# Response includes:
# - Employee ID
# - Workspace URL
# - Status
```

**What Happens Automatically:**
1. ✅ Employee record created in DynamoDB
2. ✅ Kubernetes workspace pod provisioned
3. ✅ VS Code server started
4. ✅ RBAC permissions assigned
5. ✅ Workspace URL generated
6. ✅ Development tools pre-installed

#### List All Employees

```bash
# Get all employees
curl $API_URL/api/employees

# Get specific employee
curl $API_URL/api/employees/<employee-id>
```

#### Update Employee

```bash
curl -X PUT $API_URL/api/employees/<employee-id> \
  -H "Content-Type: application/json" \
  -d '{
    "role": "senior-developer",
    "department": "Platform Engineering"
  }'
```

#### Delete Employee (Offboarding)

```bash
# Soft delete (marks as terminated)
curl -X DELETE $API_URL/api/employees/<employee-id>

# This triggers:
# 1. Workspace pod deletion
# 2. DynamoDB record update (status: terminated)
# 3. Access revocation
# 4. Resource cleanup
```

---

### 🖥️ Workspace Access

#### Access Employee Workspace

After onboarding, each employee gets a VS Code workspace:

**Workspace URL Format:**
```
http://<workspaces-service-url>/<employee-id>
```

**Find Workspace URL:**
```bash
# List all workspace pods
kubectl get pods -n workspaces

# Get workspace service
kubectl get svc -n workspaces

# Access specific workspace via port-forward
kubectl port-forward pod/<employee-workspace-pod> 8443:8080 -n workspaces
# Then browse to: http://localhost:8443
```

**Workspace Features:**
- ✅ VS Code in browser
- ✅ Pre-installed development tools (Node.js, Python, Git)
- ✅ Terminal access
- ✅ File system persistence
- ✅ Extensions support
- ✅ Collaborative coding

#### Workspace Management

**Check Workspace Status:**
```bash
# Get all workspaces
kubectl get pods -n workspaces -o wide

# Check workspace logs
kubectl logs <workspace-pod-name> -n workspaces

# Execute commands in workspace
kubectl exec -it <workspace-pod-name> -n workspaces -- /bin/bash
```

**Restart Workspace:**
```bash
kubectl delete pod <workspace-pod-name> -n workspaces
# Kubernetes will automatically recreate it
```

---

### 📊 Monitoring & Operations

#### Check System Health

```bash
# Overall cluster health
kubectl get nodes
kubectl top nodes

# Application health
kubectl get pods --all-namespaces
kubectl top pods -n hr-portal
kubectl top pods -n workspaces

# Service status
kubectl get svc --all-namespaces
kubectl get ingress --all-namespaces
```

#### View Logs

```bash
# HR Portal backend logs
kubectl logs -f deployment/hr-portal-backend -n hr-portal

# HR Portal frontend logs (if deployed)
kubectl logs -f deployment/hr-portal-frontend -n hr-portal

# Workspace logs
kubectl logs -f <workspace-pod> -n workspaces

# All logs in namespace
kubectl logs -n hr-portal --all-containers=true --tail=100
```

#### Check DynamoDB Data

```bash
# Scan employees table
aws dynamodb scan --table-name innovatech-employees --region eu-west-1

# Get specific employee
aws dynamodb get-item \
  --table-name innovatech-employees \
  --key '{"employeeId": {"S": "<employee-id>"}}' \
  --region eu-west-1

# Count employees
aws dynamodb scan \
  --table-name innovatech-employees \
  --select COUNT \
  --region eu-west-1
```

#### CloudWatch Metrics

```bash
# View log groups
aws logs describe-log-groups --region eu-west-1

# Stream logs
aws logs tail /aws/eks/innovatech-employee-lifecycle --follow --region eu-west-1

# Get recent logs
aws logs tail /aws/eks/innovatech-employee-lifecycle --since 1h --region eu-west-1
```

---

### 🔄 CI/CD Workflows

#### Deploy Workflow (Automated)

Triggers on push to `main` branch:

```bash
# Make changes
git add .
git commit -m "Update configuration"
git push origin main

# Monitor deployment
gh run watch
```

**Workflow Steps:**
1. ✅ Validate Terraform configuration
2. ✅ Create Terraform plan
3. ✅ Deploy infrastructure (if changes detected)
4. ✅ Deploy Kubernetes resources
5. ✅ Build & push container images
6. ✅ Run post-deployment tests
7. ✅ Send notification

**View Workflow Logs:**
```bash
# List recent runs
gh run list --workflow=deploy.yml

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log

# View only failed jobs
gh run view <run-id> --log-failed
```

#### Destroy Workflow (Manual)

**Option 1: GitHub CLI**
```bash
gh workflow run destroy.yml
```

**Option 2: GitHub Web UI**
1. Go to: `Actions` → `Destroy Infrastructure`
2. Click `Run workflow`
3. Select branch: `main`
4. Click `Run workflow`

**What Gets Destroyed:**
- ⚠️ All Kubernetes resources
- ⚠️ Container images in ECR
- ⚠️ EKS cluster and node groups
- ⚠️ VPC and networking
- ⚠️ DynamoDB tables (with backup)
- ⚠️ IAM roles and policies
- ✅ S3 backend bucket (preserved)
- ✅ Terraform state (preserved)

**Monitor Destroy:**
```bash
gh run watch
```

---

### 🛡️ Security Operations

#### Verify Zero Trust Configuration

```bash
# Check network policies
kubectl get networkpolicies -n hr-portal
kubectl get networkpolicies -n workspaces
kubectl describe networkpolicy -n hr-portal

# Check RBAC
kubectl get clusterrolebindings | grep innovatech
kubectl get rolebindings -n hr-portal
kubectl get rolebindings -n workspaces

# Check service accounts
kubectl get sa -n hr-portal
kubectl describe sa hr-portal-backend -n hr-portal
```

#### Test Network Isolation

```bash
# Test pod-to-pod communication (should be blocked by default)
kubectl run test-pod --image=busybox -n hr-portal --rm -it -- sh
# From inside pod:
wget -O- http://hr-portal-backend.hr-portal.svc.cluster.local

# Test allowed communication
kubectl run test-pod --image=busybox -n workspaces --rm -it -- sh
```

#### View Security Logs

```bash
# VPC Flow Logs
aws logs tail /aws/vpc/flowlogs --follow --region eu-west-1

# EKS Audit Logs
aws logs tail /aws/eks/innovatech-employee-lifecycle/cluster --follow --region eu-west-1

# Security group rules
aws ec2 describe-security-groups --region eu-west-1 --filters "Name=tag:Project,Values=InnovatechEmployeeLifecycle"
```

---

### 💰 Cost Monitoring

#### View Current Costs

```bash
# Get cost by service (last 30 days)
aws ce get-cost-and-usage \
  --time-period Start=2025-10-07,End=2025-11-06 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=SERVICE

# Get cost by tag
aws ce get-cost-and-usage \
  --time-period Start=2025-10-07,End=2025-11-06 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=Project
```

#### Resource Inventory

```bash
# Count all resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters "Key=Project,Values=InnovatechEmployeeLifecycle" \
  --region eu-west-1 | jq '.ResourceTagMappingList | length'

# List resources by type
aws resourcegroupstaggingapi get-resources \
  --tag-filters "Key=Project,Values=InnovatechEmployeeLifecycle" \
  --region eu-west-1 | jq -r '.ResourceTagMappingList[].ResourceARN' | cut -d: -f6 | sort | uniq -c
```

---

### HR Portal Access

### 🧪 Testing

### Zero Trust Implementation

**Network Segmentation:**
- Default deny-all network policies
- Micro-segmentation between namespaces
- Explicit allow rules for required communication

**Access Control:**
- RBAC at Kubernetes level
- IAM roles for service accounts (IRSA)
- Least privilege principle
- Multi-factor authentication (recommended)

**Data Protection:**
- Encryption at rest (EBS, DynamoDB)
- Encryption in transit (TLS/HTTPS)
- KMS-managed encryption keys
- Secrets management with Kubernetes secrets

**Monitoring & Auditing:**
- VPC Flow Logs
- EKS audit logs
- CloudWatch metrics and alarms
- DynamoDB point-in-time recovery

### Security Best Practices

1. **Rotate credentials regularly**
2. **Enable MFA for all users**
3. **Use AWS Secrets Manager for production secrets**
4. **Implement WAF rules on ALB**
5. **Regular security scans of container images**
6. **Keep Kubernetes and node groups updated**

## 💰 Cost Management

### Estimated Monthly Costs (EU-West-1)

| Resource | Quantity | Monthly Cost (USD) |
|----------|----------|-------------------|
| EKS Cluster | 1 | $73 |
| EC2 t3.medium nodes | 3 | $100 |
| NAT Gateway | 3 | $100 |
| Application Load Balancer | 1 | $23 |
| DynamoDB (on-demand) | 2 tables | $5-20 |
| VPC Endpoints | 6 | $45 |
| EBS Volumes (gp3) | ~50GB | $5 |
| ECR Storage | 10GB | $1 |
| CloudWatch Logs | 10GB | $5 |
| **Total** | | **~$357-372/month** |

### Cost Optimization Tips

1. **Use Spot Instances** for dev/test environments (-70% cost)
2. **Right-size node instances** based on actual usage
3. **Enable DynamoDB auto-scaling** for variable workloads
4. **Use S3 lifecycle policies** for ECR images
5. **Set CloudWatch log retention** to 30 days
6. **Delete unused workspaces** regularly
7. **Use Reserved Instances** for production (save 30-50%)

### Resource Tagging Strategy
All resources are tagged with:
- `Project`: InnovatechEmployeeLifecycle
- `Environment`: production/staging/dev
- `ManagedBy`: Terraform
- `CostCenter`: IT-Infrastructure
- `Owner`: DevOps-Team

## 🧪 Testing

### Test Plan

See [tests/TEST_PLAN.md](tests/TEST_PLAN.md) for comprehensive testing documentation.

### Quick Tests

#### 1. Infrastructure Tests
```bash
# Verify Terraform outputs
terraform output

# Check EKS cluster health
aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1

# Verify VPC endpoints
aws ec2 describe-vpc-endpoints --region eu-west-1
```

#### 2. Application Tests
```bash
# Test HR Portal API
curl -X GET https://hr.innovatech.example.com/api/health

# Test employee creation
curl -X POST https://hr.innovatech.example.com/api/employees \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Test","lastName":"User","email":"test@innovatech.com","role":"developer","department":"Engineering"}'

# Check workspace status
kubectl get pods -n workspaces
```

#### 3. Security Tests
```bash
# Verify network policies
kubectl get networkpolicies -n hr-portal
kubectl get networkpolicies -n workspaces

# Check RBAC
kubectl get clusterrolebindings | grep hr-portal
kubectl get rolebindings -n workspaces

# Test pod security
kubectl auth can-i create pods --as=system:serviceaccount:hr-portal:hr-portal-backend
```

### Automated Testing

```bash
cd tests
./run-tests.sh
```

## 🔍 Troubleshooting

### Quick Diagnostic Commands

```bash
# Full cluster overview
kubectl get all --all-namespaces

# Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# Find failing pods
kubectl get pods --all-namespaces --field-selector=status.phase!=Running

# Recent cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# Check deployments status
kubectl get deployments --all-namespaces
```

### Common Issues

#### 1. Pods not starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Common causes:
# - Image pull errors (check ECR permissions)
# - Resource limits (check node capacity)
# - ConfigMap/Secret missing
```

#### 2. Cannot connect to EKS cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle

# Verify AWS credentials
aws sts get-caller-identity

# Check EKS cluster status
aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1
```

#### 3. Workspace provisioning fails
```bash
# Check HR Portal backend logs
kubectl logs -n hr-portal -l app=hr-portal-backend

# Verify service account permissions
kubectl describe sa hr-portal-backend -n hr-portal

# Check DynamoDB access
aws dynamodb describe-table --table-name innovatech-employees
```

#### 4. Network connectivity issues
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --region eu-west-1 --filters Name=vpc-id,Values=<vpc-id>

# Verify security groups
kubectl get svc -n hr-portal
```

### Debug Commands

```bash
# Get all resources in a namespace
kubectl get all -n hr-portal

# Describe a failing pod
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Execute commands in a pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Port forward for local access
kubectl port-forward svc/hr-portal-backend 3000:80 -n hr-portal
```

## 📚 Additional Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Detailed architecture and design decisions
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) - Step-by-step deployment guide
- [OPERATIONS.md](docs/OPERATIONS.md) - Operational procedures and runbooks
- [TESTING.md](docs/TESTING.md) - Comprehensive test scenarios and results
- [COST_ANALYSIS.md](docs/COST_ANALYSIS.md) - Detailed cost breakdown and optimization
- [DEVIATIONS.md](docs/DEVIATIONS.md) - Documented deviations from original requirements

---

## ⚡ Quick Reference

### Most Used Commands

```bash
# === DEPLOYMENT ===
# Deploy via CI/CD
git push origin main

# Manual deploy
cd terraform && terraform apply -auto-approve
kubectl apply -f kubernetes/

# === MONITORING ===
# Check everything
kubectl get all -n hr-portal
kubectl get all -n workspaces

# Watch pods
kubectl get pods -n hr-portal -w

# Check logs
kubectl logs -f deployment/hr-portal-backend -n hr-portal

# === EMPLOYEE MANAGEMENT ===
# Create employee
curl -X POST $API_URL/api/employees -H "Content-Type: application/json" -d '{"firstName":"John","lastName":"Doe","email":"john@innovatech.com","role":"developer","department":"Engineering"}'

# List employees
curl $API_URL/api/employees

# Delete employee
curl -X DELETE $API_URL/api/employees/<id>

# === TROUBLESHOOTING ===
# Cluster info
kubectl cluster-info
kubectl get nodes

# Pod debugging
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Network testing
kubectl run test --image=busybox -n hr-portal --rm -it -- sh

# === CLEANUP ===
# Destroy everything
gh workflow run destroy.yml

# Manual destroy
cd terraform && terraform destroy -auto-approve
```

### Environment Variables

```bash
# Set these for easier usage
export AWS_REGION=eu-west-1
export CLUSTER_NAME=innovatech-employee-lifecycle
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export API_URL="http://$(kubectl get ingress hr-portal-ingress -n hr-portal -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
```

### Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Kubernetes shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs -f'
alias kx='kubectl exec -it'

# Namespace shortcuts
alias khr='kubectl -n hr-portal'
alias kws='kubectl -n workspaces'

# AWS shortcuts
alias eks-config='aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle'

# Project shortcuts
alias deploy='git push origin main && gh run watch'
alias check='kubectl get pods --all-namespaces'
alias logs-hr='kubectl logs -f deployment/hr-portal-backend -n hr-portal'
```

### Key URLs & Endpoints

| Resource | URL/Endpoint |
|----------|-------------|
| **GitHub Repo** | https://github.com/i546927MehdiCetinkaya/casestudy3 |
| **GitHub Actions** | https://github.com/i546927MehdiCetinkaya/casestudy3/actions |
| **HR Portal API** | `http://<ALB-DNS>/api` |
| **Health Check** | `http://<ALB-DNS>/api/health` |
| **Kubernetes Dashboard** | `kubectl proxy` → http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ |
| **CloudWatch Logs** | https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1#logsV2:log-groups |
| **DynamoDB Console** | https://console.aws.amazon.com/dynamodbv2/home?region=eu-west-1#tables |
| **ECR Repositories** | https://console.aws.amazon.com/ecr/repositories?region=eu-west-1 |

### Resource Names

| Resource Type | Name/Pattern |
|--------------|--------------|
| **EKS Cluster** | `innovatech-employee-lifecycle` |
| **VPC** | `innovatech-employee-lifecycle-vpc` |
| **DynamoDB Tables** | `innovatech-employees`, `innovatech-workspaces` |
| **ECR Repos** | `hr-portal-backend`, `hr-portal-frontend`, `employee-workspace` |
| **S3 Backend** | `innovatech-terraform-state-920120424621` |
| **DynamoDB Lock** | `terraform-state-lock` |
| **IAM Role (GitHub)** | `arn:aws:iam::920120424621:role/githubrepo` |
| **IAM Role (HR Portal)** | `innovatech-employee-lifecycle-hr-portal-role` |
| **IAM Role (Workspace)** | `innovatech-employee-lifecycle-workspace-role` |
| **Namespaces** | `hr-portal`, `workspaces`, `kube-system` |

---

## 📝 Project Structure

```
casestudy3/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── dynamodb/
│       ├── vpc-endpoints/
│       ├── iam/
│       ├── ecr/
│       ├── monitoring/
│       └── security-groups/
├── kubernetes/                # Kubernetes manifests
│   ├── hr-portal.yaml
│   ├── workspaces.yaml
│   ├── rbac.yaml
│   └── network-policies.yaml
├── applications/              # Application code
│   ├── hr-portal/
│   │   ├── backend/          # Node.js API
│   │   └── frontend/         # React UI
│   └── workspace/            # VS Code workspace image
├── ansible/                  # Optional configuration management
├── scripts/                  # Deployment and utility scripts
├── tests/                    # Test scenarios and scripts
└── docs/                     # Documentation
    ├── ARCHITECTURE.md
    ├── DEPLOYMENT.md
    ├── OPERATIONS.md
    └── images/
```

## 👥 Team & Support

**Project Owner**: Mehdi Cetinkaya  
**Course**: Case Study 3 - Fontys ICT  
**Academic Year**: 2024-2025

## 📄 License

This project is created for educational purposes as part of Case Study 3 at Fontys University of Applied Sciences.

## 🙏 Acknowledgments

- AWS Documentation
- Kubernetes Documentation
- Case Study 2 repository structure
- Fontys ICT instructors and peers

---

**Last Updated**: November 6, 2025  
**Version**: 1.0.0