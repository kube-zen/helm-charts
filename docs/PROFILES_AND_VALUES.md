# Helm Chart Profiles and Values

**Last Updated:** 2025-12-05  
**Purpose:** Guide to choosing the right Helm values for your deployment environment

**Helm Impact on Security Incident Flow:**

**Key Settings:**
- `tlsInsecure` - Affects HMAC/mTLS authentication (detection phase)
- `rbac.create` - Affects SSA execution permissions (execution phase)
- `metrics.enabled` - Affects watchdog metrics probes (validation phase)
- `caMount.enabled` - Affects TLS trust chain (detection phase)
- `resources` - Affects execution capacity and OOM protection

**See:** [SECURITY_POSTURE.md](SECURITY_POSTURE.md#security-incident-flow-alignment) for detailed mapping

---

**See Also:**
- [ENVIRONMENT_PROFILES.md](../../../zen-alpha/docs/ENVIRONMENT_PROFILES.md) - Platform-wide environment profiles ⭐ **Start Here**
- [SECURITY_INCIDENT_FLOW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW.md) - Current implementation
- [SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md) - Target production architecture
- [THREAT_MODEL_PRODUCTION.md](../../../zen-alpha/docs/09-security/THREAT_MODEL_PRODUCTION.md) - Threat model and attack scenarios
- [SECURITY_COMPLIANCE_MAP.md](../../../zen-alpha/docs/09-security/SECURITY_COMPLIANCE_MAP.md) - Compliance controls
- [OPS_PORTAL.md](../../../zen-alpha/docs/OPS_PORTAL.md) - Operations hub by profile
- [ROADMAP_HELM.md](ROADMAP_HELM.md) - Helm roadmap and features
- [SECURITY_POSTURE.md](SECURITY_POSTURE.md) - Security baseline and gaps

---

## Quick Start: Which Profile Do I Need?

| Your Situation | Profile | Example Values File | Security Incident Flow |
|----------------|---------|---------------------|------------------------|
| Local development (k3d) | **Local MVP** | [examples/values-local.yaml](examples/values-local.yaml) | SSA only, basic validation |
| GitOps deployment (FluxCD/ArgoCD) | **GitOps-Driven** | [examples/values-gitops.yaml](examples/values-gitops.yaml) | SSA + GitOps PR, full validation |
| AWS EKS deployment | **AWS/Open Demo** | [examples/values-aws.yaml](examples/values-aws.yaml) | All modes, production validation |
| Customer pilot deployment | **Production-Like** | Customize values-aws.yaml with production settings | All modes, compliance required |

**See:** [SECURITY_INCIDENT_FLOW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW.md) for how each profile affects incident handling.

---

## Profile Comparison

### Local MVP (k3d)

**When to Use:**
- Fast development iteration
- Local testing before PR
- Debugging agent behavior
- Learning the platform

**Characteristics:**
- **TLS:** Self-signed or mkcert (tlsInsecure=true allowed)
- **Resources:** Minimal (256Mi RAM, 100m CPU)
- **Replicas:** 1 (no HA)
- **SaaS Endpoint:** http://localhost:8080 or k3d ingress
- **Secrets:** Bootstrap token via --set

**Example Values:** `docs/examples/values-local.yaml`

**Usage:**
```bash
helm install zen-agent charts/zen-agent/ \
  -f docs/examples/values-local.yaml \
  --set saas.clusterToken=YOUR_TOKEN \
  --set tenant.id=LOCAL_TENANT \
  --set cluster.id=local-k3d
```

**Pros:**
- Fast iteration (seconds to deploy)
- No cloud costs
- Easy to reset/recreate

**Cons:**
- Not production-like
- No HA testing
- Limited observability

---

### GitOps-Driven (FluxCD/ArgoCD)

**When to Use:**
- GitOps workflow (PR-based changes)
- Demo environments
- Staging/pre-production
- Customer pilots with GitOps

**Characteristics:**
- **TLS:** mTLS enabled (production certificates)
- **Resources:** Medium (512Mi RAM, 200m CPU)
- **Replicas:** 2+ (HA)
- **SaaS Endpoint:** https://agent.kube-zen.io (HTTPS only)
- **Secrets:** External secrets (sealed-secrets, external-secrets-operator)

**Example Values:** `docs/examples/values-gitops.yaml`

**Usage (FluxCD):**
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
  valuesFrom:
  - kind: ConfigMap
    name: zen-agent-values
  values:
    saas:
      endpoint: "https://agent.kube-zen.io"
    tenant:
      id: "TENANT_ID"  # From ConfigMap
    cluster:
      id: "CLUSTER_ID"  # From ConfigMap
```

**Pros:**
- Git as source of truth
- Audit trail via Git history
- Automated sync
- Production-like

**Cons:**
- Slower iteration (Git commit required)
- More complex setup
- Requires GitOps tooling

---

### AWS/Open Demo (EKS)

**When to Use:**
- Public demos on AWS
- Partner showcases
- Staging on EKS
- Production deployments

**Characteristics:**
- **TLS:** Production certificates (Let's Encrypt or AWS ACM)
- **Resources:** Production-ready (512Mi-1Gi RAM, auto-scaling)
- **Replicas:** 3+ (HA with HPA)
- **SaaS Endpoint:** https://agent.kube-zen.io (public FQDN)
- **Secrets:** AWS Secrets Manager (IRSA)

**Example Values:** `docs/examples/values-aws.yaml`

**Usage:**
```bash
# With AWS Secrets Manager
helm install zen-agent charts/zen-agent/ \
  -f docs/examples/values-aws.yaml \
  --set saas.clusterToken=$(aws secretsmanager get-secret-value \
    --secret-id zen-agent-token --query SecretString --output text) \
  --set tenant.id=PROD_TENANT \
  --set cluster.id=eks-cluster-001
```

**Pros:**
- Production-ready
- AWS-native integrations (IRSA, Secrets Manager)
- Scalable (HPA)
- Public-facing

**Cons:**
- AWS costs
- More complex networking
- Requires AWS expertise

---

## Key Configuration Differences

### TLS Configuration

| Profile | tlsInsecure | environment | TLS Certificates |
|---------|-------------|-------------|------------------|
| **Local MVP** | true | dev | Self-signed/mkcert |
| **GitOps** | false | prod/staging | Let's Encrypt or custom CA |
| **AWS** | false | prod | Let's Encrypt or AWS ACM |

**Important:** `tlsInsecure=true` is **DEV ONLY** and requires `environment=dev`. Production profiles must use `tlsInsecure=false`.

### Resource Allocation

| Profile | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| **Local MVP** | 100m | 256m | 128Mi | 256Mi |
| **GitOps** | 100m | 500m | 128Mi | 512Mi |
| **AWS** | 100m | 500m | 128Mi | 512Mi |

**Note:** Adjust based on cluster size and remediation frequency.

### Secrets Management

| Profile | Bootstrap Token | Tenant/Cluster ID | CA Certificates |
|---------|----------------|-------------------|-----------------|
| **Local MVP** | --set flag | --set flag | Optional (caMount) |
| **GitOps** | External Secret | ConfigMap or Secret | ConfigMap (caMount) |
| **AWS** | AWS Secrets Manager (IRSA) | ConfigMap or Secret | ConfigMap (caMount) |

---

## How to Choose Your Profile

### Decision Tree

```
Start Here
│
├─ Are you developing locally?
│  └─ YES → Use Local MVP (values-local.yaml)
│
├─ Do you use GitOps (FluxCD/ArgoCD)?
│  └─ YES → Use GitOps-Driven (values-gitops.yaml)
│
├─ Are you deploying to AWS EKS?
│  └─ YES → Use AWS/Open Demo (values-aws.yaml)
│
└─ Other cloud or on-prem?
   └─ Start with values-gitops.yaml and customize
```

### Environment Mapping

| Platform Environment | Helm Profile | Example Values | Constraints |
|---------------------|--------------|----------------|-------------|
| **sandbox** (k3d-zen-saas) | Local MVP | values-local.yaml | tlsInsecure allowed, minimal resources |
| **demo** (k3d-ec2 or EKS) | GitOps-Driven or AWS | values-gitops.yaml or values-aws.yaml | TLS required, external secrets |
| **pilot** (customer cluster) | AWS or GitOps-Driven | values-aws.yaml (customize) | TLS required, production RBAC |
| **prod-like** (staging) | AWS | values-aws.yaml (production settings) | Identical to production |

**See:** [ENVIRONMENT_PROFILES.md](../../../zen-alpha/docs/ENVIRONMENT_PROFILES.md) for platform-wide environment definitions.

**Profile Constraints (from ENVIRONMENT_PROFILES.md):**
- **Sandbox:** Local MVP only (no AWS-specific features)
- **Demo:** GitOps-Driven or AWS (all golden paths must be GREEN)
- **Pilot:** AWS or GitOps-Driven (production-like, limited blast radius)
- **Prod-Like:** AWS only (production-identical, all paths GREEN)

---

## Customization Guide

### Starting from an Example

1. **Copy the example values:**
   ```bash
   cp docs/examples/values-local.yaml my-values.yaml
   ```

2. **Edit required fields:**
   ```yaml
   saas:
     endpoint: "https://your-saas.example.com"
     clusterToken: "YOUR_TOKEN"  # Or use external secret
   
   tenant:
     id: "YOUR_TENANT_ID"
   
   cluster:
     id: "YOUR_CLUSTER_ID"
   ```

3. **Adjust optional settings:**
   - Resources (CPU/memory)
   - Replicas (for HA)
   - TLS configuration
   - Network policies (if needed)

4. **Deploy:**
   ```bash
   helm install zen-agent charts/zen-agent/ -f my-values.yaml
   ```

### Common Customizations

**Increase Resources:**
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 200m
    memory: 256Mi
```

**Enable HA (Multiple Replicas):**
```yaml
replicaCount: 3  # Note: Not yet in chart, planned for RM-HELM-001
```

**Custom CA Certificate:**
```yaml
caMount:
  enabled: true
  configMapName: my-custom-ca
  mountPath: /usr/local/share/ca-certificates
```

**Network Policy (Planned):**
```yaml
networkPolicy:
  enabled: true  # Note: Not yet in chart, planned for RM-HELM-001
  egress:
    - to:
      - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
```

---

## Validation

### Pre-Deployment Checks

**1. Lint the chart:**
```bash
helm lint charts/zen-agent/ -f my-values.yaml
```

**2. Render templates (dry-run):**
```bash
helm template zen-agent charts/zen-agent/ -f my-values.yaml > rendered.yaml
kubectl apply --dry-run=client -f rendered.yaml
```

**3. Check for guardrails violations:**
```bash
# From helm-charts repo
RUN_GUARDRAILS=1 RUN_HELM_LINT=1 ./scripts/ci/helm-lint-and-render.sh
```

### Post-Deployment Validation

**1. Check pod status:**
```bash
kubectl get pods -l app=zen-agent
```

**2. Check logs:**
```bash
kubectl logs -l app=zen-agent --tail=50
```

**3. Verify SaaS connectivity:**
```bash
kubectl logs -l app=zen-agent | grep "Bootstrap successful"
```

---

## Troubleshooting

### Common Issues

**Issue: ImagePullBackOff**
- **Cause:** Image not available in registry
- **Fix:** Verify `image.repository` and `image.tag` in values
- **Local:** Import image via `k3d image import`

**Issue: CrashLoopBackOff**
- **Cause:** Missing required config (clusterToken, tenant.id, cluster.id)
- **Fix:** Check logs: `kubectl logs -l app=zen-agent`
- **Verify:** All required values are set

**Issue: TLS Handshake Failed**
- **Cause:** TLS configuration mismatch
- **Fix (dev):** Set `tlsInsecure: true` and `environment: dev`
- **Fix (prod):** Mount custom CA via `caMount.enabled: true`

**Issue: HMAC Authentication Failed**
- **Cause:** Invalid bootstrap token or key derivation mismatch
- **Fix:** Verify `saas.clusterToken` matches SaaS-generated token
- **Check:** Token format (zen-<uuid> or hex)

---

## See Also

- [ENVIRONMENT_PROFILES.md](../../../zen-alpha/docs/ENVIRONMENT_PROFILES.md) - Platform environment profiles
- [ROADMAP_HELM.md](ROADMAP_HELM.md) - Helm roadmap and planned features
- [SECURITY_POSTURE.md](SECURITY_POSTURE.md) - Security baseline and gaps
- [TLS_HARDENING.md](../charts/zen-agent/TLS_HARDENING.md) - TLS configuration details
- [Example Values](examples/) - Ready-to-use values files

