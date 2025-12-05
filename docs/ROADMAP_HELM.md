# Helm Charts Roadmap

**Repository:** ~/letsgo/helm-charts  
**Parent Roadmap:** [zen-alpha/docs/ROADMAP.md](../../../zen-alpha/docs/ROADMAP.md)  
**Charts:** zen-agent, zen-watcher  
**Architecture Context:** [COMPREHENSIVE_ARCHITECTURE.md](../../../zen-alpha/docs/01-architecture/COMPREHENSIVE_ARCHITECTURE.md) (see "Helm Charts & Deployment" section for system integration)  
**Security Incident Flow:** [SECURITY_INCIDENT_FLOW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW.md) - How charts support incident handling

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

**See:** [SECURITY_INCIDENT_FLOW.md](../../../zen-alpha/docs/01-architecture/SECURITY_INCIDENT_FLOW.md) for complete incident flow

### Profile → Incident Flow Mapping

| Helm Profile | Execution Modes | Approval Modes | Validation | Rollback |
|--------------|----------------|----------------|------------|----------|
| **Local MVP** | SSA only | UI immediate | Basic probes | Automatic |
| **GitOps-Driven** | SSA + GitOps PR | UI + Slack | HTTP + K8s + metrics | Automatic + Git revert |
| **AWS/Open Demo** | All modes | All modes | All probe types | Automatic + manual |

**Expected Behaviors per Profile:**
- **Local MVP:** Fast iteration, minimal security (dev only)
- **GitOps-Driven:** Audit trail via Git, async approval workflows
- **AWS/Open Demo:** Production-like, all security features enabled

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

