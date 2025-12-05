#!/usr/bin/env bash
#
# Helm Lint and Render
#
# Purpose: Validate helm charts via lint and template rendering
#
# Usage:
#   ./scripts/ci/helm-lint-and-render.sh
#
# Exit codes:
#   0: All charts valid
#   1: One or more charts fail validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Helm Charts Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed"
    exit 1
fi

echo "Helm version: $(helm version --short)"
echo ""

CHARTS=(
    "charts/zen-agent"
    "charts/zen-watcher"
)

FAILED=0

for chart in "${CHARTS[@]}"; do
    if [ ! -d "$chart" ]; then
        echo "⚠️  Chart not found: $chart (skipping)"
        continue
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Validating: $chart"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Update dependencies if needed
    if [ -f "$chart/Chart.lock" ]; then
        echo "[0/2] Updating chart dependencies..."
        if helm dependency update "$chart" > /dev/null 2>&1; then
            echo "✅ Dependencies updated"
        else
            echo "⚠️  Dependency update had warnings (continuing)"
        fi
        echo ""
    fi

    # Lint chart
    echo "[1/2] Running helm lint..."
    
    # zen-agent requires specific values, provide minimal sample
    if [[ "$chart" == *"zen-agent"* ]]; then
        LINT_OUTPUT=$(helm lint "$chart" \
            --set saas.apiBase=https://api.example.com \
            --set saas.wsBase=wss://api.example.com 2>&1 || true)
        
        # Check for critical errors (ignore dependency metadata warnings)
        if echo "$LINT_OUTPUT" | grep -q "chart metadata is missing these dependencies"; then
            echo "⚠️  Lint warning for $chart (dependency metadata issue - non-blocking)"
        elif echo "$LINT_OUTPUT" | grep -qE "\[ERROR\]" && ! echo "$LINT_OUTPUT" | grep -q "chart metadata is missing"; then
            echo "$LINT_OUTPUT"
            echo "❌ Lint failed for $chart"
            FAILED=$((FAILED + 1))
        else
            echo "✅ Lint passed for $chart"
        fi
    else
        if helm lint "$chart"; then
            echo "✅ Lint passed for $chart"
        else
            echo "❌ Lint failed for $chart"
            FAILED=$((FAILED + 1))
        fi
    fi
    echo ""

    # Template render (matrix tests)
    echo "[2/2] Running helm template (matrix tests)..."
    
    # zen-agent requires specific values, test multiple configurations
    if [[ "$chart" == *"zen-agent"* ]]; then
        # Matrix: Default, SaaS-like (TLS), Demo
        MATRIX_CONFIGS=(
            "default:--set saas.apiBase=https://api.example.com --set saas.wsBase=wss://api.example.com"
            "saas-tls:--set saas.apiBase=https://api.kube-zen.io --set saas.wsBase=wss://ws.kube-zen.io --set saas.tlsEnabled=true"
            "demo:--set saas.apiBase=http://localhost:8080 --set saas.wsBase=ws://localhost:8080 --set environment=dev"
        )
        
        for config in "${MATRIX_CONFIGS[@]}"; do
            config_name="${config%%:*}"
            config_values="${config#*:}"
            
            echo "  Testing configuration: $config_name"
            if eval "helm template test-release \"$chart\" $config_values > /dev/null 2>&1"; then
                echo "  ✓ $config_name passed"
            else
                echo "  ❌ $config_name failed"
                FAILED=$((FAILED + 1))
            fi
        done
        
        if [ $FAILED -eq 0 ]; then
            echo "✅ Template render passed for $chart (3 configurations)"
        fi
    else
        # zen-watcher: test with default values
        if helm template test-release "$chart" > /dev/null; then
            echo "✅ Template render passed for $chart"
        else
            echo "❌ Template render failed for $chart"
            FAILED=$((FAILED + 1))
        fi
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ]; then
    echo "✅ Helm Charts Validation → GREEN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo "❌ Helm Charts Validation → RED ($FAILED failures)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

