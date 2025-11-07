# HR Portal - Employee Lifecycle Management

Een moderne webapplicatie voor het beheren van employee lifecycle management, inclusief onboarding, offboarding, en workspace provisioning.

## 🚀 Quick Start (Lokaal Testen)

### Optie 1: Automatisch starten (Aanbevolen)

Vanuit de root directory:
```powershell
.\scripts\start-fullstack-local.ps1
```

Dit start automatisch beide servers:
- Backend (Mock Server): http://localhost:3001
- Frontend: http://localhost:3000

### Optie 2: Handmatig starten

**Terminal 1 - Backend:**
```powershell
.\scripts\start-backend.ps1
```

**Terminal 2 - Frontend:**
```powershell
.\scripts\start-frontend.ps1
```

### Optie 3: Direct via npm

**Backend:**
```powershell
cd applications\hr-portal\backend
npm install
npm run mock
```

**Frontend:**
```powershell
cd applications\hr-portal\frontend
npm install
npm start
```

## 📋 Features

### Frontend
- ✨ Modern Material-UI interface
- 📊 Employee lijst met filters
- ➕ Employee toevoegen met form validatie
- ✏️ Employee gegevens updaten
- 🗑️ Employee verwijderen met confirmatie
- 🔄 Real-time data updates
- 🎨 Responsive design
- 🏷️ Role en status badges

### Backend
- 🔥 RESTful API
- 📦 Mock server voor lokaal testen (geen AWS nodig!)
- 🔐 Authentication endpoints (basis)
- 🗄️ In-memory database voor development
- 📝 Request logging
- ⚡ Fast response times

### Mock vs Productie Backend

| Feature | Mock Server | Productie |
|---------|-------------|-----------|
| Database | In-memory | AWS DynamoDB |
| Workspaces | ❌ Gesimuleerd | ✅ Kubernetes |
| AWS | ❌ Niet nodig | ✅ Vereist |
| Persistentie | ❌ Tijdelijk | ✅ Permanent |

## 📁 Project Structuur

```
applications/hr-portal/
├── backend/
│   ├── src/
│   │   ├── index.js           # Main backend (AWS/K8s)
│   │   ├── routes/
│   │   │   ├── auth.js        # Authentication
│   │   │   ├── employees.js   # Employee CRUD
│   │   │   └── workspaces.js  # Workspace management
│   │   ├── services/
│   │   │   ├── dynamodb.js    # DynamoDB operations
│   │   │   └── workspace.js   # K8s workspace provisioning
│   │   └── utils/
│   │       └── logger.js      # Logging utility
│   ├── mock-server.js         # Mock server (lokaal testen)
│   ├── package.json
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── App.js             # Main React component
│   │   ├── index.js           # Entry point
│   │   └── index.css          # Global styles
│   ├── public/
│   │   └── index.html
│   ├── package.json
│   ├── .env                   # Environment variables
│   └── Dockerfile
└── README.md                  # Dit bestand
```

## 🔧 API Endpoints

### Health Check
```
GET /health
```
Response: `{ "status": "healthy" }`

### Employees

**Alle employees ophalen:**
```
GET /api/employees
```
Response:
```json
{
  "employees": [
    {
      "employeeId": "1",
      "firstName": "John",
      "lastName": "Doe",
      "email": "john.doe@company.com",
      "role": "developer",
      "department": "Engineering",
      "status": "active",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

**Employee ophalen:**
```
GET /api/employees/:id
```

**Employee aanmaken:**
```
POST /api/employees
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@company.com",
  "role": "developer",
  "department": "Engineering"
}
```

**Employee updaten:**
```
PUT /api/employees/:id
Content-Type: application/json

{
  "role": "manager",
  "department": "Management"
}
```

**Employee verwijderen:**
```
DELETE /api/employees/:id
```

## 🧪 Testen

### API Testen met PowerShell

```powershell
# Health check
Invoke-RestMethod -Uri "http://localhost:3001/health"

# Alle employees
Invoke-RestMethod -Uri "http://localhost:3001/api/employees"

# Employee aanmaken
$body = @{
    firstName = "Alice"
    lastName = "Johnson"
    email = "alice.johnson@example.com"
    role = "developer"
    department = "Engineering"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3001/api/employees" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

# Employee verwijderen
Invoke-RestMethod -Uri "http://localhost:3001/api/employees/1" `
    -Method Delete
```

### Browser Testen

1. Open http://localhost:3000
2. Klik op "Add Employee" om een nieuwe employee toe te voegen
3. Vul het formulier in en klik "Create Employee"
4. Klik op het prullenbak icoon om een employee te verwijderen

## 🌍 Environment Variabelen

### Backend (.env)
```env
PORT=3001
NODE_ENV=development
```

### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:3001
PORT=3000
```

## 📦 Dependencies

### Backend
- express - Web framework
- cors - CORS middleware
- helmet - Security headers
- aws-sdk - AWS DynamoDB (productie)
- @kubernetes/client-node - K8s client (productie)
- winston - Logging
- uuid - ID generation
- bcryptjs - Password hashing
- jsonwebtoken - JWT authentication

### Frontend
- react - UI library
- react-dom - React DOM rendering
- react-router-dom - Routing
- @mui/material - Material-UI components
- @mui/icons-material - Material-UI icons
- axios - HTTP client
- @emotion/react - Styling
- @emotion/styled - Styled components

## 🐛 Troubleshooting

### Port already in use

```powershell
# Stop backend (port 3001)
Get-Process -Id (Get-NetTCPConnection -LocalPort 3001).OwningProcess | Stop-Process

# Stop frontend (port 3000)
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process
```

### Dependencies niet geïnstalleerd

```powershell
# Backend
cd applications\hr-portal\backend
Remove-Item -Recurse -Force node_modules
npm install

# Frontend
cd applications\hr-portal\frontend
Remove-Item -Recurse -Force node_modules
npm install
```

### Backend geeft errors

Controleer of je de **mock server** gebruikt (geen AWS credentials nodig):
```powershell
cd applications\hr-portal\backend
npm run mock
```

In plaats van:
```powershell
npm start  # Dit gebruikt de echte backend met AWS!
```

### Frontend kan backend niet bereiken

1. Controleer of backend draait op http://localhost:3001
2. Test met: `Invoke-RestMethod -Uri "http://localhost:3001/health"`
3. Check `.env` file in frontend directory
4. Herstart beide servers

## 🚢 Deployment

Voor productie deployment:
1. Build frontend: `npm run build` in frontend directory
2. Gebruik de echte backend (niet mock server)
3. Deploy naar AWS EKS via Terraform + Kubernetes
4. Zie hoofddocumentatie voor details

## 📚 Meer Informatie

- [Architecture Documentation](../../docs/ARCHITECTURE.md)
- [Local Testing Guide](./START_LOCAL.md)
- [Deployment Guide](../../README.md)

## 🤝 Support

Bij problemen:
1. Check de console output (F12 in browser)
2. Check terminal logs van backend/frontend
3. Zie troubleshooting sectie hierboven
