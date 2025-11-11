# Architecture

## System Architecture

```mermaid
flowchart LR
    HR[HR Staff] --> LB[Load Balancer]
    EMP[Employee] --> LB
    LB --> FE[Frontend]
    FE --> BE[Backend API]
    BE --> DB[(DynamoDB)]
    BE --> SES[AWS SES]
    BE --> K8S[Kubernetes]
    K8S --> WS[Workspace Pods]
```

---

## Data Flow

```mermaid
sequenceDiagram
    participant HR as HR Portal
    participant API as Backend API
    participant DB as DynamoDB
    participant K8S as Kubernetes
    participant EMP as Employee Email
    
    HR->>API: POST /employees
    API->>DB: Store employee data
    API->>K8S: Create workspace pod
    K8S-->>API: Workspace created
    API->>EMP: Send welcome email (SES)
    API-->>HR: 201 Created
```

---

## Infrastructure

- **VPC**: Public/private subnets across 2 availability zones
- **EKS Cluster**: Kubernetes v1.28+ with managed node groups
- **DynamoDB**: EmployeeLifecycle table with partition key (employeeId)
- **ECR**: 3 repositories (hr-frontend, hr-backend, workspace-vscode)
- **Load Balancer**: AWS ALB with internet-facing listener
- **EBS CSI Driver**: Persistent storage for workspace files
- **IAM Roles**: EKS cluster role, node group role, workspace service account

---

## Applications

- **HR Portal**: React frontend (nginx) for employee management
- **Backend API**: Node.js Express API with AWS SDK integration
- **Workspace**: VSCode server in isolated Kubernetes namespace per employee

---

## Security

- Backend runs in private subnets (no direct internet access)
- Workspaces isolated via Kubernetes namespaces and network policies
- IAM roles for service-to-service authentication
- HTTPS only via Load Balancer SSL termination

---

## Scalability

- EKS autoscaling for node capacity
- Kubernetes HPA for backend pods
- DynamoDB on-demand capacity mode

---

## Deployment

- Terraform provisions AWS infrastructure (VPC, EKS, DynamoDB, IAM)
- Kubectl deploys Kubernetes manifests (deployments, services, ingress)
- ECR stores container images built from Dockerfiles