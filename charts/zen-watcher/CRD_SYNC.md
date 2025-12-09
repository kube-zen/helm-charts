# CRD Synchronization

## CRDs Managed

The following CRD files in this chart's `templates/` directory are **not maintained here**:
- `observation_crd.yaml` - Observation resource definition
- `observationfilter_crd.yaml` - Filter configuration
- `observationmapping_crd.yaml` - Field mapping configuration
- `observationsourceconfig_crd.yaml` - Source configuration with ingester field

## Observation CRD

### Source of Truth

**Canonical locations**:
- [observation_crd.yaml](https://github.com/kube-zen/zen-watcher/blob/main/deployments/crds/observation_crd.yaml)
- [observationfilter_crd.yaml](https://github.com/kube-zen/zen-watcher/blob/main/deployments/crds/observationfilter_crd.yaml)
- [observationmapping_crd.yaml](https://github.com/kube-zen/zen-watcher/blob/main/deployments/crds/observationmapping_crd.yaml)
- [observationsourceconfig_crd.yaml](https://github.com/kube-zen/zen-watcher/blob/main/deployments/crds/observationsourceconfig_crd.yaml)

These files are automatically synced from the zen-watcher repository and should **not be edited directly** in this repository.

### Sync Process

When CRDs are updated in the zen-watcher repository:

1. Changes are made to `deployments/crds/*.yaml` in zen-watcher
2. Copy the updated CRD(s) to `charts/zen-watcher/templates/` in this repository
3. Commit the change in this repository

**Note**: The `observationsourceconfig_crd.yaml` includes the new `ingester` field (replacing `adapterType`). See the [ingester migration guide](https://github.com/kube-zen/zen-watcher/blob/main/docs/INGESTER_MIGRATION_GUIDE.md) for details.

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

