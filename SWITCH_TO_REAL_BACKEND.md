# Switch naar ECHTE Backend (met AWS/DynamoDB/K8s)

## Huidige Situatie
Je gebruikt nu de **MOCK server** die alleen in-memory werkt.
Geen data gaat naar DynamoDB of Kubernetes.

## Om echte backend te gebruiken:

### Stap 1: Stop de Mock Server
Druk op `Ctrl+C` in het backend terminal venster

### Stap 2: Configureer AWS Credentials
Je hebt AWS credentials nodig. Check of je die hebt:

```powershell
aws configure list
```

Als je geen credentials hebt, configureer ze:
```powershell
aws configure
```

Je hebt nodig:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (bijv: eu-west-1)

### Stap 3: Check DynamoDB Tables
Controleer of de DynamoDB tables bestaan:

```powershell
aws dynamodb list-tables
```

Je zou moeten zien:
- `innovatech-employees` (of jouw table naam)
- `innovatech-employees-workspaces`

### Stap 4: Start de ECHTE Backend

In plaats van mock server:

```powershell
cd applications\hr-portal\backend
$env:PORT = "3001"
$env:NODE_ENV = "development"
$env:AWS_REGION = "eu-west-1"
$env:DYNAMODB_TABLE = "innovatech-employees"
$env:DYNAMODB_WORKSPACES_TABLE = "innovatech-employees-workspaces"
npm start  # NIET npm run mock!
```

### Stap 5: Frontend blijft hetzelfde
De frontend hoeft niet te wijzigen, die praat nog steeds met http://localhost:3001

## Check of het werkt

### Test DynamoDB Connection:
```powershell
# Maak een employee aan via de UI
# Dan check in DynamoDB:
aws dynamodb scan --table-name innovatech-employees
```

### Check Kubernetes Workspaces:
```powershell
# Als je EKS cluster hebt:
kubectl get pods -n workspaces
kubectl get services -n workspaces
```

## Verschillen Mock vs Echte Backend

| Feature | Mock Server | Echte Backend |
|---------|-------------|---------------|
| Command | `npm run mock` | `npm start` |
| Database | In-memory | AWS DynamoDB |
| Workspaces | ❌ Gesimuleerd | ✅ K8s Pods |
| Data Persistentie | ❌ Verdwijnt | ✅ Blijft bestaan |
| AWS Credentials | ❌ Niet nodig | ✅ Vereist |
| K8s Cluster | ❌ Niet nodig | ✅ Vereist |

## Script voor Echte Backend

Ik kan een script maken dat automatisch checkt of alles is geconfigureerd en dan de echte backend start.

Wil je dat ik dat maak? Dan check ik:
- ✅ AWS credentials aanwezig
- ✅ DynamoDB tables bestaan
- ✅ EKS cluster bereikbaar
- ✅ Kubernetes namespace bestaat
- ✅ Start echte backend met correcte env vars

## Waarschuwing ⚠️

De echte backend vereist:
1. AWS account met DynamoDB toegang
2. EKS cluster voor workspace provisioning
3. Correcte IAM roles en permissions
4. Terraform infrastructure deployed

Als je die nog niet hebt, moet je eerst:
```powershell
# Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply
```

## Makkelijkste Oplossing voor Nu

Als je alleen wilt **testen of DynamoDB werkt** zonder Kubernetes:

1. Deploy alleen de DynamoDB tables met Terraform
2. Comment out de workspace provisioning code
3. Start de echte backend
4. Test employee CRUD operations

Wil je dat ik je help om:
- [ ] Script maken voor echte backend
- [ ] Workspace provisioning uitschakelen (alleen DynamoDB)
- [ ] Complete infrastructure deployen
- [ ] Blijven met mock server (voor lokaal testen)

Wat wil je doen?
