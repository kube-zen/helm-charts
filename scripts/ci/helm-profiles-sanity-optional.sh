#!/usr/bin/env bash
#
# Script Name: helm-profiles-sanity-optional.sh
# Category: CI / Optional
# Purpose: Validate all helm example values profiles (local/GitOps/AWS)
# Usage: RUN_HELM_PROFILES_SANITY=1 ./scripts/ci/helm-profiles-sanity-optional.sh
# Safety: Opt-in only, no impact on CI gates
# Guardrails: See zen-alpha/docs/GUARDRAILS.md
# Persona: SRE, Pilot Operator
# Profiles: All (validates local/GitOps/AWS example values)
# Roadmap: RM-QUICK-014

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Opt-in check
if [[ "${RUN_HELM_PROFILES_SANITY:-}" != "1" ]]; then
    echo "[SKIP] helm-profiles-sanity-optional.sh (set RUN_HELM_PROFILES_SANITY=1 to enable)"
    exit 0
fi

cd "${REPO_ROOT}" || exit 1

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Helm Profiles Sanity Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

EXAMPLES_DIR="${REPO_ROOT}/docs/examples"
CHARTS_DIR="${REPO_ROOT}/charts"

if [[ ! -d "${EXAMPLES_DIR}" ]]; then
    echo "[ERROR] Examples directory not found: ${EXAMPLES_DIR}"
    exit 1
fi

# Matrix: Profile → Chart → Status
echo "📊 Profile Validation Matrix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-20s %-15s %-10s %-10s\n" "Profile" "Chart" "Lint" "Render"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL_TESTS=0
FAILED_TESTS=0

# Test each example values file
for example_file in "${EXAMPLES_DIR}"/values-*.yaml; do
    if [[ ! -f "${example_file}" ]]; then
        continue
    fi
    
    profile_name=$(basename "${example_file}" .yaml | sed 's/values-//')
    
    # Test zen-agent chart
    CHART="${CHARTS_DIR}/zen-agent"
    
    if [[ ! -d "${CHART}" ]]; then
        echo "[WARN] Chart not found: ${CHART}"
        continue
    fi
    
    # Lint
    LINT_STATUS="✅"
    if ! helm lint "${CHART}" -f "${example_file}" \
        --set saas.clusterToken=test-token \
        --set tenant.id=test-tenant \
        --set cluster.id=test-cluster \
        > /tmp/helm-lint-${profile_name}.log 2>&1; then
        LINT_STATUS="❌"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Render
    RENDER_STATUS="✅"
    if ! helm template test-release "${CHART}" -f "${example_file}" \
        --set saas.clusterToken=test-token \
        --set tenant.id=test-tenant \
        --set cluster.id=test-cluster \
        > /tmp/helm-render-${profile_name}.log 2>&1; then
        RENDER_STATUS="❌"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    printf "%-20s %-15s %-10s %-10s\n" "${profile_name}" "zen-agent" "${LINT_STATUS}" "${RENDER_STATUS}"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Summary
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Total tests: ${TOTAL_TESTS}"
echo "  Passed: $((TOTAL_TESTS - FAILED_TESTS))"
echo "  Failed: ${FAILED_TESTS}"
echo ""

if [[ "${FAILED_TESTS}" -gt 0 ]]; then
    echo "❌ Some profile validations failed"
    echo ""
    echo "Check logs in /tmp/helm-lint-*.log and /tmp/helm-render-*.log"
    exit 1
else
    echo "✅ All profile validations passed"
fi

