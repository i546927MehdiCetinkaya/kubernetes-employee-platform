# Deployment Status - Casestudy 3

**Laatste Update:** 7 november 2025, 15:40  
**Workflow Run:** #36 (ID: 19169229126) - ✅ **SUCCESSFUL**

## 🎯 Wat is er Deployed?

### 1. **AWS Infrastructure** (via Terraform)

#### EKS Cluster
- **Naam:** `innovatech-employee-lifecycle`
- **Status:** ✅ ACTIVE
- **Versie:** 1.28
- **Region:** eu-west-1
- **Endpoint:** https://C7FAE0239EF9984A419F089D450C2BF2.gr7.eu-west-1.eks.amazonaws.com
- **Public Access:** Enabled
- **Private Access:** Enabled

#### VPC & Networking
- **VPC ID:** vpc-00b55e0bb43e24878
- **CIDR:** 10.0.0.0/16
- **Public Subnets:** 3 (eu-west-1a/b/c)
  - subnet-0bb695ec9f0aac482
  - subnet-0e46c5348be7af56c
  - subnet-0727060f7809ff2dd
- **Private Subnets:** 3 (eu-west-1a/b/c)
  - subnet-0fe31e8bcc057e65b
  - subnet-022895eed394fceb8
  - subnet-01dd6f9a2eba7772d

#### VPC Endpoints
- **DynamoDB:** vpce-0473b36c7839224b5 (gateway)
- **ECR API:** vpce-0cde788820942b57d (interface)
- **ECR DKR:** vpce-00f8273f041154110 (interface)

#### DynamoDB
- **Table:** `innovatech-employees`
- **Status:** ✅ ACTIVE
- **Items:** 2 (test data)
- **ARN:** arn:aws:dynamodb:eu-west-1:920120424621:table/innovatech-employees

#### ECR Repositories
1. **hr-portal-backend**
   - URI: 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-backend
   - Status: ✅ Created (images gepusht)

2. **hr-portal-frontend**
   - URI: 920120424621.dkr.ecr.eu-west-1.amazonaws.com/hr-portal-frontend
   - Status: ✅ Created (images gepusht)

3. **employee-workspace**
   - URI: 920120424621.dkr.ecr.eu-west-1.amazonaws.com/employee-workspace
   - Status: ✅ Created (images gepusht)

#### IAM Roles
- **EKS Cluster Role:** innovatech-employee-lifecycle-cluster-role
- **Node Role:** innovatech-employee-lifecycle-node-role (ARN: arn:aws:iam::920120424621:role/innovatech-employee-lifecycle-node-role)
- **HR Portal ServiceAccount:** innovatech-employee-lifecycle-hr-portal-role
- **Workspace ServiceAccount:** innovatech-employee-lifecycle-workspace-role
- **GitHub Actions Role:** githubrepo

#### CloudWatch Logs
- **Log Group:** /aws/eks/innovatech-employee-lifecycle
- **Retention:** 30 days

### 2. **Kubernetes Resources** (Deployed via kubectl)

De workflow heeft de volgende manifests toegepast:
- ✅ Namespaces (kubernetes/namespaces.yaml)
- ✅ RBAC (kubernetes/rbac.yaml)
- ✅ Network Policies (kubernetes/network-policies.yaml)
- ✅ HR Portal app (kubernetes/hr-portal.yaml)

**⚠️ Status onbekend** - Kan niet verifiëren omdat kubectl toegang ontbreekt (zie hieronder).

### 3. **Container Images**

Alle images zijn gebouwd en gepusht naar ECR:
- Tags: `latest` en commit SHA (14/b7/6)
- Image scan: gestart (vulnerabilities check)

---

## ⚠️ Huidige Probleem: Kubectl Toegang

### Wat is het Probleem?
Je AWS SSO role (`AWSReservedSSO_fictisb_IsbUsersPS_2f9b7e07b8441d9f`) heeft geen toegang tot het EKS cluster omdat deze niet is toegevoegd aan de `aws-auth` ConfigMap in de `kube-system` namespace.

### Waarom?
- EKS clusters gebruiken een ConfigMap genaamd `aws-auth` om IAM roles/users te mappen naar Kubernetes RBAC
- De Terraform configuratie heeft deze ConfigMap niet aangemaakt
- Alleen de GitHub Actions role (`githubrepo`) heeft momenteel cluster admin toegang (gebruikt door de workflow)

### Wat Betekent Dit?
- ✅ AWS CLI werkt perfect (je hebt AdministratorAccess)
- ✅ Deployment via GitHub Actions werkt
- ❌ Kubectl commando's vanaf jouw laptop werken niet
- ❌ Je kunt pods, services, ingress niet bekijken

---

## 🔧 Hoe Toegang te Krijgen (3 Opties)

### Optie 1: AWS-Auth ConfigMap Toevoegen (RECOMMENDED)

**Stap 1:** Voeg deze resource toe aan `terraform/modules/eks/main.tf`:

```terraform
# Toevoegen onderaan het bestand, voor de laatste closing brace

# AWS Auth ConfigMap for EKS Access
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = "arn:aws:iam::920120424621:role/githubrepo"
        username = "github-actions"
        groups   = ["system:masters"]
      },
      {
        rolearn  = "arn:aws:iam::920120424621:role/AWSReservedSSO_fictisb_IsbUsersPS_2f9b7e07b8441d9f"
        username = "admin"
        groups   = ["system:masters"]
      }
    ])
  }

  force = true

  depends_on = [aws_eks_cluster.main]
}
```

**Stap 2:** Run Terraform apply:
```powershell
cd terraform
terraform init
terraform plan
terraform apply
```

**Stap 3:** Test kubectl:
```powershell
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle --profile fictisb_IsbUsersPS-920120424621 --alias casestudy3
kubectl config use-context casestudy3
kubectl get nodes
```

### Optie 2: Gebruik GitHub Actions om ConfigMap aan te maken

**Stap 1:** Maak `.github/workflows/fix-eks-access.yml`:

```yaml
name: Fix EKS Access

on:
  workflow_dispatch:

jobs:
  add-user-access:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::920120424621:role/githubrepo
          aws-region: eu-west-1

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: v1.28.4

      - name: Configure kubectl
        run: |
          aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle

      - name: Apply aws-auth ConfigMap
        run: |
          cat <<EOF | kubectl apply -f -
          apiVersion: v1
          kind: ConfigMap
          metadata:
            name: aws-auth
            namespace: kube-system
          data:
            mapRoles: |
              - rolearn: arn:aws:iam::920120424621:role/innovatech-employee-lifecycle-node-role
                username: system:node:{{EC2PrivateDNSName}}
                groups:
                  - system:bootstrappers
                  - system:nodes
              - rolearn: arn:aws:iam::920120424621:role/githubrepo
                username: github-actions
                groups:
                  - system:masters
              - rolearn: arn:aws:iam::920120424621:role/AWSReservedSSO_fictisb_IsbUsersPS_2f9b7e07b8441d9f
                username: admin
                groups:
                  - system:masters
          EOF

      - name: Verify access
        run: kubectl get nodes
```

**Stap 2:** Run workflow via GitHub UI (Actions tab → Fix EKS Access → Run workflow)

### Optie 3: Temporary - Gebruik Exec Script in Pod

Als je NU iets wilt zien zonder toegang te fixen:

```powershell
# Via AWS CLI kun je wel een command in een pod runnen (als ze draaien)
aws eks describe-cluster --name innovatech-employee-lifecycle --region eu-west-1 --profile fictisb_IsbUsersPS-920120424621

# Check CloudWatch logs voor pod output
aws logs tail /aws/eks/innovatech-employee-lifecycle --follow --profile fictisb_IsbUsersPS-920120424621
```

---

## 📋 Deployment Verificatie Checklist

Als je kubectl toegang hebt (na fix), run deze commando's:

```powershell
# 1. Cluster info
kubectl cluster-info
kubectl get nodes

# 2. Check namespaces
kubectl get namespaces

# 3. HR Portal resources
kubectl get all -n hr-portal
kubectl get pods -n hr-portal -o wide
kubectl get svc -n hr-portal
kubectl get ingress -n hr-portal

# 4. Check ConfigMaps
kubectl get configmap -n hr-portal

# 5. Check Services
kubectl get svc -n hr-portal -o wide

# 6. Pod logs
kubectl logs -n hr-portal -l app=hr-portal-backend --tail=50
kubectl logs -n hr-portal -l app=hr-portal-frontend --tail=50

# 7. Check LoadBalancer/Ingress URL
kubectl get ingress -n hr-portal -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

---

## 🚀 Volgende Stappen (Na Toegang Fix)

### 1. Verifieer Deployment
```powershell
# Script gebruiken
.\scripts\test-all-services.ps1

# Of handmatig:
kubectl get pods -n hr-portal
kubectl get svc -n hr-portal
```

### 2. Test HR Portal API
```powershell
# Get LoadBalancer URL
$LB_URL = kubectl get ingress -n hr-portal -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'

# Test endpoints (zodra DNS propagated is - kan 5-10 min duren)
curl "http://$LB_URL/api/employees"
curl "http://$LB_URL/"
```

### 3. Check DynamoDB Connectivity
```powershell
# List employees in DynamoDB
aws dynamodb scan --table-name innovatech-employees --region eu-west-1 --profile fictisb_IsbUsersPS-920120424621
```

### 4. Monitor Logs
```powershell
# CloudWatch
aws logs tail /aws/eks/innovatech-employee-lifecycle/cluster --follow --profile fictisb_IsbUsersPS-920120424621

# Kubectl (na toegang)
kubectl logs -f -n hr-portal -l app=hr-portal-backend
```

---

## 📝 Snelle Commando's

### AWS CLI (Werkt NU)
```powershell
# Set profile voor sessie
$env:AWS_PROFILE="fictisb_IsbUsersPS-920120424621"

# Check resources
aws eks list-clusters --region eu-west-1
aws dynamodb list-tables --region eu-west-1
aws ecr describe-repositories --region eu-west-1

# Get outputs van deployment
gh run download 19169229126 --repo i546927MehdiCetinkaya/casestudy3 -n terraform-outputs
Get-Content .\terraform-outputs\outputs.json | ConvertFrom-Json | ConvertTo-Json
```

### Kubectl (Werkt NA fix)
```powershell
# Login refresh
aws sso login --profile fictisb_IsbUsersPS-920120424621

# Kubeconfig update
aws eks update-kubeconfig --region eu-west-1 --name innovatech-employee-lifecycle --profile fictisb_IsbUsersPS-920120424621 --alias casestudy3

# Use context
kubectl config use-context casestudy3

# Basic commands
kubectl get all -A
kubectl get pods -n hr-portal
```

---

## 🔍 Troubleshooting

### "error: You must be logged in"
→ Je SSO role is niet in aws-auth ConfigMap (zie Optie 1 of 2 hierboven)

### "The security token included in the request is invalid"
```powershell
# SSO session expired, refresh:
aws sso login --profile fictisb_IsbUsersPS-920120424621
```

### "No resources found in hr-portal namespace"
→ Pods zijn mogelijk nog niet gestart of crashen. Check:
```powershell
kubectl describe pods -n hr-portal
kubectl logs -n hr-portal <pod-name>
```

### DNS/LoadBalancer URL werkt niet
→ DNS propagatie duurt 5-10 minuten. Check status:
```powershell
kubectl describe ingress -n hr-portal
nslookup <alb-url>
```

---

## 📊 Resource Overzicht

| Resource Type | Naam | Status | Regio |
|--------------|------|--------|-------|
| EKS Cluster | innovatech-employee-lifecycle | ✅ ACTIVE | eu-west-1 |
| VPC | vpc-00b55e0bb43e24878 | ✅ ACTIVE | eu-west-1 |
| DynamoDB | innovatech-employees | ✅ ACTIVE | eu-west-1 |
| ECR Repos | 3 repositories | ✅ ACTIVE | eu-west-1 |
| CloudWatch | Logs enabled | ✅ ACTIVE | eu-west-1 |
| Kubectl Access | aws-auth ConfigMap | ❌ MISSING | - |

---

**🎉 Samenvatting:** Deployment is succesvol, maar je hebt kubectl toegang nodig. Volg Optie 1 (Terraform) of Optie 2 (GitHub Actions workflow) om dit op te lossen!
