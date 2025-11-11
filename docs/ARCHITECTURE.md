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
            LB[Application Load Balancer]
        end
        
        subgraph Private["Private Subnet - EKS Cluster"]
            subgraph HR_NS["Namespace: hr-portal"]
                FE[Frontend<br/>React + Nginx]
                BE[Backend API<br/>Node.js + Express]
            end
            
            subgraph WS_NS["Namespace: workspaces"]
                WS1[Workspace Pod 1<br/>VSCode Server]
                WS2[Workspace Pod 2<br/>VSCode Server]
                WS3[Workspace Pod N<br/>VSCode Server]
            end
        end
        
        subgraph Services["AWS Services"]
            DB[(DynamoDB<br/>Employee Data)]
            SES[AWS SES<br/>Email Service]
            ECR[ECR<br/>Container Images]
        end
    end
    
    HR -->|HTTPS| LB
    EMP -->|HTTPS| LB
    LB -->|Route /| FE
    LB -->|Route /api| BE
    FE -->|API Calls| BE
    BE -->|Store/Retrieve| DB
    BE -->|Send Email| SES
    BE -->|Create Pod| WS_NS
    LB -->|Route /workspace/:id| WS1
    LB -->|Route /workspace/:id| WS2
    LB -->|Route /workspace/:id| WS3
    HR_NS -.->|Pull Images| ECR
    WS_NS -.->|Pull Images| ECR
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