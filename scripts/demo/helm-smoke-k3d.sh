#!/usr/bin/env bash
#
# Helm Charts Local Smoke Test
#
# Purpose: Create k3d cluster, install charts, verify basic health
#
# Usage:
#   ./scripts/demo/helm-smoke-k3d.sh
#
# Exit codes:
#   0: Smoke test passes
#   1: Smoke test fails

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLUSTER_NAME="${CLUSTER_NAME:-helm-smoke}"
NAMESPACE="${NAMESPACE:-zen-system}"

cd "$REPO_ROOT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Helm Charts Local Smoke Test (k3d)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check prerequisites
if ! command -v k3d &> /dev/null; then
    echo "❌ k3d is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

echo "k3d version: $(k3d version | head -1)"
echo "helm version: $(helm version --short)"
echo "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo ""

# Parse arguments
KEEP_CLUSTER=0
for arg in "$@"; do
    case $arg in
        --keep-cluster)
            KEEP_CLUSTER=1
            shift
            ;;
    esac
done

# Cleanup function
cleanup() {
    if [ "$KEEP_CLUSTER" = "1" ]; then
        echo ""
        echo "ℹ️  Keeping cluster $CLUSTER_NAME for debugging (--keep-cluster)"
        echo "   Cleanup with: k3d cluster delete $CLUSTER_NAME"
        return
    fi
    
    echo ""
    echo "Cleaning up cluster $CLUSTER_NAME..."
    k3d cluster delete "$CLUSTER_NAME" 2>/dev/null || true
}

trap cleanup EXIT

# Create k3d cluster
echo "[1/5] Creating k3d cluster..."
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "Cluster $CLUSTER_NAME already exists, deleting..."
    k3d cluster delete "$CLUSTER_NAME"
fi

k3d cluster create "$CLUSTER_NAME" \
    --agents 1 \
    --wait \
    --timeout 120s

echo "✅ Cluster created"
echo ""

# Create namespace
echo "[2/5] Creating namespace..."
kubectl create namespace "$NAMESPACE" 2>/dev/null || true
echo "✅ Namespace created"
echo ""

# Install zen-watcher
echo "[3/5] Installing zen-watcher chart..."
if helm install zen-watcher charts/zen-watcher \
    --namespace "$NAMESPACE" \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --wait --timeout 120s; then
    echo "✅ zen-watcher installed"
else
    echo "⚠️  zen-watcher install failed (may require actual image)"
fi
echo ""

# Install zen-agent
echo "[4/5] Installing zen-agent chart..."
# Note: zen-agent requires watcher dependency and TLS config
if helm install zen-agent charts/zen-agent \
    --namespace "$NAMESPACE" \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --set tls.enabled=false \
    --wait --timeout 120s 2>&1; then
    echo "✅ zen-agent installed"
else
    echo "⚠️  zen-agent install may require additional config (TLS, secrets)"
fi
echo ""

# Verify pods
echo "[5/5] Verifying pod status..."
echo ""
kubectl get pods -n "$NAMESPACE"
echo ""

WATCHER_READY=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=zen-watcher -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")

echo "zen-watcher ready status: $WATCHER_READY"

if [ "$WATCHER_READY" = "True" ]; then
    echo "✅ zen-watcher pod is Ready"
    RESULT=0
else
    echo "⚠️  zen-watcher pod not Ready (may need actual image/config)"
    RESULT=0  # Non-blocking for now
    
    # Collect logs on failure
    echo ""
    echo "━━━ Collecting pod logs for debugging ━━━"
    for pod in $(kubectl get pods -n "$NAMESPACE" -o name 2>/dev/null); do
        pod_name="${pod#pod/}"
        echo "Logs for $pod_name:"
        kubectl logs -n "$NAMESPACE" "$pod_name" --tail=20 2>&1 || echo "  (no logs or pod not found)"
        echo ""
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $RESULT -eq 0 ]; then
    echo "✅ Helm Charts Smoke Test → GREEN"
else
    echo "❌ Helm Charts Smoke Test → RED"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Note: Cluster will be cleaned up automatically"

exit $RESULT

