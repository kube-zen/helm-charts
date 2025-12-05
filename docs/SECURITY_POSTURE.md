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
  - **Status:** TODO
  - **Roadmap:** RM-HELM-001 (Agent chart TLS hardening)
  - **Impact:** Network isolation incomplete for production
  - **Example:** See `docs/examples/values-aws.yaml` for planned NetworkPolicy config

- **zen-agent RBAC scoping:** Too broad for production
  - **Status:** TODO
  - **Roadmap:** RM-HELM-001
  - **Impact:** Over-permissive ClusterRole (get/list/watch all resources)
  - **Required:** Scope to specific namespaces/resources per tenant

- **PodDisruptionBudget:** Missing (HA consideration)
  - **Status:** TODO
  - **Roadmap:** Not explicitly tracked (infrastructure hardening)
  - **Impact:** No protection against voluntary disruptions
  - **Required:** PDB for multi-replica deployments

### Medium Priority

- **zen-watcher PodSecurity:** Match zen-agent hardening
  - **Status:** Partial (restricted profile planned)
  - **Roadmap:** RM-HELM-002 (Watcher CRD sync automation)
  - **Impact:** Inconsistent security posture between agent/watcher
  - **Required:** Apply same PodSecurity standards as zen-agent

- **Service mesh integration:** Istio/Linkerd compatibility (future)
  - **Status:** Not planned
  - **Roadmap:** Future enhancement
  - **Impact:** No service mesh integration yet

### Low Priority

- **OPA policy validation:** Before applying remediations (future)
  - **Status:** Not planned
  - **Roadmap:** RM-AGENT-020 (Future ideas)
  - **Impact:** No policy validation before SSA apply

- **Image scanning:** Trivy/Snyk in CI (future)
  - **Status:** Not planned
  - **Roadmap:** Not explicitly tracked
  - **Impact:** No automated vulnerability scanning in CI

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

## Security Incident Flow Alignment

**See:** [SECURITY_INCIDENT_FLOW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW.md) for current implementation  
**See:** [SECURITY_INCIDENT_FLOW_PRODUCTION.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW_PRODUCTION.md) for production architecture  
**See:** [THREAT_MODEL_PRODUCTION.md](../../../zen-alpha/docs/09-security/THREAT_MODEL_PRODUCTION.md) for threat scenarios  
**See:** [SECURITY_COMPLIANCE_MAP.md](../../../zen-alpha/docs/09-security/SECURITY_COMPLIANCE_MAP.md) for compliance controls

### Helm Configuration Impact on Incident Flow

**Chart Settings That Affect Security Incident Handling:**

| Chart Setting | Incident Flow Impact | Profiles |
|---------------|---------------------|----------|
| `tlsInsecure: true` | **Detection:** Allows self-signed certs, reduces TLS validation | Sandbox only (dev) |
| `tlsInsecure: false` | **Detection:** Full TLS validation, production-ready | Demo, Pilot, Prod-Like |
| `caMount.enabled: true` | **Detection:** Custom CA trust, private PKI support | All (optional) |
| `rbac.create: true` | **Execution:** Agent can execute remediations, read cluster state | All (required) |
| `serviceAccount.create: true` | **Execution:** Agent identity for K8s API | All (required) |
| `metrics.enabled: true` | **Observability:** Prometheus metrics, watchdog metrics probes | All (recommended) |
| `resources.limits` | **Execution:** Resource constraints, OOM protection | All (tune per profile) |

### Execution Mode Support by Profile

| Profile | SSA Direct | GitOps PR | Validation Strategy | Rollback |
|---------|------------|-----------|---------------------|----------|
| **Sandbox (Local MVP)** | ✅ Supported | ⚠️  Optional | Basic probes (HTTP/K8s) | Automatic |
| **Demo (GitOps/AWS)** | ✅ Supported | ✅ Supported | All probes (HTTP/K8s/metrics) | Automatic + Git revert |
| **Pilot (AWS)** | ✅ Supported | ✅ Supported | All probes + continuous | Automatic + manual |
| **Prod-Like (AWS)** | ✅ Supported | ✅ Supported | All probes + continuous + SLO | Automatic + manual |

**Helm Settings for Each Profile:**
- **Sandbox:** `tlsInsecure: true`, `environment: dev`, minimal resources
- **Demo:** `tlsInsecure: false`, external secrets, medium resources
- **Pilot:** `tlsInsecure: false`, customer CA, production resources, NetworkPolicy (RM-HELM-001)
- **Prod-Like:** Identical to Pilot, all security features enabled, compliance validated

---

## Environment Profile Mapping

**See:** [ENVIRONMENT_PROFILES.md](../../../zen-alpha/docs/ENVIRONMENT_PROFILES.md) for platform-wide profiles

| Profile | Security Posture | Gaps Allowed | Incident Flow Support (Current) | Target Production Flow |
|---------|------------------|--------------|--------------------------------|----------------------|
| **Sandbox (Local MVP)** | Relaxed | tlsInsecure=true, auto-gen secrets, broad RBAC | SSA immediate, basic validation | N/A (dev only) |
| **Demo (GitOps/AWS)** | Moderate | NetworkPolicy optional, RBAC scoping TODO | SSA immediate + GitOps PR immediate, HTTP/K8s probes | N/A (demo only) |
| **Pilot (AWS)** | Production-Lite | NetworkPolicy required (RM-HELM-001), RBAC scoping TODO | All modes (except scheduled GitOps), metrics probes, rollback | Scheduled SSA ✅, Scheduled GitOps 🔮 |
| **Prod-Like (AWS)** | Production | No gaps allowed, all RM-HELM-001 items must be resolved | All modes (except scheduled GitOps), continuous validation, compliance | All target modes ✅, HA ✅, multi-region 🔮 |

**Note:** Scheduled GitOps PR (delayed PR creation) is target behavior, not current. Current GitOps creates PRs immediately.

**Validation:**
- **Sandbox:** No security validation required, basic smoke tests
- **Demo:** Basic security checks (TLS enabled, external secrets)
- **Pilot:** All security checks (NetworkPolicy, RBAC scoping, PDB)
- **Prod-Like:** Full security audit (SOC2 controls, compliance)

**Security Incident Flow Support:**
- **Sandbox:** Immediate SSA, basic watchdog, automatic rollback
- **Demo:** Immediate/Scheduled SSA, GitOps PR, Slack approval, full watchdog
- **Pilot:** All approval modes, all execution modes, continuous validation, audit trail
- **Prod-Like:** Production-identical flow, all features tested, compliance validated

---

## For Reviewers

**If you are reviewing security incident flows**, read these documents in order:

1. **[SECURITY_INCIDENT_FLOW_PRODUCTION.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW_PRODUCTION.md)** (20 min)
   - Production architecture for incident handling
   - How agent, watcher, SaaS, and GitOps interact
   - Resilience scenarios (SaaS down, agent offline)

2. **[THREAT_MODEL_PRODUCTION.md](../../../zen-alpha/docs/09-security/THREAT_MODEL_PRODUCTION.md)** (15 min)
   - Threat model with 10 key threats
   - Attack scenarios and mitigations
   - How Helm configuration affects security posture

3. **This Document (SECURITY_POSTURE.md)** (10 min)
   - Helm-level security controls
   - Current guarantees vs known gaps
   - Environment profile mapping

4. **[PROFILES_AND_VALUES.md](PROFILES_AND_VALUES.md)** (10 min)
   - How to choose Helm values for different environments
   - Security implications of each profile

**Key Questions to Ask:**
- Are agent RBAC permissions appropriate for production? (Currently broad ClusterRole)
- Is NetworkPolicy absence a blocker for your environment? (Planned, not implemented)
- Is mTLS optional acceptable, or should it be mandatory? (Currently optional, production-ready)
- Are Pod Security Standards (restricted profile) sufficient? (Currently enforced)

**Where Helm Configuration Affects Incident Flow:**
- `tlsInsecure`: Controls TLS validation (detection phase, HMAC/mTLS authentication)
- `rbac.create`: Controls agent permissions (execution phase, SSA operations)
- `metrics.enabled`: Controls metrics emission (validation phase, watchdog metrics probes)
- `caMount.enabled`: Controls CA trust chain (detection phase, mTLS certificate validation)
- `serviceAccount.create`: Controls agent identity (execution phase, K8s API authentication)

---

## See Also

- [PROFILES_AND_VALUES.md](PROFILES_AND_VALUES.md) - Profile selection guide
- [ENVIRONMENT_PROFILES.md](../../../zen-alpha/docs/ENVIRONMENT_PROFILES.md) - Platform profiles
- [TLS_HARDENING.md](../charts/zen-agent/TLS_HARDENING.md) - Agent TLS details
- [Agent Cert Lifecycle](../../../zen-alpha/docs/09-security/AGENT_CERT_LIFECYCLE.md) - Certificate management
- [HMAC Enforcement](../../../zen-alpha/docs/09-security/HMAC_ENFORCEMENT_CONFIG.md) - HMAC configuration
- [ROADMAP_HELM.md](ROADMAP_HELM.md) - Helm roadmap

