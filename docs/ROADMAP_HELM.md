# Helm Charts Roadmap

**Repository:** ~/letsgo/helm-charts  
**Parent Roadmap:** [zen-alpha/docs/ROADMAP.md](../../../zen-alpha/docs/ROADMAP.md)  
**Charts:** zen-agent, zen-watcher  
**Architecture Context:** [COMPREHENSIVE_ARCHITECTURE.md](../../../zen-alpha/docs/01-architecture/COMPREHENSIVE_ARCHITECTURE.md) (see "Helm Charts & Deployment" section for system integration)  
**Security Incident Flow:** [SECURITY_INCIDENT_FLOW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW.md) - How charts support incident handling (current)  
**Production Target:** [SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md) - Target production architecture  
**Threat Model:** [THREAT_MODEL_PRODUCTION.md](../../../zen-alpha/docs/09-security/THREAT_MODEL_PRODUCTION.md) - Threat scenarios and mitigations

This document extracts helm/infrastructure roadmap items from the platform roadmap.

---

## Example Values Files

**Location:** `docs/examples/`

- **values-local.yaml** - Local k3d development (TLS disabled, minimal resources)
- **values-gitops.yaml** - GitOps-driven deployment (FluxCD/ArgoCD, mTLS enabled)
- **values-aws.yaml** - AWS EKS deployment (public certs, IRSA support)

**Usage:**
```bash
# Local dev
helm install zen-agent charts/zen-agent/ -f docs/examples/values-local.yaml \
  --set saas.clusterToken=YOUR_TOKEN \
  --set tenant.id=TENANT_ID \
  --set cluster.id=CLUSTER_ID

# GitOps (via FluxCD/ArgoCD)
# Reference values-gitops.yaml in your GitOps repo

# AWS EKS
helm install zen-agent charts/zen-agent/ -f docs/examples/values-aws.yaml \
  --set saas.clusterToken=YOUR_TOKEN \
  --set tenant.id=TENANT_ID \
  --set cluster.id=CLUSTER_ID
```

---

## Environment Profiles

### Local MVP (k3d)

**Purpose:** Fast development iteration in local k3d cluster

**Chart Values:**
- TLS disabled or self-signed mkcert
- Image: local registry or import
- SaaS endpoint: `http://localhost:port` or k3d ingress
- Resources: minimal (limits: 256Mi RAM, 200m CPU)

**Security Posture (from SECURITY_POSTURE.md):**
- PodSecurity: ✅ Restricted profile
- NetworkPolicy: ⚠️  Not enforced (low risk in k3d)
- RBAC: ⚠️  Broad permissions (acceptable for dev)
- mTLS: ❌ Disabled (dev only)

**Scripts:**
- `zen-alpha/scripts/demo/run-local-real-pipeline.sh`
- `helm-charts/scripts/demo/helm-smoke-k3d.sh`

**Example Values:** `docs/examples/values-local.yaml`

**Profile Guide:** See [PROFILES_AND_VALUES.md](PROFILES_AND_VALUES.md) for choosing the right profile

**Validation:** Run `RUN_HELM_PROFILES_SANITY=1 scripts/ci/helm-profiles-sanity-optional.sh` to validate all example values

### GitOps-Driven Demo

**Purpose:** Demonstrate GitOps workflows with real Git repos

**Chart Values:**
- TLS enabled (mTLS)
- SaaS endpoint: demo cluster external FQDN
- GitOps mode enabled
- Resources: production-like

**Security Posture:**
- PodSecurity: ✅ Restricted profile
- NetworkPolicy: ⚠️  Should be enforced (RM-HELM-001)
- RBAC: ⚠️  Should be scoped (production requirement)
- mTLS: ✅ Enabled

**Flow:**
1. zen-gitops creates PR in customer repo
2. Customer reviews and merges
3. FluxCD/ArgoCD syncs to cluster
4. zen-agent validates via webhook

**Status:** Design complete (not yet wired to /clusters/new)

**Example Values:** `docs/examples/values-gitops.yaml`

### AWS/Open Demo

**Purpose:** Public demo on AWS EKS for partners/customers

**Chart Values:**
- TLS enabled (public certificates, not mkcert)
- SaaS endpoint: public FQDN (e.g., `https://agent.kube-zen.io`)
- IRSA for AWS integration
- Resources: production-ready

**Security Posture:**
- PodSecurity: ✅ Restricted profile (required for EKS)
- NetworkPolicy: ✅ Must be enforced (public cloud requirement)
- RBAC: ✅ Must be scoped (production best practice)
- mTLS: ✅ Enabled with public certs

**Requirements:**
- EKS-compatible
- Network egress policies for public SaaS
- Public certificate trust chain

**Status:** Planned (orchestration by MAIN AI)

**Example Values:** `docs/examples/values-aws.yaml`

---

## Chart Testing & Validation

### RM-HELM-003: Chart testing CI integration
**Status:** ✅ Done  
**Priority:** Medium  
**Implementation:**
- `scripts/ci/helm-lint-and-render.sh` - Lint and template rendering with value matrix
- `scripts/demo/helm-smoke-k3d.sh` - k3d cluster smoke test
- `scripts/README.md` - Usage documentation

**Related zen-main Integration:**
- `zen-alpha/scripts/ci/helm-charts-optional.sh` - Optional helm validation from zen-main CI

---

## Security & TLS

### RM-HELM-001: Agent chart TLS hardening
**Status:** 🔄 In Progress  
**Priority:** High  
**Implementation:**
- `charts/zen-agent/TLS_HARDENING.md` - TLS hardening documentation
- `charts/zen-agent/values.yaml` - TLS configuration options

**Current TLS Features:**
- mTLS support (agent ↔ SaaS)
- Custom CA certificate mounting
- TLS insecure mode (dev only)
- Certificate lifecycle management

**Outstanding:**
- Automated cert rotation via CertManager
- OCSP stapling support
- Cert expiry monitoring alerts

---

## CRD & Observability

### RM-HELM-002: Watcher CRD sync automation
**Status:** 🔄 In Progress  
**Priority:** Medium  
**Implementation:**
- `charts/zen-watcher/CRD_SYNC.md` - CRD synchronization documentation
- `charts/zen-watcher/templates/observation_crd.yaml` - Observation CRD
- `charts/zen-watcher/templates/observationfilter_crd.yaml` - Filter CRD
- `charts/zen-watcher/templates/observationmapping_crd.yaml` - Mapping CRD

**Outstanding:**
- Automated CRD version migration
- CRD schema validation in CI

---

## Chart Features

### zen-agent Chart

**Current Version:** 1.0.2  
**Key Features:**
- SSA-based remediation execution
- HMAC authentication to SaaS
- mTLS support
- Leader election (multi-replica)
- Prometheus metrics endpoint
- Pod security standards (restricted profile)
- Network policies

**Configuration:**
- `saas.endpoint` - SaaS API endpoint (FQDN only, no .svc.cluster.local)
- `saas.clusterToken` - Bootstrap token (required)
- `tenant.id`, `cluster.id` - Tenant/cluster identification
- `tls.enabled` - Enable mTLS
- `caMount.enabled` - Custom CA certificate

**Dependencies:**
- zen-watcher (embedded as subchart)

### zen-watcher Chart

**Current Version:** 1.0.1  
**Key Features:**
- Kubernetes resource observation
- CRD-based configuration (ObservationFilter, ObservationMapping)
- Prometheus metrics (ServiceMonitor, VMServiceScrape)
- Network policies
- Pod disruption budgets
- Horizontal pod autoscaling

**Configuration:**
- `image.repository`, `image.tag` - Container image
- `resources` - Resource limits/requests
- `hpa.enabled` - Horizontal pod autoscaling
- `networkPolicy.enabled` - Network policy enforcement

---

## Security Incident Flow Support

**See:** [SECURITY_INCIDENT_FLOW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW.md) for current implementation  
**See:** [SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md) for target production architecture  
**See:** [SECURITY_INCIDENT_EXPERT_REVIEW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_EXPERT_REVIEW.md) for expert review

### Profile → Incident Flow Mapping (Current)

| Helm Profile | Execution Modes | Approval Modes | Validation | Rollback | Status |
|--------------|----------------|----------------|------------|----------|--------|
| **Local MVP** | SSA immediate | UI immediate | Basic probes | Automatic | ✅ CURRENT |
| **GitOps-Driven** | SSA immediate + scheduled, GitOps PR immediate | UI + Slack | HTTP + K8s + metrics | Automatic + Git revert | ✅ CURRENT |
| **AWS/Open Demo** | SSA immediate + scheduled, GitOps PR immediate | UI + Slack + scheduled | All probe types | Automatic + manual | ✅ CURRENT |

**Current Implementation Notes:**
- **Scheduled SSA:** ✅ CURRENT (CRD-based in-cluster scheduler)
- **Scheduled GitOps PR:** 🔮 FUTURE (delayed PR creation not implemented)
- **GitOps PR:** ✅ CURRENT (immediate PR creation only)

**Expected Behaviors per Profile:**
- **Local MVP:** Fast iteration, minimal security (dev only)
- **GitOps-Driven:** Audit trail via Git, async approval workflows (PRs created immediately)
- **AWS/Open Demo:** Production-like, all security features enabled (except scheduled GitOps)

### Helm Security Incident Support Status

**Current Implementation (✅ DONE):**
1. **SSA Immediate Execution:** Agent executes immediate remediations via Server-Side Apply
2. **SSA Scheduled Execution:** Agent creates CRD with schedule, in-cluster scheduler executes at scheduled time (resilient to SaaS outage)
3. **GitOps PR Immediate:** zen-gitops creates PR immediately, FluxCD/ArgoCD syncs to cluster
4. **mTLS Optional:** Agent supports mTLS to SaaS (production-ready, not required)
5. **Pod Security:** Restricted profile enforced (non-root, read-only rootfs, dropped capabilities)

**Target Production (🔮 FUTURE):**
1. **GitOps PR Scheduled:** zen-gitops creates PR at scheduled time (delayed PR creation) - 3 design options in [SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW_PRODUCTION_TARGET.md#scheduled-gitops-pr-target)
2. **Agent HA:** Formal leader election for multi-replica agents (RM-AGENT-002) - Mitigates T1, T8 in [THREAT_MODEL_PRODUCTION.md](../../../zen-alpha/docs/09-security/THREAT_MODEL_PRODUCTION.md)
3. **NetworkPolicy:** Agent egress policies enforced (RM-HELM-001) - Mitigates T1 (compromised agent)
4. **RBAC Scoping:** Agent permissions scoped to specific resources/namespaces (RM-HELM-001) - Mitigates T1, T9
5. **mTLS Required:** mTLS mandatory for production (RM-SEC-001) - Mitigates T3 (MITM attack)
6. **External Secrets:** Vault/AWS Secrets Manager for bootstrap tokens (RM-AGENT-004) - Mitigates T2 (stolen tokens)

**Compliance Alignment:**
- **SOC2 CC6.1:** RBAC scoping (RM-HELM-001)
- **SOC2 CC6.7:** NetworkPolicy enforcement (RM-HELM-001)
- **ISO A.8.5:** mTLS required (RM-SEC-001)
- **ISO A.8.12:** NetworkPolicy for data leakage prevention (RM-HELM-001)

**Note:** Scheduled GitOps PR is target behavior (3 design options documented). Current: GitOps creates PRs immediately.

---

### Helm-Level Assumptions (Affects Incident Handling)

1. **ServiceAccount & RBAC (✅ DONE):**
   - **Assumption:** Agent has `get/list/watch` on all resources (observation)
   - **Assumption:** Agent has `create/update/patch/delete` on ZenAgentRemediation CRDs
   - **Impact:** Broad permissions required for incident detection and execution
   - **Roadmap:** RM-HELM-001 (scope RBAC for production)

2. **NetworkPolicy (⚠️  TODO - RM-HELM-001):**
   - **Assumption:** Agent can egress to SaaS API (HTTPS)
   - **Assumption:** Agent can egress to K8s API server
   - **Impact:** Without NetworkPolicy, agent has unrestricted egress
   - **Roadmap:** RM-HELM-001 (add NetworkPolicy template)

3. **Pod Security (✅ DONE):**
   - **Assumption:** Agent runs as non-root, read-only root filesystem
   - **Assumption:** All capabilities dropped
   - **Impact:** Restricted profile enforced, compliant with PSS

4. **Secrets Management (⚠️  PARTIAL):**
   - **Assumption:** Bootstrap token stored in K8s Secret
   - **Assumption:** HMAC key derived via HKDF (not stored)
   - **Impact:** Bootstrap token is sensitive, needs external secret management
   - **Roadmap:** RM-AGENT-004 (external secret providers)

5. **Metrics & Observability (✅ DONE):**
   - **Assumption:** Prometheus scrapes /metrics endpoint
   - **Assumption:** Metrics used for watchdog validation
   - **Impact:** Metrics-based probes require Prometheus in cluster
   - **Default:** `metrics.enabled: true` (recommended for all profiles)

---

## Golden Path Alignment

### Local MVP Golden Script

**Script:** `zen-alpha/scripts/demo/run-local-real-pipeline.sh`

**Chart Usage:**
- zen-agent: Installed in customer cluster (Cluster B)
- zen-watcher: Installed as dependency of zen-agent
- Values: Configured with sandbox SaaS endpoints

**Requirements:**
- TLS enabled
- Bootstrap tokens configured
- Network connectivity to sandbox SaaS

### GitOps Golden Paths

**Concept:** Charts as targets for GitOps remediations

**Implementation Status:** Planned (not yet wired to /clusters/new)

**Design:**
- zen-gitops service manages Git repos
- Remediation execution_mode=gitops creates commits
- FluxCD/ArgoCD syncs changes to clusters
- Agent validates via webhook or polling

**Constraints (from GUARDRAILS.md):**
- No direct coupling to /clusters/new yet
- Charts remain self-contained and testable independently
- Integration point designed, not implemented

### AWS/Open Demo Orchestration

**Status:** Planned (MAIN AI responsibility)

**Expected Chart Usage:**
- Deploy zen-agent + zen-watcher to demo AWS clusters
- Validate against public SaaS instance
- Demo golden scenarios to partners

**Requirements:**
- Charts must support AWS EKS
- Network egress policies for public SaaS
- TLS with public certificates (not dev mkcert)

**Outstanding:**
- AWS-specific values files
- EKS IRSA integration
- Public demo SaaS endpoint configuration

---

## Guardrails Alignment

### Allowed Registries (from GUARDRAILS.md)

**Current:**
- zen-agent: `kubezen/zen-agent` ✅
- zen-watcher: `kubezen/zen-watcher` ✅

**Policy:**
- Prefer `kubezen/*` (Docker Hub official namespace)
- Internal dev: `registry.kube-zen.io:5000/*`
- CI: `ghcr.io/kube-zen/*`
- Prohibited: `docker.io/*` (except kubezen namespace)

**Validation:**
- `scripts/ci/helm-lint-and-render.sh` checks registry policies when `RUN_GUARDRAILS=1`

### Environment Gating

**All helm validation scripts are opt-in:**
- `RUN_HELM_LINT=1` - Enable lint/render checks
- `RUN_HELM_SMOKE=1` - Enable k3d smoke tests
- `RUN_GUARDRAILS=1` - Enable strict guardrails mode

**Default:** All disabled (safe to ignore)

---

## CI Integration

### From zen-main CI

**Integration Hook:** `zen-alpha/scripts/ci/helm-charts-optional.sh`

**Usage:**
```bash
# Enable lint only
RUN_HELM_LINT=1 ./scripts/ci/helm-charts-optional.sh

# Enable smoke only
RUN_HELM_SMOKE=1 ./scripts/ci/helm-charts-optional.sh

# Enable both with guardrails
RUN_HELM_LINT=1 RUN_HELM_SMOKE=1 RUN_GUARDRAILS=1 ./scripts/ci/helm-charts-optional.sh
```

**Default:** Disabled (opt-in only, no effect on existing CI gates)

---

## Outstanding Work

### High Priority
- RM-HELM-001: TLS hardening completion (cert rotation, OCSP)
- RM-HELM-002: CRD sync automation

### Medium Priority
- Value matrix expansion (more test scenarios)
- AWS/EKS-specific values files
- Chart versioning strategy documentation

### Low Priority
- OCI registry support
- Helm v4 compatibility testing
- Chart museum integration

---

## See Also

- [Platform Roadmap](../../../zen-alpha/docs/ROADMAP.md) - Complete platform roadmap
- [Scripts README](../scripts/README.md) - Helm validation scripts
- [GUARDRAILS.md](../../../zen-alpha/docs/GUARDRAILS.md) - Platform guardrails
- [Agent-Watcher Integration](../../../zen-alpha/docs/00-overview/AGENT_WATCHER_INTEGRATION.md) - Integration architecture

