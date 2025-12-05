# Helm Chart Example Values

**Purpose:** Example Helm values files for common deployment scenarios

## Files

- **values-local.yaml** - Local k3d development
  - TLS disabled (tlsInsecure: true)
  - Minimal resources (256Mi RAM)
  - Local SaaS endpoint (http://localhost:8080)

- **values-gitops.yaml** - GitOps-driven deployment (FluxCD/ArgoCD)
  - TLS enabled (mTLS)
  - Production SaaS endpoint
  - Version-pinned images
  - Secret management via external-secrets

- **values-aws.yaml** - AWS EKS deployment
  - Public TLS certificates
  - IRSA support (AWS Secrets Manager)
  - Network policies (planned)
  - Production-ready resources

## Usage

### Local Development

```bash
helm install zen-agent charts/zen-agent/ \
  -f docs/examples/values-local.yaml \
  --set saas.clusterToken=YOUR_BOOTSTRAP_TOKEN \
  --set tenant.id=LOCAL_TENANT \
  --set cluster.id=local-k3d-cluster
```

### GitOps (FluxCD)

```yaml
# flux-system/zen-agent.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: zen-agent
spec:
  chart:
    spec:
      chart: zen-agent
      sourceRef:
        kind: HelmRepository
        name: zen-charts
  values:
    # Reference values-gitops.yaml
    saas:
      endpoint: "https://agent.kube-zen.io"
    # Secrets managed via external-secrets
```

### AWS EKS

```bash
helm install zen-agent charts/zen-agent/ \
  -f docs/examples/values-aws.yaml \
  --set saas.clusterToken=$(aws secretsmanager get-secret-value --secret-id zen-agent-token --query SecretString --output text) \
  --set tenant.id=PROD_TENANT \
  --set cluster.id=eks-cluster-001
```

## Security Notes

- **Local:** `tlsInsecure: true` is DEV ONLY (requires `environment: dev`)
- **GitOps/AWS:** TLS required (`tlsInsecure: false`)
- **Secrets:** Never commit bootstrap tokens; use external-secrets or sealed-secrets
- **Network Policies:** Planned in RM-HELM-001 (see `SECURITY_POSTURE.md`)

## See Also

- [ROADMAP_HELM.md](../ROADMAP_HELM.md) - Helm roadmap and profiles
- [SECURITY_POSTURE.md](../SECURITY_POSTURE.md) - Security baseline and gaps
- [TLS_HARDENING.md](../../charts/zen-agent/TLS_HARDENING.md) - TLS configuration details

