# Check Kubernetes Workspaces
# Dit script laat zien welke employee workspaces in Kubernetes draaien

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  KUBERNETES WORKSPACES CHECK" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check kubectl
Write-Host "[1/3] Checking kubectl..." -ForegroundColor Yellow
try {
    $k8sVersion = kubectl version --client --short 2>&1
    Write-Host "      ✓ kubectl installed" -ForegroundColor Green
} catch {
    Write-Host "      ✗ kubectl not found!" -ForegroundColor Red
    Write-Host "`nInstall kubectl: https://kubernetes.io/docs/tasks/tools/" -ForegroundColor Yellow
    exit 1
}

# Check cluster connection
Write-Host "`n[2/3] Checking cluster connection..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes --no-headers 2>&1
    if ($LASTEXITCODE -eq 0) {
        $nodeCount = ($nodes | Measure-Object -Line).Lines
        Write-Host "      ✓ Connected to cluster ($nodeCount nodes)" -ForegroundColor Green
    } else {
        Write-Host "      ✗ Cannot connect to cluster!" -ForegroundColor Red
        Write-Host "`nConfigure cluster access:" -ForegroundColor Yellow
        Write-Host "  aws eks update-kubeconfig --region eu-west-1 --name your-cluster-name" -ForegroundColor White
        exit 1
    }
} catch {
    Write-Host "      ✗ Cannot connect to cluster!" -ForegroundColor Red
    exit 1
}

# Check workspaces namespace
Write-Host "`n[3/3] Checking workspaces namespace..." -ForegroundColor Yellow
$namespace = "workspaces"

try {
    kubectl get namespace $namespace 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      ✓ Namespace '$namespace' exists" -ForegroundColor Green
    } else {
        Write-Host "      ⚠ Namespace '$namespace' not found" -ForegroundColor Yellow
        Write-Host "`nCreate namespace:" -ForegroundColor Yellow
        Write-Host "  kubectl create namespace $namespace" -ForegroundColor White
        Write-Host ""
        $createNS = Read-Host "Create namespace now? (y/n)"
        if ($createNS -eq "y") {
            kubectl create namespace $namespace
            Write-Host "      ✓ Namespace created" -ForegroundColor Green
        } else {
            exit 1
        }
    }
} catch {
    Write-Host "      ✗ Cannot check namespace!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  WORKSPACE PODS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get pods
try {
    $pods = kubectl get pods -n $namespace --no-headers 2>&1
    if ($LASTEXITCODE -eq 0 -and $pods) {
        $podCount = ($pods | Measure-Object -Line).Lines
        Write-Host "Found $podCount workspace pods:" -ForegroundColor Green
        Write-Host ""
        
        kubectl get pods -n $namespace -o wide
        
    } else {
        Write-Host "No workspace pods found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Workspaces will be created when you:" -ForegroundColor Gray
        Write-Host "  1. Create an employee via the frontend" -ForegroundColor White
        Write-Host "  2. Using the REAL backend (not mock server)" -ForegroundColor White
        Write-Host ""
    }
} catch {
    Write-Host "Cannot list pods" -ForegroundColor Red
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  WORKSPACE SERVICES" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get services
try {
    $services = kubectl get services -n $namespace --no-headers 2>&1
    if ($LASTEXITCODE -eq 0 -and $services) {
        $svcCount = ($services | Measure-Object -Line).Lines
        Write-Host "Found $svcCount workspace services:" -ForegroundColor Green
        Write-Host ""
        
        kubectl get services -n $namespace
        
    } else {
        Write-Host "No workspace services found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Cannot list services" -ForegroundColor Red
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  INGRESSES" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get ingresses
try {
    $ingresses = kubectl get ingresses -n $namespace --no-headers 2>&1
    if ($LASTEXITCODE -eq 0 -and $ingresses) {
        $ingCount = ($ingresses | Measure-Object -Line).Lines
        Write-Host "Found $ingCount workspace ingresses:" -ForegroundColor Green
        Write-Host ""
        
        kubectl get ingresses -n $namespace
        
    } else {
        Write-Host "No workspace ingresses found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Cannot list ingresses" -ForegroundColor Red
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commands:" -ForegroundColor Cyan
Write-Host "  View pods: kubectl get pods -n workspaces" -ForegroundColor White
Write-Host "  View logs: kubectl logs <pod-name> -n workspaces" -ForegroundColor White
Write-Host "  Delete pod: kubectl delete pod <pod-name> -n workspaces" -ForegroundColor White
Write-Host "  Describe pod: kubectl describe pod <pod-name> -n workspaces" -ForegroundColor White
Write-Host ""
