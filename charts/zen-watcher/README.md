# Zen Watcher Helm Chart

**Standalone security event aggregator** - Watches Trivy, Kyverno, Falco, Audit logs, and Kube-bench reports. Creates ZenAgentEvent CRDs locally. No external communication required.

**Version:** v1.0.13 (Go 1.22)

## Prerequisites

- Kubernetes 1.28+
- Helm 3.8+
- Security tools (auto-detected): Trivy, Kyverno, Falco, Kube-bench
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

### Quick Start (Standalone)

```bash
# zen-watcher is typically installed as part of zen-agent
# But you can install it standalone for event detection only

# Add Helm repository
helm repo add kubezen https://kube-zen.io/helm-charts
helm repo update

# Install standalone (no cluster token needed)
helm install zen-watcher kubezen/zen-watcher \
  --namespace zen-cluster \
  --create-namespace
```

**Note:** zen-watcher is standalone - it only creates ZenAgentEvent CRDs locally. It does NOT communicate with external services. For full remediation capabilities, use `zen-agent` (which includes zen-watcher automatically).

### Production Installation

```bash
helm install zen-watcher kubezen/zen-watcher \
  --namespace zen-cluster \
  --create-namespace \
  --set networkPolicy.enabled=true \
  --set autoDetect.enabled=true \
  --set resources.limits.memory=256Mi \
  --set resources.limits.cpu=200m
```

## Configuration

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `kubezen/zen-watcher` |
| `image.tag` | Image tag (Go 1.22) | `1.0.13` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `autoDetect.enabled` | **Auto-detect security tools** - Continuously checks for Kyverno, Trivy, Falco pods in their namespaces | `true` |
| `namespaces.kyverno` | Kyverno namespace to scan | `kyverno` |
| `namespaces.trivy` | Trivy namespace to scan | `trivy-system` |
| `namespaces.falco` | Falco namespace to scan | `falco` |
| `namespaces.kubeBench` | Kube-bench namespace to scan | `kube-bench` |
| `networkPolicy.enabled` | Enable NetworkPolicy (required for cross-namespace pod detection) | `true` |
| `resources.limits.memory` | Memory limit | `256Mi` |
| `resources.limits.cpu` | CPU limit | `200m` |
| `serviceMonitor.enabled` | Enable Prometheus ServiceMonitor | `false` |

### Features

- ✅ **Auto-detection** - Automatically detects installed security tools
- ✅ **Deduplication** - Only creates NEW ZenAgentEvents (no duplicates)
- ✅ **Category taxonomy** - security, compliance, performance
- ✅ **Label-based filtering** - `source=trivy,category=security`, `source=kyverno,category=compliance`
- ✅ **NetworkPolicy** - Allows K8s API access for cross-namespace detection
- ✅ **RBAC** - ClusterRole with read access to security reports

### Supported Security Tools

| Tool | Status | Category | Event Type |
|------|--------|----------|------------|
| **Trivy** | ✅ Fully implemented | security | VulnerabilityReports → vulnerabilities |
| **Kyverno** | ✅ Fully implemented | compliance | PolicyReports → policy-violations |
| **Falco** | ℹ️ Detection only | security | Requires falco-sidekick for events |
| **Kube-bench** | ℹ️ Detection only | compliance | Requires custom result parser |
| **Audit logs** | ℹ️ Placeholder | compliance | Requires K8s audit webhook |

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


