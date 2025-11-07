# 🔑 Hoe krijg je de juiste AWS Credentials?

## ❌ PROBLEEM: Wat je FOUT deed

Je plakte dit:
```powershell
$Env:AWS_ACCESS_KEY_ID="ASIA5MO3TPCWYS4J26M3"
$Env:AWS_SECRET_ACCESS_KEY="t5YNiZIkCLmI++2xXfBO7zEMqH/5gREg7B6PzrOS"
$Env:AWS_SESSION_TOKEN="IQoJb3JpZ2luX2VjE..."
```

**Dat zijn PowerShell COMMANDS, niet de credentials zelf!**

---

## ✅ OPLOSSING: Wat je GOED moet doen

Plak ALLEEN de waarde tussen de quotes:

```
ASIA5MO3TPCWYS4J26M3
t5YNiZIkCLmI++2xXfBO7zEMqH/5gREg7B6PzrOS
IQoJb3JpZ2luX2VjE...
```

---

## 📋 Stap voor stap: Credentials ophalen

### Optie 1: Van je docent/admin (MAKKELIJKST)

1. Vraag aan je docent: "Kan ik nieuwe AWS credentials krijgen voor mijn project?"
2. Je krijgt 3 dingen:
   - **AWS Access Key ID** (bijv: `ASIA5MO3TPCWYS4J26M3`)
   - **AWS Secret Access Key** (bijv: `t5YNiZIkCLmI++2xXfBO7zEMqH/5gREg7B6PzrOS`)
   - **AWS Session Token** (hele lange string)
3. Kopieer deze waarden naar een notitiebestand

### Optie 2: Zelf genereren via AWS Console

1. Open: https://console.aws.amazon.com
2. Login met je studentenaccount
3. Klik rechtsboven op je naam
4. Klik **"Security Credentials"**
5. Scroll naar **"Access Keys"**
6. Klik **"Create Access Key"**
7. Selecteer **"CLI"** als use case
8. Download het `.csv` bestand OF kopieer de keys direct

**LET OP**: Als je temporary credentials gebruikt (met session token), verlopen deze na een paar uur!

---

## 🚀 Hoe gebruik je ze?

### Methode 1: Via het nieuwe script (AANBEVOLEN)

```powershell
.\scripts\fix-credentials.ps1
```

Het script vraagt je om:
1. Access Key ID → plak alleen `ASIA5MO3TPCWYS4J26M3`
2. Secret Access Key → plak alleen `t5YNiZIkCLmI++2xXfBO7zEMqH/5gREg7B6PzrOS`
3. Session Token → plak alleen `IQoJb3JpZ2luX2VjE...`

Script test ze automatisch en start de backend!

### Methode 2: Handmatig configureren

```powershell
aws configure
```

Voer in:
- **AWS Access Key ID**: `ASIA5MO3TPCWYS4J26M3`
- **AWS Secret Access Key**: `t5YNiZIkCLmI++2xXfBO7zEMqH/5gREg7B6PzrOS`
- **Default region name**: `eu-west-1`
- **Default output format**: `json`

**MAAR**: Dit werkt NIET voor session tokens! Gebruik dan Methode 1.

---

## 🔍 Hoe check je of het werkt?

```powershell
aws sts get-caller-identity
```

### Als het werkt, zie je:
```json
{
    "UserId": "...",
    "Account": "920120424621",
    "Arn": "arn:aws:sts::920120424621:assumed-role/..."
}
```

### Als het NIET werkt, zie je:
```
An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

---

## ⏰ Credentials verlopen steeds?

Je gebruikt **temporary credentials** (AWS SSO). Die verlopen na een paar uur.

### Permanente oplossing:

Vraag je docent om **permanente IAM user credentials** in plaats van temporary SSO tokens.

**Verschil**:
- ❌ Temporary (SSO): Verlopen na paar uur, moet steeds opnieuw inloggen
- ✅ Permanent (IAM User): Blijven werken tot je ze verwijdert

---

## 📞 Hulp nodig?

1. Run: `.\scripts\fix-credentials.ps1`
2. Volg de instructies PRECIES
3. Plak ALLEEN de waarden, niet de PowerShell commands
4. Als het nog steeds niet werkt: vraag nieuwe credentials aan je docent

**Common mistakes:**
- ❌ `$Env:AWS_ACCESS_KEY_ID="..."` → verkeerd formaat
- ❌ Oude/expired credentials gebruiken
- ❌ Verkeerde region (moet `eu-west-1` zijn)
- ✅ Gewoon de waarde plakken zonder `$Env:` of quotes

---

## 🎯 Snel overzicht

| Wat je hebt | Wat je moet doen |
|-------------|------------------|
| PowerShell commands | Kopieer alleen de waarde tussen de quotes |
| Oude credentials | Vraag nieuwe aan |
| Geen session token | Vraag complete set met session token |
| Credentials werken niet | Check of ze nog geldig zijn met `aws sts get-caller-identity` |

---

**Ready?** Run gewoon:
```powershell
.\scripts\fix-credentials.ps1
```

En plak de waarden ZONDER `$Env:` enzo! 🚀
