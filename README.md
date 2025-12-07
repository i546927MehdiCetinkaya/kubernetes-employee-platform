# 🚀 InnovaTech Employee Lifecycle Platform - Release v1.0

> **Automated employee onboarding with cloud-native Linux workspaces**

[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Workspaces-326CE5?style=flat-square&logo=kubernetes)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform)](https://www.terraform.io/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square)](https://github.com)

**🎉 Release v1.0 - Fully Functional Employee Workspace Platform**

---

## 📋 Overview

A cloud-native HR platform that **automatically provisions Linux desktop workspaces** for new employees. When HR submits employee details, the system creates a containerized Ubuntu desktop accessible via web browser with automatic DNS records.

### ✅ What's Working in v1.0

- ✅ **Complete HR Portal** with employee management
- ✅ **Automated workspace provisioning** (2-5 minute setup)
- ✅ **Automatic DNS records** (`firstname.lastname.innovatech.local`)
- ✅ **VPN access** with OpenVPN + DNS resolution
- ✅ **Real-time provisioning status** with live polling
- ✅ **Official Kasm desktop image** (kasmweb/desktop:1.14.0)
- ✅ **Production-grade timeouts** (10 minutes for workspace startup)
- ✅ **NAT instance** for AWS API access
- ✅ **Route53 private DNS** with resolver endpoints
- ✅ **Custom DNS for HR Portal** (`hr-portal.innovatech.local:30080`)

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0ff', 'primaryTextColor': '#fff', 'primaryBorderColor': '#0ff', 'lineColor': '#f0f', 'secondaryColor': '#0f0', 'tertiaryColor': '#1a1a2e'}}}%%
flowchart LR
    subgraph INPUT[" "]
        HR["👤 HR User"]
    end
    
    subgraph CLOUD["☁️ AWS Cloud"]
        Portal["🌐 HR Portal"]
        API["⚡ Backend"]
        DB[("💾 DynamoDB")]
        K8S["☸️ EKS"]
        WS["🖥️ Workspace"]
    end
    
    subgraph OUTPUT[" "]
        EMP["👨‍💻 Employee"]
    end
    
    HR -->|1. Create| Portal
    Portal --> API
    API --> DB
    API -->|2. Provision| K8S
    K8S --> WS
    WS -->|3. Access| EMP
    
    style Portal fill:#0ff,stroke:#0ff,color:#000
    style API fill:#0f0,stroke:#0f0,color:#000
    style DB fill:#f0f,stroke:#f0f,color:#000
    style K8S fill:#ff0,stroke:#ff0,color:#000
    style WS fill:#f60,stroke:#f60,color:#000
```

---

## ⚡ Quick Start

### 🌐 Access Requirements

#### 1️⃣ **VPN Connection** (Required for workspace access)
```
OpenVPN Server: 54.195.44.238
Config: Download from HR Portal or administrator
```

#### 2️⃣ **HR Portal URL** (Public access)
```
http://ac0cd11d903e646dc890a3606c5999df-8a0c923d8bfa6cfe.elb.eu-west-1.amazonaws.com
```

### 📝 Employee Onboarding Workflow

#### **For HR Administrators:**
1. **Login** → HR Portal with Cognito credentials
2. **Create Employee** → Fill in: First Name, Last Name, Email, Department, Role
3. **Provision Workspace** → Click "Provision Workspace" (wait ~2 min)
4. **Share Credentials** → Give employee VPN config + workspace URL + password

#### **For Employees:**
1. **Connect VPN** → Use OpenVPN client with provided config
2. **Access Workspace** → Navigate to personal URL: `https://firstname.lastname.innovatech.local:PORT`
3. **Login** → Use provided password
4. **Work** → Full Ubuntu desktop with Firefox, Terminal, AWS CLI, PuTTY

### 🔗 Personal Workspace URLs

Elke medewerker krijgt een **persoonlijke DNS record** in Route53:
- **Format**: `https://firstname.lastname.innovatech.local:PORT`
- **Voorbeeld**: `https://jan.jansen.innovatech.local:30123`
- **DNS Zone**: Private Hosted Zone `innovatech.local` (Route53)
- **Toegang**: Alleen via VPN (wijst naar EKS node IP in private subnet)
- **Auto-Cleanup**: DNS record wordt verwijderd bij workspace deprovision

Each employee gets a **personal DNS record**:
```
Format: https://{firstname}.{lastname}.innovatech.local:{port}
Example: https://john.doe.innovatech.local:30123

✅ Automatic DNS record creation in Route53
✅ No more localhost:6901 port-forwards
✅ Production-ready URLs
✅ Automatic cleanup on deprovision
```

---

## 🏗️ Architecture

📖 **Detailed docs**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

### 🔄 Workspace Provisioning Flow

```mermaid
%%{init: {'theme': 'dark'}}%%
sequenceDiagram
    participant HR as 👤 HR User
    participant Portal as 🌐 Frontend
    participant API as ⚡ Backend
    participant DDB as 💾 DynamoDB
    participant K8S as ☸️ Kubernetes
    participant R53 as 🌐 Route53
    participant WS as 🖥️ Workspace Pod
    
    HR->>Portal: Create Employee
    Portal->>API: POST /employees
    API->>DDB: Store employee data
    API-->>Portal: Employee created
    
    HR->>Portal: Provision Workspace
    Portal->>API: POST /workspaces
    API->>DDB: Check for duplicates
    API->>K8S: Create Pod + Service
    K8S->>WS: Start container
    WS-->>K8S: Ready (200 OK)
    K8S-->>API: Pod Running + NodePort
    API->>R53: Create A record (firstname.lastname.innovatech.local)
    API->>DDB: Store workspace info
    API-->>Portal: Workspace URL + password
    Portal-->>HR: Display personal URL
```

### 🔐 DNS-Based Access Control

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart LR
    subgraph EMPLOYEE["👤 Employee"]
        VPN["🔒 OpenVPN Client"]
        BROWSER["🌐 Browser"]
    end
    
    subgraph AWS["☁️ AWS"]
        R53["🌐 Route53\ninnovatech.local"]
        NODE["🖥️ EKS Node"]
    end
    
    VPN -->|Connect| NODE
    BROWSER -->|1. DNS Query\njohn.doe.innovatech.local| R53
    R53 -->|2. Returns Node IP\n10.0.58.37| BROWSER
    BROWSER -->|3. HTTPS:30123| NODE
    NODE -->|4. Route to Pod| WS["🖥️ Workspace"]
    
    style R53 fill:#0ff,color:#000
    style WS fill:#f60,color:#000
```

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#0ff', 'lineColor': '#f0f'}}}%%
flowchart TB
    subgraph INTERNET["🌐 Internet"]
        USER["👤 Users"]
    end
    
    subgraph AWS["☁️ AWS eu-west-1"]
        subgraph VPC["VPC 10.0.0.0/16"]
            NLB["⚖️ Load Balancers"]
            
            subgraph EKS["☸️ EKS Cluster"]
                FE["React\nFrontend"]
                BE["Node.js\nBackend"]
                W1["🖥️ Workspace 1"]
                W2["🖥️ Workspace 2"]
                W3["🖥️ Workspace N"]
            end
        end
        
        DDB[("💾 DynamoDB")]
        ECR["📦 ECR"]
        AD["🔐 AD"]
    end
    
    USER --> NLB
    NLB --> FE & W1 & W2 & W3
    FE --> BE
    BE --> DDB
    BE --> EKS
    EKS -.-> ECR
    EKS -.-> AD
    
    style NLB fill:#0ff,stroke:#0ff,color:#000
    style FE fill:#0f0,stroke:#0f0,color:#000
    style BE fill:#0f0,stroke:#0f0,color:#000
    style DDB fill:#f0f,stroke:#f0f,color:#000
    style W1 fill:#f60,stroke:#f60,color:#000
    style W2 fill:#f60,stroke:#f60,color:#000
    style W3 fill:#f60,stroke:#f60,color:#000
```

---

## 🖥️ Workspace Features

| Tool | Description |
|------|-------------|
| 🐧 **Ubuntu 22.04** | Linux desktop via browser |
| 🖼️ **XFCE** | Lightweight desktop |
| 🌐 **Firefox** | Web browser |
| 💻 **Terminal** | xfce4-terminal |
| 🔒 **PuTTY** | SSH client |
| ☁️ **AWS CLI** | Cloud access (IRSA) |

---

## 🔐 Security Model

### 🛡️ Multi-Layer Security

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#f0f', 'lineColor': '#0ff'}}}%%
flowchart TB
    subgraph NETWORK["🌐 Network Security"]
        VPN["🔒 OpenVPN\nVPN Required"]
        SG["🔥 Security Groups\nPrivate Subnets"]
    end
    
    subgraph K8S["☸️ Kubernetes Security"]
        NP["🚫 Network Policies\nNamespace Isolation"]
        IRSA["🎫 IRSA\nNo Static Keys"]
        RBAC["👮 RBAC\nRole-Based Access"]
    end
    
    subgraph APP["🔐 Application Security"]
        COG["🔑 Cognito\nHR Authentication"]
        DNS["🌐 Route53\nPrivate DNS Zone"]
    end
    
    VPN --> SG
    SG --> NP
    NP --> IRSA
    IRSA --> RBAC
    COG --> DNS
    
    style VPN fill:#f0f,color:#fff
    style IRSA fill:#0ff,color:#000
    style COG fill:#0f0,color:#000
```

### 📋 Department-Based Permissions (IRSA)

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#f0f', 'lineColor': '#0ff'}}}%%
flowchart LR
    subgraph DEPT["🏢 Department IRSA"]
        DEV["💻 developer-sa"]
        HR["👥 hr-sa"]
        MGR["📊 manager-sa"]
        ADM["🔑 admin-sa"]
    end
    
    subgraph AWS["☁️ AWS Permissions"]
        S3["📁 S3"]
        SSM["🔧 SSM"]
        DDB["💾 DynamoDB"]
        R53["🌐 Route53"]
    end
    
    DEV --> S3
    HR --> DDB & R53
    MGR --> S3 & SSM
    ADM --> S3 & SSM & DDB & R53
    
    style DEV fill:#0ff,stroke:#0ff,color:#000
    style HR fill:#0f0,stroke:#0f0,color:#000
    style MGR fill:#ff0,stroke:#ff0,color:#000
    style ADM fill:#f0f,stroke:#f0f,color:#000
```

### ✅ Security Features

| Feature | Status | Description |
|---------|--------|-------------|
| **VPN Access** | ✅ | OpenVPN required for workspace access |
| **Private DNS** | ✅ | Route53 Private Hosted Zone (innovatech.local) |
| **IRSA** | ✅ | No static credentials in containers |
| **Network Policies** | ✅ | Namespace isolation in Kubernetes |
| **Private Subnets** | ✅ | All pods in private subnets (10.0.64.0/19, 10.0.96.0/19) |
| **Cognito Auth** | ✅ | HR Portal authentication |
| **AD Integration** | ⚠️ | Ready (innovatech.local) - Not yet in use |
| **Duplicate Prevention** | ✅ | Backend checks prevent multiple workspaces per employee |

---

## 📁 Project Structure

```
📦 casestudy3
├── 📂 applications/
│   ├── 📂 hr-portal/          # React + Node.js
│   └── 📂 workspace/          # Ubuntu desktop container
├── 📂 kubernetes/             # K8s manifests
├── 📂 terraform/              # AWS infrastructure (IaC)
├── 📂 .github/workflows/      # CI/CD pipeline
└── 📂 docs/                   # Documentation
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| ☁️ **Cloud** | AWS (EKS, DynamoDB, ECR, VPC) |
| 🏗️ **IaC** | Terraform |
| 🐳 **Container** | Docker, Kubernetes |
| ⚡ **Backend** | Node.js, Express |
| 🎨 **Frontend** | React |
| 🖥️ **Desktop** | Ubuntu, XFCE, TigerVNC, noVNC |
| 🔄 **CI/CD** | GitHub Actions |

---

## 📊 AWS Resources

| Resource | Value |
|----------|-------|
| **EKS Cluster** | `innovatech-employee-lifecycle` |
| **Region** | `eu-west-1` (Ireland) |
| **VPC** | `10.0.0.0/16` |
| **Directory** | `innovatech.local` |

---

<p align="center">
  <sub>☁️ AWS • ☸️ Kubernetes • 🐳 Docker • 🎓 Fontys S3 2025</sub>
</p>