# 🔍 Hoe te Controleren: DynamoDB, Kubernetes & VMs

## Huidige Situatie

Je gebruikt nu de **MOCK SERVER** 🎭
- ✅ Werkt lokaal perfect
- ❌ Geen data in DynamoDB
- ❌ Geen Kubernetes workspaces
- ❌ Geen VMs/containers
- ⚠️ Data verdwijnt bij herstart

## Om Echte Infrastructure Te Gebruiken

### Stap 1: Check wat je hebt

**Check AWS:**
```powershell
.\scripts\check-dynamodb.ps1
```

**Check Kubernetes:**
```powershell
.\scripts\check-k8s-workspaces.ps1
```

### Stap 2: Start Echte Backend

**Automatisch (met checks):**
```powershell
.\scripts\start-backend-real.ps1
```

**Of handmatig:**
```powershell
cd applications\hr-portal\backend
$env:PORT = "3001"
$env:AWS_REGION = "eu-west-1"
npm start  # NIET npm run mock!
```

### Stap 3: Test met Frontend

1. Frontend blijft op http://localhost:3000 draaien
2. Maak een employee aan via UI
3. Check DynamoDB:
   ```powershell
   .\scripts\check-dynamodb.ps1
   ```
4. Check Kubernetes (na ~30 sec):
   ```powershell
   .\scripts\check-k8s-workspaces.ps1
   ```

## 🗂️ DynamoDB Checken

### Via Script (Makkelijkst):
```powershell
.\scripts\check-dynamodb.ps1
```

Output:
```
========================================
  EMPLOYEES IN DYNAMODB
========================================

Employee:
  ID: 123e4567-e89b-12d3-a456-426614174000
  Name: John Doe
  Email: john.doe@example.com
  Role: developer
  Department: Engineering
  Status: active
  Created: 2024-11-07T10:30:00.000Z

Total: 1 employees
```

### Via AWS CLI:
```powershell
# List alle employees
aws dynamodb scan --table-name innovatech-employees

# Count employees
aws dynamodb scan --table-name innovatech-employees --select "COUNT"

# Get specifieke employee
aws dynamodb get-item --table-name innovatech-employees --key '{"employeeId":{"S":"YOUR-ID-HERE"}}'
```

### Via AWS Console:
1. Open https://console.aws.amazon.com/dynamodb
2. Klik "Tables" in sidebar
3. Klik op "innovatech-employees"
4. Klik "Explore table items"
5. Zie alle employees

## ☸️ Kubernetes Checken

### Via Script (Makkelijkst):
```powershell
.\scripts\check-k8s-workspaces.ps1
```

Output:
```
========================================
  WORKSPACE PODS
========================================

Found 2 workspace pods:

NAME              READY   STATUS    RESTARTS   AGE
john-doe          1/1     Running   0          5m
jane-smith        1/1     Running   0          3m
```

### Via kubectl:
```powershell
# Alle workspace pods
kubectl get pods -n workspaces

# Workspace details
kubectl describe pod john-doe -n workspaces

# Workspace logs
kubectl logs john-doe -n workspaces

# Alle workspace services
kubectl get services -n workspaces

# Workspace URLs (ingresses)
kubectl get ingresses -n workspaces
```

### Via Kubernetes Dashboard:
```powershell
# Start dashboard
kubectl proxy

# Open in browser:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## 🖥️ VMs/Containers Checken

### Workspaces zijn Kubernetes Pods:
Elke employee krijgt een pod (container) met:
- VS Code Server (code-server)
- Persistent storage (PVC)
- Eigen URL via Ingress
- Resource limits (CPU/Memory)

**Check pod details:**
```powershell
# Pod info
kubectl get pod john-doe -n workspaces -o yaml

# Pod resource usage
kubectl top pod john-doe -n workspaces

# Access pod shell
kubectl exec -it john-doe -n workspaces -- /bin/bash
```

## 📊 Complete Infrastructure Check

### All-in-One Check:
```powershell
# Check alles
Write-Host "`n=== AWS ===" -ForegroundColor Cyan
aws sts get-caller-identity

Write-Host "`n=== DynamoDB ===" -ForegroundColor Cyan
.\scripts\check-dynamodb.ps1

Write-Host "`n=== Kubernetes ===" -ForegroundColor Cyan
.\scripts\check-k8s-workspaces.ps1

Write-Host "`n=== EKS Cluster ===" -ForegroundColor Cyan
aws eks list-clusters
```

## 🔄 Workflow Overzicht

### Mock Server (Huidige):
```
Frontend → Mock Server (Port 3001) → In-Memory Array
          └─ Geen AWS
          └─ Geen Kubernetes
          └─ Data verdwijnt
```

### Echte Backend:
```
Frontend → Real Backend (Port 3001) → DynamoDB (Employees)
                                    → Kubernetes (Workspaces)
                                    → AWS EKS Cluster
                                    → Pods/Services/Ingresses
```

## 🎯 Wat Gebeurt Bij Employee Aanmaken

### Met Mock Server:
1. POST naar /api/employees
2. Employee opgeslagen in memory array
3. Fake workspace URL gegenereerd
4. ❌ Niets in DynamoDB
5. ❌ Geen Kubernetes pod

### Met Echte Backend:
1. POST naar /api/employees
2. ✅ Employee opgeslagen in DynamoDB
3. ✅ Kubernetes provisioning gestart:
   - PersistentVolumeClaim (PVC) aangemaakt
   - Secret met credentials aangemaakt
   - Pod met VS Code Server gestart
   - Service aangemaakt (ClusterIP)
   - Ingress aangemaakt (externe URL)
4. ✅ Workspace URL beschikbaar
5. ✅ Employee kan inloggen op workspace

## 📝 Quick Reference

| Check | Command |
|-------|---------|
| DynamoDB | `.\scripts\check-dynamodb.ps1` |
| Kubernetes | `.\scripts\check-k8s-workspaces.ps1` |
| Start Echte Backend | `.\scripts\start-backend-real.ps1` |
| AWS Identity | `aws sts get-caller-identity` |
| Tables | `aws dynamodb list-tables` |
| Pods | `kubectl get pods -n workspaces` |
| Services | `kubectl get services -n workspaces` |
| Ingresses | `kubectl get ingresses -n workspaces` |

## ⚠️ Vereisten voor Echte Backend

Moet gedeployed zijn:
- [ ] AWS Account met credentials
- [ ] DynamoDB tables (via Terraform)
- [ ] EKS Cluster (via Terraform)
- [ ] Kubernetes namespace `workspaces`
- [ ] IAM roles voor workspace provisioner
- [ ] Load Balancer Controller (voor Ingresses)
- [ ] Storage class voor PVCs

Check infrastructure status:
```powershell
cd terraform
terraform show
```

## 🚀 Deploy Infrastructure (als nog niet gedaan)

```powershell
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan

# Deploy everything
terraform apply
```

Dit deployt:
- VPC & Networking
- EKS Cluster
- DynamoDB Tables
- IAM Roles
- Security Groups
- Systems Manager Parameters

## 💡 Tips

1. **Start met Mock Server** - Perfect voor UI development
2. **Deploy Infrastructure** - Alleen als je echt AWS resources wilt
3. **Test DynamoDB eerst** - Voordat je Kubernetes test
4. **Check Logs** - kubectl logs voor troubleshooting
5. **Use Scripts** - Automatische checks zijn makkelijker

## 🆘 Troubleshooting

### "Cannot access DynamoDB"
```powershell
aws configure
# Voer credentials in
```

### "Cannot connect to Kubernetes"
```powershell
aws eks update-kubeconfig --region eu-west-1 --name your-cluster-name
```

### "Workspace pod pending"
```powershell
kubectl describe pod <pod-name> -n workspaces
# Check events voor errors
```

### "Table not found"
```powershell
cd terraform
terraform apply
# Deploy tables eerst
```

## 📚 Meer Info

- [Switch to Real Backend](SWITCH_TO_REAL_BACKEND.md) - Gedetailleerde guide
- [Architecture Docs](docs/ARCHITECTURE.md) - System overzicht
- [Terraform Docs](terraform/README.md) - Infrastructure setup
