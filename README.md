# Kube-Zen Helm Charts

Official Helm charts for Zero-Effort Kubernetes security and remediation platform.

## Quick Start

```bash
# Add repository
helm repo add kube-zen https://kube-zen.github.io/helm-charts
helm repo update

# Install zen-agent (includes zen-watcher automatically)
helm install zen-agent kube-zen/zen-agent \
  --set saas.clusterToken="YOUR_TOKEN_HERE" \
  --namespace zen-system --create-namespace
```

## Available Charts

### zen-agent (Recommended)
**Installs both zen-agent + zen-watcher in one command**

- Automated security remediation
- Policy enforcement
- Scheduled maintenance windows
- Includes zen-watcher for event detection

### zen-watcher (Standalone)
Event detection and monitoring only (no remediation)

## Installation

### 1. Get Cluster Token
Visit https://app.kube-zen.io/clusters and generate a token for your cluster.

### 2. Install
```bash
helm install zen-agent kube-zen/zen-agent \
  --set saas.clusterToken="<token>" \
  --set saas.endpoint="https://api.kube-zen.io" \
  --namespace zen-system --create-namespace
```

### 3. Verify
```bash
kubectl get pods -n zen-system
# Should see: zen-agent and zen-watcher running
```

## Configuration

See `values.yaml` in each chart for all options.

## License

- zen-agent: Proprietary
- zen-watcher: Apache 2.0

## Support

https://kube-zen.io/support

