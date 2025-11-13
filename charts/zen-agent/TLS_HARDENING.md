# Security Note: TLS_INSECURE Usage Policy

## Overview

`tlsInsecure` is a **dev-only escape hatch** for local testing with self-signed certificates. It is **NOT** a runtime feature and must **NEVER** be used in production or staging environments.

## Security Posture

### Default: Secure-by-Default
- `tlsInsecure: false` (default)
- TLS certificate verification is **always enabled** unless explicitly disabled in dev

### Multi-Layer Gating
1. **Helm Schema**: `values.schema.json` enforces `environment=dev` when `tlsInsecure=true`
2. **Helm Template**: Deployment template fails fast if `tlsInsecure=true && environment!=dev`
3. **Agent Code**: Agent exits with `fatal_tls_insecure_in_prod` if `TLS_INSECURE=true` and `ENVIRONMENT != "dev"`
4. **Precheck**: `deploy-precheck.sh` fails if `tlsInsecure=true` in non-dev environments

## Preferred Path: CA Mount + Strict TLS

### For Dev Environments
```yaml
environment: dev
tlsInsecure: false  # Keep secure
caMount:
  enabled: true
  configMapName: zen-agent-ca
  mountPath: /usr/local/share/ca-certificates
```

### For Production Environments
```yaml
environment: prod
tlsInsecure: false  # Always false
caMount:
  enabled: false  # Use system CAs only
```

## References

- Chart values: `charts/zen-agent/values.yaml`
- Schema: `charts/zen-agent/values.schema.json`
- Precheck: `scripts/deploy-precheck.sh`
- Agent validation: `zen-agent/cmd/agent/main.go`
