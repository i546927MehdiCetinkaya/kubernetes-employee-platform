# Start HR Portal Lokaal

Deze guide laat je zien hoe je de HR Portal lokaal kunt draaien voor ontwikkeling en testing, **zonder AWS credentials of Kubernetes**.

## Wat je nodig hebt

- Node.js (v18 of hoger)
- npm of yarn

## Quick Start

### Optie 1: PowerShell Scripts (Aanbevolen)

#### Start Backend (Mock Server):
```powershell
cd applications\hr-portal\backend
npm install
npm run mock
```

De mock server draait nu op: **http://localhost:3001**

#### Start Frontend (in nieuwe terminal):
```powershell
cd applications\hr-portal\frontend
npm install
npm start
```

De frontend draait nu op: **http://localhost:3000**

### Optie 2: Gebruik de Start Scripts

#### Windows PowerShell:
```powershell
# Backend starten
.\scripts\start-backend.ps1

# Frontend starten (in nieuwe terminal)
.\scripts\start-frontend.ps1
```

## Wat is de Mock Server?

De **mock server** (`mock-server.js`) is een lichtgewicht test server die:
- ✅ Geen AWS credentials nodig heeft
- ✅ Geen DynamoDB of andere AWS services nodig heeft
- ✅ Werkt volledig in-memory (data verdwijnt bij herstart)
- ✅ Perfect voor lokale ontwikkeling en testing
- ✅ Gebruikt dezelfde API endpoints als de echte backend

## Functionaliteit

De mock server ondersteunt alle belangrijke operaties:

### Employees API
- `GET /api/employees` - Alle employees ophalen
- `GET /api/employees/:id` - Specifieke employee ophalen
- `POST /api/employees` - Nieuwe employee aanmaken
- `PUT /api/employees/:id` - Employee updaten
- `DELETE /api/employees/:id` - Employee verwijderen

### Health Check
- `GET /health` - Server status checken

## Frontend Features

De frontend applicatie biedt:
- 📋 **Employee Lijst** - Bekijk alle employees
- ➕ **Employee Toevoegen** - Maak nieuwe employees aan
- ✏️ **Employee Bewerken** - Update employee gegevens
- 🗑️ **Employee Verwijderen** - Verwijder employees (met confirmatie)
- 🔄 **Real-time Updates** - Automatisch verversen van data
- 🎨 **Material UI Design** - Modern en gebruiksvriendelijk interface

## Testen

### API Testen met PowerShell:

```powershell
# Check server health
Invoke-RestMethod -Uri "http://localhost:3001/health"

# Haal alle employees op
Invoke-RestMethod -Uri "http://localhost:3001/api/employees"

# Maak een nieuwe employee aan
$body = @{
    firstName = "John"
    lastName = "Doe"
    email = "john.doe@example.com"
    role = "developer"
    department = "Engineering"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3001/api/employees" -Method Post -Body $body -ContentType "application/json"
```

## Environment Variabelen

### Backend (.env)
```
PORT=3001
NODE_ENV=development
```

### Frontend (.env)
```
REACT_APP_API_URL=http://localhost:3001
PORT=3000
```

## Verschillen met Productie Backend

| Feature | Mock Server | Productie Backend |
|---------|-------------|-------------------|
| Database | In-memory | AWS DynamoDB |
| Workspace Provisioning | ❌ Gesimuleerd | ✅ Kubernetes |
| AWS Credentials | ❌ Niet nodig | ✅ Vereist |
| Data Persistentie | ❌ Tijdelijk | ✅ Permanent |
| Authentication | ❌ Basis | ✅ JWT + Auth |

## Troubleshooting

### Port al in gebruik?
```powershell
# Stop proces op port 3001
Get-Process -Id (Get-NetTCPConnection -LocalPort 3001).OwningProcess | Stop-Process

# Stop proces op port 3000
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process
```

### Dependencies installeren:
```powershell
# Backend
cd applications\hr-portal\backend
npm install

# Frontend
cd applications\hr-portal\frontend
npm install
```

### Clean install:
```powershell
# Backend
cd applications\hr-portal\backend
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
npm install

# Frontend
cd applications\hr-portal\frontend
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
npm install
```

## Volgende Stappen

Zodra je klaar bent met lokaal ontwikkelen en testen:

1. **Test met echte backend**: Gebruik de volledige backend met AWS/K8s
2. **Deploy naar productie**: Gebruik de Terraform en Kubernetes configuraties
3. **Zie documentation**: Check `docs/ARCHITECTURE.md` voor meer info

## Support

Bij problemen, check:
- Browser console voor frontend errors (F12)
- Terminal output voor backend errors
- `applications/hr-portal/backend/mock-server.js` voor API implementatie
