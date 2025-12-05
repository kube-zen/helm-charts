# Helm Charts Security Posture

**Last Updated:** 2025-12-05  
**Purpose:** Document security baseline for zen-agent and zen-watcher charts

**See Also:** [ROADMAP_HELM.md](ROADMAP_HELM.md) for security roadmap items

---

## Current Guarantees vs Known Gaps

### What IS Enforced Now

- ✅ Pod runs as non-root (UID 1000)
- ✅ Read-only root filesystem
- ✅ All capabilities dropped
- ✅ No privilege escalation
- ✅ HMAC authentication to SaaS
- ✅ mTLS optional (production-ready)
- ✅ zen-watcher NetworkPolicy enforced (if enabled)

### Known Gaps

- ⚠️  zen-agent NetworkPolicy missing (RM-HELM-001)
- ⚠️  zen-agent RBAC too broad for production
- ⚠️  No PodDisruptionBudget (HA consideration)
- ⚠️  zen-watcher PodSecurity needs hardening

### Assumptions (Relies on Cluster Policies)

- Cluster-level network policies (if NetworkPolicy CRD not installed)
- PSP or Pod Security Admission (if chart PSS not enforced)
- Image pull policies (cluster registry authentication)

---

## zen-agent Security Baseline

### Pod Security

**Pod Security Standards:** Restricted profile

**podSecurityContext:**
```yaml
runAsNonRoot: true
runAsUser: 1000
fsGroup: 1000
```

**securityContext:**
```yaml
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
readOnlyRootFilesystem: true
```

**Status:** ✅ Implemented and enforced

### Network Policies

**Status:** ⚠️  TODO (RM-HELM-001)

**Requirements:**
- Egress to SaaS API (HTTPS)
- Egress to K8s API server
- No ingress (agent initiates all connections)
- DNS egress for name resolution

**Planned:** NetworkPolicy template in chart

### RBAC

**ServiceAccount:** `zen-agent` (auto-created)

**ClusterRole Permissions:**
- `get`, `list`, `watch`: All resources (observation)
- `create`, `update`, `patch`, `delete`: ZenAgentRemediation CRDs
- `patch`: NetworkPolicy, RoleBinding (SSA remediations)

**Status:** ✅ Implemented with least-privilege principle

**Gap:** Broader than ideal for production; should scope to specific namespaces/resources

### Secrets Management

**Current:**
- Bootstrap token: Kubernetes Secret
- HMAC key: Derived via HKDF (not stored)
- TLS certs: ConfigMap or Secret mount

**Status:** ✅ No hardcoded secrets

**Outstanding (RM-AGENT-004):**
- External secret providers (Vault, AWS Secrets Manager, Azure Key Vault)
- Sealed Secrets integration

### mTLS Configuration

**Status:** ✅ Production-ready (optional)

**Configuration:**
```yaml
tls:
  enabled: true  # Enable mTLS
```

**Features:**
- Agent ↔ SaaS mTLS
- Certificate lifecycle managed by agent
- Custom CA support via `caMount.enabled`
- Dev mode: `tlsInsecure: true` (dev only)

**Outstanding (RM-SEC-001):**
- Automated cert rotation via CertManager
- OCSP stapling

---

## zen-watcher Security Baseline

### Pod Security

**Pod Security Standards:** Restricted profile (planned)

**securityContext:** Similar to zen-agent

**Status:** ⚠️  Needs hardening to match zen-agent

### Network Policies

**Status:** ✅ Implemented

**Template:** `templates/networkpolicy.yaml`

**Policy:**
- Egress: K8s API server
- Egress: DNS
- No ingress

**Configurable:** `networkPolicy.enabled: true/false`

### RBAC

**ServiceAccount:** `zen-watcher`

**ClusterRole Permissions:**
- `get`, `list`, `watch`: All cluster resources
- Read-only operation

**Status:** ✅ Least-privilege for observation

### Service Type

**Default:** ClusterIP (internal only)

**Exposure:** Metrics endpoint only (Prometheus scrape)

**Status:** ✅ No external exposure

---

## Security Gaps & Roadmap

### High Priority (RM-HELM-001)

- **zen-agent NetworkPolicy:** Not yet defined
- **zen-agent RBAC scoping:** Too broad for production
- **PodDisruptionBudget:** Missing (HA consideration)

### Medium Priority

- **zen-watcher PodSecurity:** Match zen-agent hardening
- **Service mesh integration:** Istio/Linkerd compatibility (future)

### Low Priority

- **OPA policy validation:** Before applying remediations (future)
- **Image scanning:** Trivy/Snyk in CI (future)

---

## Compliance Alignment

### SOC2 Requirements

**Implemented:**
- Non-root containers ✅
- Read-only root filesystem ✅
- Dropped capabilities ✅
- Network isolation (partial) ⚠️
- RBAC least-privilege (partial) ⚠️

**Outstanding:**
- Comprehensive network policies
- Tighter RBAC scoping
- Audit logging (agent-side)

### GDPR Considerations

**Data Handling:**
- Agent doesn't store customer data persistently
- Observability data sent to SaaS (encrypted)
- No PII in logs

**Status:** ✅ Compliant by design

---

## See Also

- [TLS_HARDENING.md](../charts/zen-agent/TLS_HARDENING.md) - Agent TLS details
- [Agent Cert Lifecycle](../../../zen-alpha/docs/09-security/AGENT_CERT_LIFECYCLE.md) - Certificate management
- [HMAC Enforcement](../../../zen-alpha/docs/09-security/HMAC_ENFORCEMENT_CONFIG.md) - HMAC configuration
- [ROADMAP_HELM.md](ROADMAP_HELM.md) - Helm roadmap

