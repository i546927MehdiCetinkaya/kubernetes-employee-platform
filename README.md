# InnovaTech Employee Lifecycle Platform
Automated employee onboarding system that provisions cloud workspaces and sends instant email credentials.

 **Architecture Diagram**: See [ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## What is this?
A cloud-native HR platform that automatically creates dedicated development workspaces for new employees. When HR submits employee details, the system provisions a containerized VS Code environment and emails access credentials within minutes.

---

## The Problem
Traditional onboarding requires manual server setup, VPN configuration, and software installation. This takes days and creates security risks through shared credentials and inconsistent environments.

---

## The Solution
This system:

- Captures employee data via web portal
- Stores records in DynamoDB
- Provisions workspace pods on Kubernetes
- Configures LoadBalancer routing
- Sends email with login credentials

---

## How Does It Work?
**HR Portal  Backend API  DynamoDB  Kubernetes  Workspace Pod  Email Alert**

**Ingress**: Validates employee form data  
**Store**: Writes record to DynamoDB  
**Provision**: Deploys workspace pod via Kubernetes Job  
**Route**: Updates LoadBalancer with employee subdomain  
**Notify**: Sends credentials via SES email

---

## Network Architecture

- HR portal and workspaces run in EKS cluster on private subnets
- Application LoadBalancer handles HTTPS traffic from internet
- VPC Endpoints provide private AWS service access
- No NAT Gateway needed - all communication via VPC endpoints
- No VPN needed - LoadBalancer publicly accessible via HTTPS

---

## Workspace Resources

| Resource | Allocation |
|----------|-----------|
| CPU | 2 vCPU |
| Memory | 4GB RAM |
| Storage | 20GB persistent |

Each workspace includes VS Code, Git, Docker, and terminal access.

---

## Technology

**AWS Services**:
- EKS (Kubernetes cluster)
- DynamoDB (employee database)
- SES (email notifications)
- ECR (container registry)
- VPC (isolated networking)
- CloudWatch (monitoring)

**Infrastructure**:
- Terraform (IaC)
- GitHub Actions (CI/CD)

---

## Deployment
Fully automated via GitHub Actions on every push to main branch.

---

## Project Structure
```
casestudy3/
 applications/          # HR portal + workspace apps
 terraform/            # Infrastructure as Code
 kubernetes/           # K8s manifests
 scripts/             # Helper scripts
 .github/             # CI/CD workflows
```

---

## Academic Context
**Case Study 3** | Fontys University of Applied Sciences | Semester 3 | 2025  
Demonstrates cloud-native architecture, Infrastructure as Code, and container orchestration.

**Student**: Mehdi Cetinkaya