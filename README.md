# Kube-Zen Helm Charts

Official Helm charts for Zero-Effort Kubernetes security and remediation platform.

**Source Repositories:**
- **zen-watcher**: [github.com/kube-zen/zen-watcher](https://github.com/kube-zen/zen-watcher)
- **zen-agent**: [github.com/kube-zen/zen-agent](https://github.com/kube-zen/zen-agent) (if applicable)

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
**Complete security + remediation solution**

- Installs zen-agent + zen-watcher (as dependency)
- Automated security remediation
- Syncs events with SaaS platform
- Policy enforcement
- Scheduled maintenance windows
- Requires: cluster token, tenant ID, cluster ID

### zen-watcher (Standalone)
**Event detection only (no SaaS communication)**

- Standalone security event aggregator
- Auto-detects: Trivy, Kyverno, Falco, Audit logs, Kube-bench
- Creates Observation CRDs locally
- No external communication
- No token/tenant/cluster ID needed
- Use case: Local event collection, testing, air-gapped environments

## Installation

### 1. Get Cluster Token
Visit https://app.kube-zen.io/clusters and generate a token for your cluster.

### 2. Install zen-agent (includes zen-watcher)
```bash
helm install zen-agent kube-zen/zen-agent \
  --set saas.clusterToken="<bootstrap-token>" \
  --set saas.endpoint="https://api.kube-zen.io" \
  --set tenant.id="<tenant-uuid>" \
  --set cluster.id="<cluster-uuid>" \
  --namespace zen-cluster --create-namespace
```

**Or install zen-watcher standalone (no SaaS):**
```bash
helm install zen-watcher kube-zen/zen-watcher \
  --namespace zen-cluster --create-namespace
```

### 3. Verify
```bash
kubectl get pods -n zen-cluster
# zen-agent installation: shows zen-agent + zen-agent-zen-watcher
# zen-watcher standalone: shows zen-watcher only

# Check events being created
kubectl get observations -A
# Should show: SOURCE | CATEGORY | SEVERITY columns
```

## Version Compatibility

### zen-watcher Chart

| Chart Version | App Version (Image Tag) | Kubernetes | Go Version | Notes |
|---------------|-------------------------|------------|------------|-------|
| 1.0.0         | 1.0.0                   | 1.26-1.29  | 1.23+      | Initial release |

See individual chart READMEs for detailed version information.

## Configuration

See `values.yaml` in each chart for all options.

## Repository Structure

This repository contains Helm charts for Kube-Zen projects:

- **zen-watcher**: Event aggregation operator (Apache 2.0)
- **zen-agent**: Remediation agent (Proprietary)

**Source Code Repositories:**
- zen-watcher: [github.com/kube-zen/zen-watcher](https://github.com/kube-zen/zen-watcher)
- zen-agent: [github.com/kube-zen/zen-agent](https://github.com/kube-zen/zen-agent) (if applicable)

## License

- zen-agent: Proprietary
- zen-watcher: Apache 2.0

## Support

- **zen-watcher**: [github.com/kube-zen/zen-watcher/issues](https://github.com/kube-zen/zen-watcher/issues)
- **General**: https://kube-zen.io/support

