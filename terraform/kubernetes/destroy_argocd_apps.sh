#!/usr/bin/env bash
set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-180s}"

APPS=(
  platform-root
  catalog-dev
  catalog-staging
  catalog-prod
  orders-dev
  orders-staging
  orders-prod
  audit-dev
  audit-staging
  audit-prod
  micro-market-frontend-dev
  micro-market-frontend-staging
  micro-market-frontend-prod
)

require_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl is required for ArgoCD cascade deletion." >&2
    exit 1
  fi
}

ensure_namespace() {
  if ! kubectl get namespace "${ARGOCD_NAMESPACE}" >/dev/null 2>&1; then
    echo "Namespace '${ARGOCD_NAMESPACE}' does not exist; nothing to cascade-delete."
    exit 0
  fi
}

delete_if_present() {
  local resource="$1"
  local name="$2"

  if ! kubectl get "${resource}" "${name}" -n "${ARGOCD_NAMESPACE}" >/dev/null 2>&1; then
    echo "${resource}/${name} not found; skipping."
    return
  fi

  echo "Deleting ${resource}/${name} from namespace ${ARGOCD_NAMESPACE}..."
  kubectl patch "${resource}" "${name}" -n "${ARGOCD_NAMESPACE}" --type merge \
    -p '{"metadata":{"finalizers":["resources-finalizer.argocd.argoproj.io"]}}' >/dev/null
  kubectl delete "${resource}" "${name}" -n "${ARGOCD_NAMESPACE}" --cascade=foreground --wait=false
}

wait_until_gone() {
  local resource="$1"
  local name="$2"

  if kubectl get "${resource}" "${name}" -n "${ARGOCD_NAMESPACE}" >/dev/null 2>&1; then
    kubectl wait --for=delete "${resource}/${name}" -n "${ARGOCD_NAMESPACE}" \
      --timeout="${WAIT_TIMEOUT}" || {
        echo "Timed out waiting for ${resource}/${name} to delete." >&2
        exit 1
      }
  fi
}

require_kubectl
ensure_namespace

# Delete the generator first so it stops reconciling the 12 generated
# Applications while the individual application finalizers clean up workloads.
delete_if_present "applicationsets.argoproj.io" "microservices"

for app in "${APPS[@]}"; do
  delete_if_present "applications.argoproj.io" "${app}"
done

wait_until_gone "applicationsets.argoproj.io" "microservices"
for app in "${APPS[@]}"; do
  wait_until_gone "applications.argoproj.io" "${app}"
done

echo "ArgoCD ApplicationSet/Application cascade deletion completed."
