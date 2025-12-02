# CRD Synchronization

## Observation CRD

The `observation_crd.yaml` file in this chart's `templates/` directory is **not maintained here**.

### Source of Truth

**Canonical location**: [github.com/kube-zen/zen-watcher/deployments/crds/observation_crd.yaml](https://github.com/kube-zen/zen-watcher/blob/main/deployments/crds/observation_crd.yaml)

This file is automatically synced from the zen-watcher repository and should **not be edited directly** in this repository.

### Sync Process

When the CRD is updated in the zen-watcher repository:

1. Changes are made to `deployments/crds/observation_crd.yaml` in zen-watcher
2. Run `make sync-crd-to-chart` from the zen-watcher repository
3. This copies the CRD to `charts/zen-watcher/templates/observation_crd.yaml` in this repository
4. Commit the change in this repository

### Detecting Drift

If you suspect the CRD has been manually edited or is out of sync:

1. Check the header comment in `templates/observation_crd.yaml` - it should indicate the source
2. Compare with the canonical file in zen-watcher repository
3. If drift is detected, sync using the process above

### CI/CD Integration

Consider adding a drift check in CI/CD:

```bash
# Compare CRD with canonical source
diff zen-watcher/deployments/crds/observation_crd.yaml \
     charts/zen-watcher/templates/observation_crd.yaml
```

This ensures the CRD stays in sync with the source repository.

### Documentation

- **zen-watcher CRD docs**: [docs/CRD.md](https://github.com/kube-zen/zen-watcher/blob/main/docs/CRD.md)
- **Source repository**: [github.com/kube-zen/zen-watcher](https://github.com/kube-zen/zen-watcher)

