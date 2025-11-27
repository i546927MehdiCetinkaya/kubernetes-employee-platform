# Architecture

## System Architecture

```mermaid
flowchart TB
    subgraph Users
        HR[HR Staff]
        EMP[Employee]
    end
    
    subgraph AWS["AWS Cloud"]
        subgraph Public["Public Subnet"]
            LB[Application Load Balancer<br/>AWS Load Balancer Controller]
        end
        
        subgraph Private["Private Subnet - EKS Cluster"]
            subgraph HR_NS["Namespace: hr-portal"]
                FE[Frontend<br/>React + Nginx]
                BE[Backend API<br/>Node.js + Express]
            end
            
            subgraph WS_NS["Namespace: workspaces"]
                WS1[Workspace Pod 1<br/>VSCode Server + Tools]
                WS2[Workspace Pod 2<br/>VSCode Server + Tools]
                WS3[Workspace Pod N<br/>VSCode Server + Tools]
            end
        end
        
        subgraph Identity["Identity & Access"]
            DS[AWS Directory Service<br/>Managed Microsoft AD]
            IAM[IAM Roles<br/>Per Department]
        end
        
        subgraph Services["AWS Services"]
            DB[(DynamoDB<br/>EmployeeLifecycle Table<br/>+ Workspaces Table)]
            ECR[ECR<br/>Container Images]
            SSM[Systems Manager<br/>SSM Parameter Store]
            CW[CloudWatch<br/>Logs + Metrics]
        end
        
        subgraph VPCe["VPC Endpoints"]
            VPCe_ECR[ECR API + DKR]
            VPCe_DDB[DynamoDB]
            VPCe_S3[S3]
            VPCe_SSM[SSM]
            VPCe_CW[CloudWatch Logs]
        end
    end
    
    HR -->|HTTPS| LB
    EMP -->|HTTPS| LB
    LB -->|Route /| FE
    LB -->|Route /api| BE
    FE -->|API Calls| BE
    BE -->|Store/Retrieve Employee Data| DB
    BE -->|Create Workspace Pod via K8s Job| WS_NS
    BE -->|Store Workspace Metadata| DB
    BE -->|Read Workspace Config| SSM
    BE -->|Manage Directory Users| DS
    DS -->|Role Assignment| IAM
    HR_NS -.->|Pull Images via VPC Endpoint| VPCe_ECR
    WS_NS -.->|Pull Images via VPC Endpoint| VPCe_ECR
    VPCe_ECR -.-> ECR
    BE -.->|Write/Read Data via VPC Endpoint| VPCe_DDB
    VPCe_DDB -.-> DB
    HR_NS -.->|Send Logs via VPC Endpoint| VPCe_CW
    WS_NS -.->|Send Logs via VPC Endpoint| VPCe_CW
    VPCe_CW -.-> CW
    BE -.->|Read Parameters via VPC Endpoint| VPCe_SSM
    VPCe_SSM -.-> SSM
    
    style VPCe fill:#e1f5ff
    style Services fill:#fff4e6
    style Identity fill:#e8f5e9
```

---

## Identity & Access Management

### IAM Roles Per Department (No IAM Users)

| Role | Department | Key Permissions |
|------|------------|-----------------|
| `infra-role` | IT, DevOps, Infrastructure | EKS describe, EC2 read, CloudWatch, SSM read |
| `developer-role` | Engineering, Development | ECR push/pull, CodeBuild, CloudWatch logs |
| `hr-role` | HR, Human Resources | DynamoDB employee CRUD, workspaces read |
| `manager-role` | Management, Executive | DynamoDB read-only, CloudWatch read |
| `admin-role` | Administration | Full access to all project resources |

### Service Roles (IRSA)

| Role | Service | Purpose |
|------|---------|---------|
| `hr-portal-role` | Backend API | DynamoDB, SSM, Directory Service access |
| `workspace-role` | Workspace Provisioner | CloudWatch logs, workspace management |

**Key Design Decisions:**
- **No IAM Users**: All human access via IAM Roles (school/enterprise requirement)
- **Directory Service**: AWS Managed Microsoft AD for centralized identity
- **Department-based Roles**: Each department has specific, scoped permissions
- **SAML Federation**: Employees assume roles via Directory Service integration
- **IRSA for Services**: Kubernetes pods use IAM Roles for Service Accounts

---

## AWS Network Architecture

```mermaid
flowchart TB
    Internet((Internet))
    
    subgraph VPC["VPC: 10.0.0.0/16"]
        subgraph AZ1["Availability Zone 1"]
            subgraph PubSub1["Public Subnet 10.0.1.0/24"]
                IGW[Internet Gateway]
                ALB1[Application Load Balancer<br/>Target: Frontend + Backend]
            end
            
            subgraph PrivSub1["Private Subnet 10.0.101.0/24"]
                EKS1[EKS Node Group<br/>Managed Nodes]
                POD1[Pods:<br/>hr-portal-frontend<br/>hr-portal-backend<br/>workspace-*]
            end
        end
        
        subgraph AZ2["Availability Zone 2"]
            subgraph PubSub2["Public Subnet 10.0.2.0/24"]
                ALB2[ALB<br/>Multi-AZ]
            end
            
            subgraph PrivSub2["Private Subnet 10.0.102.0/24"]
                EKS2[EKS Node Group<br/>Managed Nodes]
                POD2[Pods:<br/>hr-portal-frontend<br/>hr-portal-backend<br/>workspace-*]
            end
        end
        
        subgraph Endpoints["VPC Endpoints - AWS PrivateLink"]
            VPCe_DDB[DynamoDB<br/>Gateway Endpoint]
            VPCe_ECR[ECR API<br/>Interface Endpoint]
            VPCe_ECR_DKR[ECR Docker<br/>Interface Endpoint]
            VPCe_S3[S3<br/>Gateway Endpoint]
            VPCe_SSM[Systems Manager<br/>Interface Endpoint]
            VPCe_CW[CloudWatch Logs<br/>Interface Endpoint]
        end
    end
    
    subgraph AWS_Services["AWS Managed Services"]
        DDB[(DynamoDB<br/>EmployeeLifecycle<br/>Workspaces)]
        ECR[ECR Repositories<br/>hr-portal-backend<br/>hr-portal-frontend<br/>employee-workspace]
        S3[S3 Buckets<br/>Terraform State]
        SSM_SVC[Systems Manager<br/>Parameter Store]
        CW_SVC[CloudWatch<br/>Monitoring]
    end
    
    Internet -->|HTTPS Only| IGW
    IGW --> ALB1
    IGW --> ALB2
    ALB1 --> POD1
    ALB2 --> POD2
    
    POD1 -.->|Private Access| VPCe_DDB
    POD2 -.->|Private Access| VPCe_DDB
    VPCe_DDB -.-> DDB
    
    POD1 -.->|Private Access| VPCe_ECR
    POD2 -.->|Private Access| VPCe_ECR_DKR
    VPCe_ECR -.-> ECR
    VPCe_ECR_DKR -.-> ECR
    
    EKS1 -.->|Private Access| VPCe_S3
    EKS2 -.->|Private Access| VPCe_S3
    VPCe_S3 -.-> S3
    
    POD1 -.->|Private Access| VPCe_SSM
    POD2 -.->|Private Access| VPCe_SSM
    VPCe_SSM -.-> SSM_SVC
    
    POD1 -.->|Private Access| VPCe_CW
    POD2 -.->|Private Access| VPCe_CW
    VPCe_CW -.-> CW_SVC
    
    style Endpoints fill:#e1f5ff
    style AWS_Services fill:#fff4e6
```

**Key Architecture Decisions:**
- **No NAT Gateway**: All AWS service communication via VPC endpoints (cost optimization: ~$32/month savings)
- **No Direct Workspace Access**: Workspaces are backend-managed pods, credentials displayed in HR portal UI
- **Private-Only Pods**: EKS nodes in private subnets, no direct internet access
- **ALB Ingress**: AWS Load Balancer Controller provisions ALB automatically via Kubernetes Ingress

---

## Data Flow

```mermaid
sequenceDiagram
    participant HR as HR Portal<br/>(Frontend)
    participant API as Backend API<br/>(Node.js)
    participant DB as DynamoDB<br/>(EmployeeLifecycle)
    participant K8S as Kubernetes API<br/>(EKS Control Plane)
    participant WS_DB as DynamoDB<br/>(Workspaces Table)
    participant SSM as Systems Manager<br/>(Parameter Store)
    participant WS as Workspace Pod<br/>(VSCode Server)
    
    HR->>API: POST /employees<br/>{name, email, role}
    API->>DB: PutItem<br/>Store employee data
    DB-->>API: Success
    
    API->>SSM: GetParameter<br/>Fetch workspace config
    SSM-->>API: {cpu, memory, storage}
    
    API->>K8S: Create Job<br/>provision-workspace-{employeeId}
    K8S->>WS: Launch Pod<br/>employee-workspace-{id}
    WS-->>K8S: Pod Running
    K8S-->>API: Job Complete
    
    API->>WS_DB: PutItem<br/>Store workspace metadata<br/>{employeeId, podName, status}
    WS_DB-->>API: Success
    
    API-->>HR: 201 Created<br/>{employeeId, workspaceUrl, credentials}
    
    Note over HR,WS: Credentials displayed in UI<br/>(no email sent - deviation from req)
```

---

## Infrastructure Components

### Terraform Modules

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| **vpc** | Network foundation | VPC, subnets (public/private), IGW, route tables |
| **eks** | Kubernetes cluster | EKS cluster, managed node groups, OIDC provider |
| **dynamodb** | Data storage | EmployeeLifecycle table, Workspaces table |
| **iam** | Access control | Service account roles, IRSA for hr-portal & workspaces |
| **vpc-endpoints** | Private AWS access | ECR, DynamoDB, S3, SSM, CloudWatch endpoints |
| **systems-manager** | Configuration management | SSM parameters for workspace settings |
| **ebs-csi** | Persistent storage | EBS CSI driver for workspace volumes |
| **security-groups** | Network security | EKS cluster, node, pod security groups |
| **ecr** | Container registry | Repositories for frontend, backend, workspace images |
| **monitoring** | Observability | CloudWatch log groups, metric filters, dashboards |

---

## Applications

### HR Portal
- **Frontend**: React SPA served by nginx, containerized
- **Backend**: Node.js Express API with AWS SDK integration
- **Namespace**: `hr-portal`
- **IAM Role**: `hr-portal-sa-role` (IRSA) with DynamoDB, SSM, EKS permissions

### Employee Workspaces
- **Image**: VSCode server + development tools (Git, Docker, Node.js)
- **Provisioning**: Kubernetes Jobs created by backend API
- **Namespace**: `workspaces` (isolated from hr-portal)
- **Storage**: 20GB EBS volumes per workspace via EBS CSI driver
- **Resources**: 2 vCPU, 4GB RAM per pod

---

## Security

### Zero Trust Principles
- **Private Subnets Only**: All pods run without direct internet access
- **VPC Endpoints**: Secure, private communication to AWS services
- **IRSA (IAM Roles for Service Accounts)**: Pod-level AWS permissions via OIDC
- **Network Policies**: Kubernetes namespace isolation
- **RBAC**: Kubernetes role-based access control for service accounts

### Security Groups
| Group | Purpose | Rules |
|-------|---------|-------|
| EKS Cluster SG | Control plane | Ingress from nodes on 443 |
| Node SG | Worker nodes | Ingress from ALB, cluster; egress to VPC endpoints |
| Pod SG | Application pods | Restricted ingress based on namespace |

---

## Scalability

- **EKS Cluster Autoscaler**: Automatically scales node groups based on pod resource requests
- **Horizontal Pod Autoscaler (HPA)**: Scales backend API pods based on CPU/memory
- **DynamoDB On-Demand**: Automatically scales read/write capacity
- **Multi-AZ**: EKS nodes and ALB span 2 availability zones

---

## Monitoring

### CloudWatch Integration
- **Log Groups**: Separate groups for frontend, backend, workspace pods
- **Metrics**: CPU, memory, network for EKS nodes and pods
- **Alarms**: Triggers for pod failures, high error rates, resource exhaustion
- **Dashboards**: Custom dashboard showing:
  - Active employee count
  - Workspace provisioning success rate
  - API response times
  - DynamoDB throttling events

---

## Deployment

### Infrastructure Provisioning
1. **Terraform**: Provisions VPC, EKS, DynamoDB, IAM, VPC endpoints
2. **State Management**: Remote state in S3 with DynamoDB locking
3. **Terraform Modules**: Modular design for reusability

### Application Deployment
1. **Docker**: Build images for frontend, backend, workspace
2. **ECR**: Push images to AWS ECR repositories
3. **Kubernetes Manifests**: Deploy via kubectl:
   - Namespaces
   - Deployments (frontend, backend)
   - Services (ClusterIP for backend, LoadBalancer for frontend)
   - Ingress (ALB via AWS Load Balancer Controller)
   - ServiceAccounts with IRSA annotations

### CI/CD Pipeline
- **GitHub Actions**: Automated on push to `main`
- **Workflow**: Terraform plan → apply → Docker build → ECR push → kubectl apply
- **OIDC Authentication**: GitHub Actions authenticate to AWS without static credentials

---

## Design Deviations from Requirements

### Email Notifications (REQ-NCA-P3-01)
**Requirement**: Automated provisioning with email credentials via AWS SES  
**Implementation**: Credentials displayed in HR Portal UI instead of email  
**Justification**:
- **Simplicity**: No SES configuration, DNS verification, or email templates needed
- **Cost**: Saves SES costs (~$0.10 per 1,000 emails)
- **Security**: Credentials not transmitted via email (reduces interception risk)
- **User Experience**: Immediate access in portal vs. waiting for email delivery
- **Core Requirement Met**: Automated provisioning still occurs, only delivery method differs

### Internet Access Architecture
**Requirement**: None specified  
**Implementation**: No NAT Gateway - all AWS service access via VPC endpoints  
**Justification**:
- **Cost Optimization**: Saves ~$32/month per NAT Gateway (no data transfer charges)
- **Security**: No egress internet access from pods (reduced attack surface)
- **Performance**: VPC endpoints provide faster access to AWS services
- **Zero Trust Alignment**: Private-only communication aligns with ZTA principles

### Workspace Access Pattern
**Requirement**: None specified  
**Implementation**: Workspaces are backend-managed pods, not directly routed via ALB  
**Justification**:
- **Current Phase**: Focus on automated provisioning (Phase 2 core assignment)
- **Future Enhancement**: Workspace routing can be added via Ingress in Phase 3
- **Security**: Prevents direct user access to workspace pods before proper authentication

---

## Cost Optimization

| Resource | Monthly Cost (Estimate) | Optimization |
|----------|------------------------|--------------|
| EKS Cluster | $72 | Required (control plane) |
| EC2 Nodes (3x t3.medium) | ~$90 | Right-sized for workload |
| NAT Gateway | **$0** | ✅ Eliminated via VPC endpoints |
| VPC Endpoints | ~$22 | Required for private access |
| DynamoDB On-Demand | ~$5 | Pay-per-request |
| ALB | ~$16 | Required for ingress |
| **Total** | **~$205/month** | **$32/month saved** vs NAT |

```