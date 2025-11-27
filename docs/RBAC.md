# Role-Based Access Control (RBAC)

## Overview

This project implements a comprehensive RBAC system using AWS Directory Service and IAM Roles. 
**No IAM Users are created** - all access is managed through roles that can be assumed.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS Directory Service                        │
│                   (Managed Microsoft AD)                         │
│                      innovatech.local                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Infra-Team  │  │ Developers  │  │  HR-Team    │              │
│  │   Group     │  │   Group     │  │   Group     │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                      │
│         ▼                ▼                ▼                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Managers    │  │   Admins    │  │             │              │
│  │   Group     │  │   Group     │  │             │              │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┘              │
│         │                │                                       │
└─────────┼────────────────┼──────────────────────────────────────┘
          │                │
          ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       IAM Roles                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ infra-role  │  │developer-role│ │  hr-role    │              │
│  │             │  │             │  │             │              │
│  │ EKS Access  │  │ ECR Access  │  │ DynamoDB    │              │
│  │ EC2 Read    │  │ CodeBuild   │  │ Employee    │              │
│  │ CloudWatch  │  │ Logs        │  │ Management  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │manager-role │  │ admin-role  │                               │
│  │             │  │             │                               │
│  │ Read-Only   │  │ Full Access │                               │
│  │ Access      │  │             │                               │
│  └─────────────┘  └─────────────┘                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## IAM Roles

### Department Roles

| Role Name | Target Departments | Session Duration | Key Permissions |
|-----------|-------------------|------------------|-----------------|
| `infra-role` | IT, DevOps, Infrastructure | 12 hours | EKS describe/list, EC2 describe, CloudWatch metrics/logs, SSM parameter read |
| `developer-role` | Engineering, Development, Software | 12 hours | ECR push/pull, CodeBuild start/stop, CloudWatch logs, S3 artifacts |
| `hr-role` | HR, Human Resources | 8 hours | DynamoDB employee CRUD, workspaces read-only |
| `manager-role` | Management, Executive | 8 hours | DynamoDB read-only, CloudWatch read-only |
| `admin-role` | Admin, Administration | 4 hours | Full access to project resources |

### Service Roles (IRSA)

| Role Name | Kubernetes Service Account | Namespace | Purpose |
|-----------|---------------------------|-----------|---------|
| `hr-portal-role` | hr-portal-backend | hr-portal | DynamoDB access, SSM read, Directory Service management |
| `workspace-role` | workspace-provisioner | workspaces | CloudWatch logs, workspace pod management |

## Role Permissions Detail

### Infrastructure Role (`infra-role`)

```json
{
  "EKS": ["DescribeCluster", "ListClusters", "DescribeNodegroup", "ListNodegroups", "AccessKubernetesApi"],
  "EC2": ["Describe*", "GetConsoleOutput"],
  "CloudWatch": ["GetMetricData", "GetMetricStatistics", "ListMetrics"],
  "Logs": ["GetLogEvents", "DescribeLogGroups", "DescribeLogStreams", "FilterLogEvents"],
  "SSM": ["GetParameter", "GetParameters", "GetParametersByPath", "DescribeParameters"]
}
```

### Developer Role (`developer-role`)

```json
{
  "ECR": ["GetAuthorizationToken", "BatchCheckLayerAvailability", "GetDownloadUrlForLayer", "BatchGetImage", "PutImage", "InitiateLayerUpload", "UploadLayerPart", "CompleteLayerUpload", "DescribeRepositories", "ListImages"],
  "CodeBuild": ["StartBuild", "StopBuild", "BatchGetBuilds", "ListBuildsForProject"],
  "Logs": ["GetLogEvents", "DescribeLogGroups", "DescribeLogStreams", "FilterLogEvents"],
  "S3": ["GetObject", "PutObject", "ListBucket"] // On artifacts bucket only
}
```

### HR Role (`hr-role`)

```json
{
  "DynamoDB (employees table)": ["GetItem", "PutItem", "UpdateItem", "DeleteItem", "Query", "Scan"],
  "DynamoDB (workspaces table)": ["GetItem", "Query", "Scan"]
}
```

### Manager Role (`manager-role`)

```json
{
  "DynamoDB (all tables)": ["GetItem", "Query", "Scan"],
  "CloudWatch": ["GetMetricData", "GetMetricStatistics", "GetLogEvents", "FilterLogEvents"]
}
```

### Admin Role (`admin-role`)

```json
{
  "DynamoDB": ["*"],
  "EKS": ["*"],
  "SSM": ["*"],
  "CloudWatch": ["*"],
  "Logs": ["*"],
  "DirectoryService": ["*"]
}
```

## How Employees Get Access

### 1. Employee Onboarding

When an employee is created through the HR Portal:

1. Employee record is created in DynamoDB
2. Directory Service user is created (username: `firstname.lastname`)
3. User is assigned to the appropriate Directory Group based on department
4. Temporary password is stored in SSM Parameter Store
5. Welcome email is sent with credentials

### 2. Role Assumption Flow

```
Employee → Directory Service Login → SAML Assertion → IAM Role Assumption → Temporary Credentials
```

1. Employee authenticates to AWS Directory Service
2. SAML assertion is generated with group membership
3. Employee assumes the appropriate IAM role
4. Temporary credentials are issued (STS)
5. Employee uses credentials to access AWS services

### 3. Department to Role Mapping

| Department | Directory Group | IAM Role |
|------------|-----------------|----------|
| IT | Infra-Team | infra-role |
| DevOps | Infra-Team | infra-role |
| Infrastructure | Infra-Team | infra-role |
| Engineering | Developers | developer-role |
| Development | Developers | developer-role |
| Software | Developers | developer-role |
| HR | HR-Team | hr-role |
| Human Resources | HR-Team | hr-role |
| Management | Managers | manager-role |
| Executive | Managers | manager-role |
| Admin | Admins | admin-role |
| Administration | Admins | admin-role |

## Security Considerations

### Session Duration

- **Infra/Developer roles**: 12 hours (full work day)
- **HR/Manager roles**: 8 hours (standard work day)
- **Admin role**: 4 hours (limited for security)

### Principle of Least Privilege

Each role is scoped to only the permissions needed for that department:

- Developers can only push to ECR, not delete repositories
- HR can manage employees but not infrastructure
- Managers can view data but not modify it
- Infrastructure team can view but not modify EKS configuration

### Audit Trail

All role assumption events are logged in CloudWatch:

- `/aws/directoryservice/innovatech.local` - Directory Service events
- Role assumption events in CloudTrail
- SSM Parameter Store access in CloudTrail

## Kubernetes RBAC Integration

Kubernetes RBAC is configured to work with IAM roles:

```yaml
# hr-portal namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: hr-portal-backend
  namespace: hr-portal
subjects:
- kind: ServiceAccount
  name: hr-portal-backend
  namespace: hr-portal
roleRef:
  kind: Role
  name: hr-portal-role
  apiGroup: rbac.authorization.k8s.io
```

The service account `hr-portal-backend` is annotated with the IAM role ARN:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: hr-portal-backend
  namespace: hr-portal
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/innovatech-employee-lifecycle-hr-portal-role
```

## Enabling/Disabling Directory Service

Directory Service is optional and can be controlled via Terraform variable:

```hcl
# Enable Directory Service
enable_directory_service = true
directory_admin_password = "SecureP@ssw0rd!"

# Disable Directory Service (use fallback mode)
enable_directory_service = false
```

When disabled, the system operates in "fallback mode":
- User mappings are still stored in SSM
- Role assignments are tracked but not enforced via Directory Service
- Suitable for development/testing environments

## Cost Considerations

| Component | Estimated Monthly Cost |
|-----------|----------------------|
| AWS Managed Microsoft AD (Standard) | ~$145/month |
| SSM Parameter Store | Free tier (up to 10,000 parameters) |
| IAM Roles | Free |
| CloudWatch Logs | ~$5/month |

**Total**: ~$150/month for Directory Service integration

For development environments, you can disable Directory Service to save costs.
