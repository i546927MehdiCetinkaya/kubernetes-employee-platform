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

## AWS Network Architecture

```mermaid
flowchart TB
    Internet((Internet))
    
    subgraph VPC["VPC: 10.0.0.0/16"]
        subgraph AZ1["Availability Zone 1"]
            subgraph PubSub1["Public Subnet 10.0.1.0/24"]
                IGW[Internet Gateway]
                ALB1[ALB<br/>Target Group 1]
                NAT1[NAT Gateway<br/>Elastic IP]
            end
            
            subgraph PrivSub1["Private Subnet 10.0.101.0/24"]
                EKS1[EKS Node Group<br/>Worker Nodes]
                POD1[Pods<br/>hr-portal + workspaces]
            end
        end
        
        subgraph AZ2["Availability Zone 2"]
            subgraph PubSub2["Public Subnet 10.0.2.0/24"]
                ALB2[ALB<br/>Target Group 2]
                NAT2[NAT Gateway<br/>Elastic IP]
            end
            
            subgraph PrivSub2["Private Subnet 10.0.102.0/24"]
                EKS2[EKS Node Group<br/>Worker Nodes]
                POD2[Pods<br/>hr-portal + workspaces]
            end
        end
        
        subgraph Endpoints["VPC Endpoints - PrivateLink"]
            VPCe_DDB[DynamoDB<br/>Gateway Endpoint]
            VPCe_ECR[ECR API<br/>Interface Endpoint]
            VPCe_ECR_DKR[ECR DKR<br/>Interface Endpoint]
            VPCe_SES[SES<br/>Interface Endpoint]
            VPCe_S3[S3<br/>Gateway Endpoint]
        end
    end
    
    subgraph AWS_Services["AWS Managed Services"]
        DDB[(DynamoDB)]
        ECR[ECR Registry]
        SES[Simple Email Service]
        S3[S3 Buckets]
    end
    
    Internet -->|HTTPS| IGW
    IGW --> ALB1
    IGW --> ALB2
    ALB1 --> POD1
    ALB2 --> POD2
    
    POD1 -->|Outbound Internet| NAT1
    POD2 -->|Outbound Internet| NAT2
    NAT1 --> IGW
    NAT2 --> IGW
    
    POD1 -.->|Private| VPCe_DDB
    POD2 -.->|Private| VPCe_DDB
    VPCe_DDB -.-> DDB
    
    POD1 -.->|Private| VPCe_ECR
    POD2 -.->|Private| VPCe_ECR_DKR
    VPCe_ECR -.-> ECR
    VPCe_ECR_DKR -.-> ECR
    
    POD1 -.->|Private| VPCe_SES
    POD2 -.->|Private| VPCe_SES
    VPCe_SES -.-> SES
    
    EKS1 -.->|Private| VPCe_S3
    EKS2 -.->|Private| VPCe_S3
    VPCe_S3 -.-> S3
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