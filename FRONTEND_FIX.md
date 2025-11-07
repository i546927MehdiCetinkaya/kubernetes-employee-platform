# Frontend API URL Fix 🔧

## Het Probleem

Toen je probeerde een employee toe te voegen in de browser, kreeg je een **Network Error**:

```
AxiosError: Network Error
url: "http://localhost:3000/api/employees"
```

De frontend probeerde te verbinden met `localhost:3000` in plaats van de LoadBalancer URL.

## Waarom Dit Gebeurde

In `applications/hr-portal/frontend/src/App.js` stond:

```javascript
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';
```

React environment variables werken alleen tijdens **build time**, niet runtime. En omdat de frontend in de **browser** draait (client-side), moet het het publieke LoadBalancer adres gebruiken, NIET een interne Kubernetes service naam.

## De Oplossing ✅

Ik heb de code aangepast naar:

```javascript
// API configuration - use same origin (LoadBalancer handles routing)
const API_BASE_URL = process.env.REACT_APP_API_URL || window.location.origin;
```

Nu gebruikt de frontend **automatisch** het juiste adres:
- **Lokaal:** `http://localhost:3000`
- **AWS:** `http://k8s-hrportal-hrportal-936a6c829f-1479683540.eu-west-1.elb.amazonaws.com`

Dit werkt omdat:
1. De frontend en backend zitten achter **dezelfde LoadBalancer**
2. De Ingress routeert `/api/*` → backend en `/*` → frontend
3. `window.location.origin` geeft de URL waar de browser de pagina vandaan heeft gehaald

## Hoe Te Activeren

### Optie 1: Lokaal Bouwen (Snelst)

1. **Start Docker Desktop**

2. **Run het rebuild script:**
   ```powershell
   .\scripts\rebuild-frontend-local.ps1
   ```

   Dit script doet:
   - Login to ECR
   - Build nieuwe frontend image met de fix
   - Push naar ECR
   - Restart Kubernetes deployment
   - Wait tot rollout compleet is

3. **Wacht 1-2 minuten** voor de nieuwe pods volledig ready zijn

4. **Test in browser:**
   - Open: http://k8s-hrportal-hrportal-936a6c829f-1479683540.eu-west-1.elb.amazonaws.com
   - **Hard refresh** (Ctrl+Shift+R of Ctrl+F5) om cache te legen
   - Probeer een employee toe te voegen

### Optie 2: GitHub Workflow (Na OIDC Fix)

De GitHub Actions OIDC credentials zijn momenteel verlopen. Om via workflow te deployen:

1. Fix de OIDC trust policy in AWS IAM (buiten scope voor nu)
2. Run de workflow:
   ```powershell
   gh workflow run rebuild-frontend.yml --repo i546927MehdiCetinkaya/casestudy3
   ```

## Verificatie

Na de rebuild, test je dit:

```powershell
# Check pod status
kubectl get pods -n hr-portal -l app=hr-portal-frontend

# Test frontend
curl http://k8s-hrportal-hrportal-936a6c829f-1479683540.eu-west-1.elb.amazonaws.com/

# Test backend via frontend route
curl http://k8s-hrportal-hrportal-936a6c829f-1479683540.eu-west-1.elb.amazonaws.com/api/employees
```

Alle endpoints zouden `200 OK` moeten geven.

## Alternatieve Oplossing (Niet Nodig Nu)

Als je de frontend en backend op verschillende LoadBalancers zou hebben, zou je een **nginx.conf configuratie** moeten gebruiken met een `/config.js` die runtime geladen wordt:

```javascript
// In /public/config.js (niet hardcoded in bundle)
window.ENV = {
  API_URL: 'http://backend-lb-url.com'
};

// In App.js
const API_BASE_URL = window.ENV?.API_URL || window.location.origin;
```

Maar omdat beide achter dezelfde LB zitten, is `window.location.origin` de beste oplossing.

## Status

- ✅ **Code aangepast:** `applications/hr-portal/frontend/src/App.js`
- ✅ **Committed en gepushed:** commit `262e06f`
- ✅ **Script gemaakt:** `scripts/rebuild-frontend-local.ps1`
- ⏳ **Deployment:** Pending Docker Desktop start
- 🔧 **GitHub Actions:** OIDC credentials need refresh

## Next Step

**Start Docker Desktop en run:**
```powershell
.\scripts\rebuild-frontend-local.ps1
```

Dan zal de frontend correct werken! 🚀
