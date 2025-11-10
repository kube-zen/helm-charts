# Zen Watcher Helm Chart

Production-ready Helm chart for Zen Watcher with comprehensive security best practices.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.8+
- (Optional) Cosign for image verification
- (Optional) Prometheus Operator for ServiceMonitor

## Security Features

This Helm chart implements security best practices:

- ✅ **Non-privileged containers** - RunAsNonRoot, no privilege escalation
- ✅ **Read-only root filesystem** - Immutable container filesystem
- ✅ **Dropped capabilities** - All Linux capabilities dropped
- ✅ **Seccomp profile** - RuntimeDefault seccomp profile
- ✅ **NetworkPolicy** - Ingress/Egress network segmentation
- ✅ **Pod Security Standards** - Restricted profile by default
- ✅ **Resource limits** - CPU and memory constraints
- ✅ **RBAC** - Least-privilege access control
- ✅ **Image verification** - Optional Cosign signature verification
- ✅ **SBOM support** - Software Bill of Materials
- ✅ **Security Context** - Comprehensive security settings

## Installation

### Quick Start

```bash
# Add Helm repository (when published)
helm repo add zen-watcher https://charts.kube-zen.com
helm repo update

# Install with default settings
helm install zen-watcher zen-watcher/zen-watcher \
  --namespace zen-system \
  --create-namespace \
  --set global.clusterID=my-cluster
```

### Install from Local Chart

```bash
# Install from local directory
helm install zen-watcher ./helm/zen-watcher \
  --namespace zen-system \
  --create-namespace \
  --set global.clusterID=my-cluster
```

### Production Installation

```bash
helm install zen-watcher zen-watcher/zen-watcher \
  --namespace zen-system \
  --create-namespace \
  --set global.clusterID=production-us-east-1 \
  --set networkPolicy.enabled=true \
  --set podSecurityStandards.enabled=true \
  --set image.verifySignature=true \
  --set image.cosignPublicKey="<your-public-key>" \
  --set serviceMonitor.enabled=true \
  --set resources.limits.memory=512Mi \
  --set resources.limits.cpu=500m
```

## Configuration

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.clusterID` | Unique cluster identifier (required) | `my-cluster` |
| `image.repository` | Image repository | `zubezen/zen-watcher` |
| `image.tag` | Image tag | `1.0.0` |
| `image.verifySignature` | Enable Cosign signature verification | `false` |
| `networkPolicy.enabled` | Enable NetworkPolicy | `true` |
| `podSecurityStandards.enabled` | Enable Pod Security Standards | `true` |
| `podSecurityStandards.enforce` | PSS enforcement level | `restricted` |
| `serviceMonitor.enabled` | Enable Prometheus ServiceMonitor | `false` |
| `config.watchNamespace` | Namespace for CRDs | `zen-system` |
| `config.behaviorMode` | Watcher mode | `all` |

### Full Configuration

See [values.yaml](values.yaml) for all available configuration options.

## Security Configuration

### Image Signature Verification

Enable Cosign signature verification:

```bash
# Generate key pair (if not already done)
cosign generate-key-pair

# Install with signature verification
helm install zen-watcher ./helm/zen-watcher \
  --set image.verifySignature=true \
  --set-file image.cosignPublicKey=cosign.pub
```

### Network Policies

Customize network policies:

```yaml
networkPolicy:
  enabled: true
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: monitoring
      ports:
      - protocol: TCP
        port: 8080
  egress:
    - to:
      - namespaceSelector: {}
        podSelector:
          matchLabels:
            k8s-app: kube-dns
      ports:
      - protocol: UDP
        port: 53
```

### Pod Security Standards

Configure Pod Security Standards:

```yaml
podSecurityStandards:
  enabled: true
  enforce: "restricted"  # restricted, baseline, or privileged
  audit: "restricted"
  warn: "restricted"
```

## Monitoring

### Prometheus Integration

Enable ServiceMonitor for Prometheus Operator:

```bash
helm install zen-watcher ./helm/zen-watcher \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.interval=30s
```

### Grafana Dashboard

Import the included Grafana dashboard:

```bash
kubectl apply -f ../examples/grafana-dashboard.json
```

## Upgrade

```bash
helm upgrade zen-watcher zen-watcher/zen-watcher \
  --namespace zen-system \
  --reuse-values \
  --set image.tag=1.1.0
```

## Uninstall

```bash
# Uninstall (keeps CRDs by default)
helm uninstall zen-watcher --namespace zen-system

# Remove CRDs (if needed)
kubectl delete crd zenevents.zen.kube-zen.com
```

## Verification

### Security Checks

After installation, verify security settings:

```bash
# Check Pod Security Context
kubectl get pod -n zen-system -l app.kubernetes.io/name=zen-watcher \
  -o jsonpath='{.items[0].spec.securityContext}' | jq

# Check Container Security Context
kubectl get pod -n zen-system -l app.kubernetes.io/name=zen-watcher \
  -o jsonpath='{.items[0].spec.containers[0].securityContext}' | jq

# Verify NetworkPolicy
kubectl get networkpolicy -n zen-system

# Check RBAC
kubectl describe clusterrole zen-watcher-zen-watcher
```

### Health Checks

```bash
# Port forward
kubectl port-forward -n zen-system svc/zen-watcher-zen-watcher 8080:8080

# Check health
curl http://localhost:8080/health

# Check status
curl http://localhost:8080/tools/status
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n zen-system

# View logs
kubectl logs -n zen-system -l app.kubernetes.io/name=zen-watcher

# Describe pod
kubectl describe pod -n zen-system -l app.kubernetes.io/name=zen-watcher
```

### RBAC Issues

```bash
# Check ServiceAccount
kubectl get serviceaccount -n zen-system

# Check ClusterRole
kubectl describe clusterrole zen-watcher-zen-watcher

# Check ClusterRoleBinding
kubectl describe clusterrolebinding zen-watcher-zen-watcher
```

### Network Issues

```bash
# Check NetworkPolicy
kubectl get networkpolicy -n zen-system zen-watcher-zen-watcher -o yaml

# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n zen-system -- \
  wget -qO- http://zen-watcher-zen-watcher:8080/health
```

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

## License

Apache 2.0 - See [LICENSE](../../LICENSE) for details.

## Support

- GitHub Issues: https://github.com/your-org/zen-watcher/issues
- Documentation: https://github.com/your-org/zen-watcher/wiki


