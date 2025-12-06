# 🏗️ Architecture

> **InnovaTech Employee Lifecycle Platform** - Technical Architecture

---

## 🌐 High-Level Overview

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0ff', 'primaryTextColor': '#fff', 'lineColor': '#f0f', 'tertiaryColor': '#1a1a2e'}}}%%
flowchart TB
    subgraph USERS["🌐 Internet"]
        HR["👤 HR Staff"]
        EMP["👨‍💻 Employees"]
    end

    subgraph AWS["☁️ AWS Cloud - eu-west-1"]
        subgraph VPC["VPC 10.0.0.0/16"]
            subgraph PUB["Public Subnets"]
                NLB1["⚖️ HR Portal NLB\nPort 80"]
                NLB2["⚖️ Workspace NLBs\nPort 80"]
            end
            
            subgraph PRIV["Private Subnets"]
                subgraph EKS["☸️ EKS Cluster"]
                    direction TB
                    subgraph NS1["📦 hr-portal namespace"]
                        FE["🎨 Frontend\nReact + nginx"]
                        BE["⚡ Backend\nNode.js + Express"]
                    end
                    subgraph NS2["📦 workspaces namespace"]
                        W1["🖥️ jan.jansen\nNodePort 30123"]
                        W2["🖥️ kees.vanderspek\nNodePort 30456"]
                        WN["🖥️ ...more"]
                    end
                end
            end
        end
        
        DDB[("💾 DynamoDB\nemployees + workspaces")]
        ECR["📦 ECR\nContainer Images"]
        AD["🔐 Directory Service\ninnovatech.local"]
        SSM["🔧 SSM\nSecrets"]
        R53["🌐 Route53\nPrivate Zone\ninnovatech.local"]
    end

    HR --> NLB1
    EMP --> NLB2
    NLB1 --> FE
    FE --> BE
    NLB2 --> W1 & W2 & WN
    BE --> DDB
    BE --> R53
    BE -.->|"provision"| NS2
    EKS -.-> ECR
    EKS -.-> AD
    BE -.-> SSM
    EMP -.->|"DNS lookup"| R53

    style NLB1 fill:#0ff,stroke:#0ff,color:#000
    style NLB2 fill:#0ff,stroke:#0ff,color:#000
    style FE fill:#0f0,stroke:#0f0,color:#000
    style BE fill:#0f0,stroke:#0f0,color:#000
    style DDB fill:#f0f,stroke:#f0f,color:#000
    style ECR fill:#ff0,stroke:#ff0,color:#000
    style AD fill:#f60,stroke:#f60,color:#000
    style W1 fill:#f60,stroke:#f60,color:#000
    style W2 fill:#f60,stroke:#f60,color:#000
    style WN fill:#f60,stroke:#f60,color:#000
```

---

## 🔄 Employee Onboarding Flow

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0f0', 'lineColor': '#0ff'}}}%%
sequenceDiagram
    autonumber
    participant HR as 👤 HR Staff
    participant FE as 🎨 Frontend
    participant BE as ⚡ Backend
    participant DB as 💾 DynamoDB
    participant K8S as ☸️ Kubernetes
    participant WS as 🖥️ Workspace
    participant EMP as 👨‍💻 Employee

    rect rgb(20, 20, 40)
        Note over HR,DB: Employee Creation
        HR->>FE: Create Employee Form
        FE->>BE: POST /api/employees
        BE->>DB: Put Item
        DB-->>BE: ✅ Saved
        BE-->>FE: Employee Created
    end

    rect rgb(40, 20, 40)
        Note over HR,WS: Workspace Provisioning
        HR->>FE: Click "Provision Workspace"
        FE->>BE: POST /api/workspaces
        BE->>DB: Check for duplicate
        BE->>K8S: Create Pod + NodePort Service
        K8S->>WS: Start Container
        WS-->>K8S: Ready (TCP Check)
        K8S-->>BE: NodeIP + NodePort
        BE->>Route53: Create DNS A Record
        Note over Route53: firstname.lastname.innovatech.local → NodeIP
        BE->>DB: Save Workspace + URL
        BE-->>FE: ✅ Workspace Ready
    end

    rect rgb(20, 40, 40)
        Note over EMP,WS: Desktop Access
        Note over EMP: Connect to OpenVPN
        EMP->>Route53: DNS Lookup firstname.lastname.innovatech.local
        Route53-->>EMP: NodeIP (10.0.x.x)
        EMP->>WS: HTTPS via VPN to NodeIP:NodePort
        WS-->>EMP: 🖥️ Ubuntu Desktop via noVNC
    end
```

---

## 🖥️ Workspace Pod Architecture

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#f60', 'lineColor': '#0ff'}}}%%
flowchart TB
    subgraph POD["📦 Workspace Pod"]
        subgraph CONTAINER["🐳 linux-desktop container"]
            UBUNTU["🐧 Ubuntu 22.04"]
            XFCE["🖼️ XFCE Desktop"]
            VNC["📺 TigerVNC :5901"]
            NOVNC["🌐 noVNC :6080"]
            
            subgraph TOOLS["🛠️ Pre-installed"]
                FF["Firefox"]
                TERM["Terminal"]
                PUTTY["PuTTY"]
                AWSCLI["AWS CLI"]
            end
        end
        
        SA["🔐 ServiceAccount\n(IRSA)"]
    end
    
    subgraph SVC["☸️ Kubernetes"]
        SERVICE["Service :6080"]
        LB["⚖️ LoadBalancer"]
    end
    
    UBUNTU --> XFCE
    XFCE --> VNC
    VNC --> NOVNC
    NOVNC --> SERVICE
    SERVICE --> LB
    SA -.->|"AWS Credentials"| CONTAINER
    
    style POD fill:#1a1a2e,stroke:#f60,color:#fff
    style CONTAINER fill:#2a2a4e,stroke:#0ff,color:#fff
    style UBUNTU fill:#f60,stroke:#f60,color:#000
    style NOVNC fill:#0ff,stroke:#0ff,color:#000
    style LB fill:#0f0,stroke:#0f0,color:#000
    style SA fill:#f0f,stroke:#f0f,color:#000
```

---

## 🔐 Security Architecture

### IRSA (IAM Roles for Service Accounts)

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#f0f', 'lineColor': '#0ff'}}}%%
flowchart LR
    subgraph K8S["☸️ Kubernetes"]
        subgraph SA["ServiceAccounts"]
            DEV["developer-sa"]
            HRR["hr-sa"]
            MGR["manager-sa"]
            ADM["admin-sa"]
            INF["infra-sa"]
        end
    end
    
    subgraph IAM["🔐 AWS IAM"]
        R1["developer-role"]
        R2["hr-role"]
        R3["manager-role"]
        R4["admin-role"]
        R5["infra-role"]
    end
    
    subgraph PERMS["📋 Permissions"]
        S3["📁 S3 Buckets"]
        SSM["🔧 SSM Params"]
        DDB["💾 DynamoDB"]
        EC2["💻 EC2"]
    end
    
    DEV --> R1 --> S3
    HRR --> R2 --> DDB
    MGR --> R3 --> S3 & SSM
    ADM --> R4 --> S3 & SSM & DDB
    INF --> R5 --> EC2 & SSM
    
    style DEV fill:#0ff,stroke:#0ff,color:#000
    style HRR fill:#0f0,stroke:#0f0,color:#000
    style MGR fill:#ff0,stroke:#ff0,color:#000
    style ADM fill:#f0f,stroke:#f0f,color:#000
    style INF fill:#f60,stroke:#f60,color:#000
```

### Network Security

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0ff', 'lineColor': '#f0f'}}}%%
flowchart TB
    subgraph INTERNET["🌐 Internet"]
        USER["Users"]
    end
    
    subgraph VPC["VPC"]
        subgraph PUB["Public Subnets"]
            NLB["⚖️ NLB"]
        end
        
        subgraph PRIV["Private Subnets"]
            subgraph EKS["EKS"]
                NS1["hr-portal"]
                NS2["workspaces"]
            end
        end
        
        subgraph SG["🛡️ Security Groups"]
            SG1["EKS Nodes SG"]
            SG2["VPC Endpoints SG"]
        end
    end
    
    USER -->|"HTTP 80"| NLB
    NLB --> NS1 & NS2
    NS1 <-.->|"Blocked"| NS2
    
    style NLB fill:#0ff,stroke:#0ff,color:#000
    style NS1 fill:#0f0,stroke:#0f0,color:#000
    style NS2 fill:#f60,stroke:#f60,color:#000
    style SG fill:#f0f,stroke:#f0f,color:#fff
```

---

## 🏢 AWS Infrastructure

### Terraform Modules

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#7B42BC', 'lineColor': '#0ff'}}}%%
flowchart TB
    subgraph TF["🏗️ Terraform"]
        MAIN["main.tf"]
        
        subgraph MODULES["📦 Modules"]
            VPC["vpc"]
            EKS["eks"]
            IAM["iam"]
            DDB["dynamodb"]
            ECR["ecr"]
            SSM["systems-manager"]
            SG["security-groups"]
            VPE["vpc-endpoints"]
        end
    end
    
    MAIN --> VPC & EKS & IAM & DDB & ECR & SSM & SG & VPE
    VPC --> EKS
    IAM --> EKS
    SG --> EKS & VPE
    
    style MAIN fill:#7B42BC,stroke:#7B42BC,color:#fff
    style VPC fill:#0ff,stroke:#0ff,color:#000
    style EKS fill:#0f0,stroke:#0f0,color:#000
    style IAM fill:#f0f,stroke:#f0f,color:#000
    style DDB fill:#ff0,stroke:#ff0,color:#000
```

### Resource Summary

| Resource | Name | Details |
|----------|------|---------|
| 🌐 **VPC** | innovatech-vpc | 10.0.0.0/16, 2 AZs |
| ☸️ **EKS** | innovatech-employee-lifecycle | v1.29, Managed Nodes |
| 💾 **DynamoDB** | employees, workspaces | On-demand capacity |
| 📦 **ECR** | hr-portal-*, workspace | Container registry |
| 🔐 **Directory** | innovatech.local | AWS Managed AD |
| 🔧 **SSM** | /innovatech-*/* | Secrets & config |

---

## 🔄 CI/CD Pipeline

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0f0', 'lineColor': '#0ff'}}}%%
flowchart LR
    subgraph GH["GitHub"]
        PUSH["📤 Push to main"]
    end
    
    subgraph ACTIONS["⚡ GitHub Actions"]
        BUILD["🔨 Build Images"]
        PUSH2["📦 Push to ECR"]
        DEPLOY["🚀 Deploy to EKS"]
    end
    
    subgraph AWS["☁️ AWS"]
        ECR["📦 ECR"]
        EKS["☸️ EKS"]
    end
    
    PUSH --> BUILD --> PUSH2 --> DEPLOY
    PUSH2 --> ECR
    DEPLOY --> EKS
    
    style PUSH fill:#0f0,stroke:#0f0,color:#000
    style BUILD fill:#ff0,stroke:#ff0,color:#000
    style ECR fill:#f0f,stroke:#f0f,color:#000
    style EKS fill:#0ff,stroke:#0ff,color:#000
```

### Pipeline Triggers

| Path | Action |
|------|--------|
| `applications/hr-portal/**` | Rebuild HR Portal |
| `applications/workspace/**` | Rebuild Workspace Image |
| `kubernetes/**` | Apply K8s manifests |
| `terraform/**` | (Manual) Terraform apply |

---

## 📊 Data Flow

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#f0f', 'lineColor': '#0ff'}}}%%
flowchart LR
    subgraph INPUT["📝 Input"]
        FORM["Employee Form"]
    end
    
    subgraph STORE["💾 Storage"]
        DDB1["employees table"]
        DDB2["workspaces table"]
    end
    
    subgraph COMPUTE["☸️ Compute"]
        POD["Workspace Pod"]
    end
    
    subgraph OUTPUT["🖥️ Output"]
        DESK["Linux Desktop"]
    end
    
    FORM -->|"name, email,\ndept, role"| DDB1
    DDB1 -->|"trigger"| POD
    POD -->|"url, password"| DDB2
    POD --> DESK
    
    style FORM fill:#0f0,stroke:#0f0,color:#000
    style DDB1 fill:#f0f,stroke:#f0f,color:#000
    style DDB2 fill:#f0f,stroke:#f0f,color:#000
    style POD fill:#ff0,stroke:#ff0,color:#000
    style DESK fill:#0ff,stroke:#0ff,color:#000
```

---

## ✅ Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| 🌐 HR Portal | ✅ Working | React + Node.js |
| 💾 DynamoDB | ✅ Working | employees + workspaces |
| 🖥️ Workspaces | ✅ Working | Ubuntu + noVNC |
| 🔐 IRSA | ✅ Deployed | Per-department SAs |
| 🏢 AD | ⚠️ Ready | Code ready, needs SSM password |
| 📧 Email | ❌ Disabled | SES configured but not sending |

---

<p align="center">
  <sub>🏗️ Terraform • ☸️ Kubernetes • 🐳 Docker • ☁️ AWS</sub>
</p>
