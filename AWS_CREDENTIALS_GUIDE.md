# AWS Credentials Blijven Werken

## Probleem

Je AWS credentials zijn **temporary session tokens** die automatisch verlopen na een paar uur.
Dit is normaal voor AWS SSO (Single Sign-On) of temporary credentials.

## Oplossingen

### Optie 1: Auto-Refresh Script (AANBEVOLEN)

Gebruik dit script dat automatisch om nieuwe credentials vraagt:

```powershell
.\scripts\start-backend-auto-refresh.ps1
```

Dit script:
- ✅ Checkt of credentials geldig zijn
- ✅ Vraagt om nieuwe credentials als ze verlopen zijn
- ✅ Start backend automatisch
- ✅ Werkt altijd!

### Optie 2: Handmatig Refreshen

Als credentials verlopen zijn:

**Stap 1: Haal nieuwe credentials**
1. Ga naar AWS Console: https://console.aws.amazon.com
2. Login met je account
3. Klik rechtsboven op je naam → "Security Credentials"
4. Klik "Create access key"
5. Kopieer Access Key ID en Secret Access Key

**Stap 2: Update credentials**
```powershell
aws configure
```
Plak de nieuwe credentials

**Stap 3: Start backend**
```powershell
.\scripts\start-backend-dynamodb.ps1
```

### Optie 3: AWS CLI met Lange Termijn Credentials

Voor credentials die NIET verlopen:

**Stap 1: Maak IAM User aan (via AWS Console)**
1. IAM Console → Users → Create User
2. Geef naam: `hr-portal-dev`
3. Attach policies: `AmazonDynamoDBFullAccess`
4. Create access key → CLI
5. Download credentials

**Stap 2: Configureer**
```powershell
aws configure --profile hr-portal
```

**Stap 3: Gebruik dit profiel**
Voeg toe aan `.env`:
```
AWS_PROFILE=hr-portal
```

## Hoe Lang Blijven Credentials Geldig?

| Type | Geldigheid |
|------|------------|
| Temporary SSO | 1-12 uur |
| Session Token | 15 min - 36 uur |
| IAM User Keys | **Permanent** (tot je ze verwijdert) |

## Aanbeveling voor School Project

### Voor Demonstratie (Korte Termijn):
✅ Gebruik het auto-refresh script
✅ Refresh credentials elke keer voor je demonstreert
✅ Makkelijk en snel

### Voor Ontwikkeling (Lange Termijn):
✅ Maak IAM User met lange termijn keys
✅ Credentials blijven werken
✅ Geen herhaaldelijk refreshen nodig

## Quick Commands

### Check of credentials werken:
```powershell
aws sts get-caller-identity
```

### Refresh credentials:
```powershell
aws configure
# Plak nieuwe credentials
```

### Start backend met auto-refresh:
```powershell
.\scripts\start-backend-auto-refresh.ps1
```

### Check DynamoDB:
```powershell
aws dynamodb scan --table-name innovatech-employees --region eu-west-1
```

## Troubleshooting

### "ExpiredToken" error
→ Credentials zijn verlopen
→ Run: `.\scripts\start-backend-auto-refresh.ps1`
→ Script vraagt om nieuwe credentials

### "Invalid credentials" error
→ Verkeerde credentials
→ Check AWS Console voor nieuwe keys
→ Run: `aws configure`

### "Table does not exist" error
→ DynamoDB tables niet aangemaakt
→ Run: `cd terraform && terraform apply -target="module.dynamodb"`

## Wat Ik Heb Gedaan

✅ DynamoDB tables aangemaakt (blijven bestaan)
✅ Auto-refresh script gemaakt
✅ Credentials configuratie
✅ Backend scripts met DynamoDB

De **tables blijven bestaan** - alleen je **credentials** verlopen.
Gebruik het auto-refresh script en je bent altijd klaar!
