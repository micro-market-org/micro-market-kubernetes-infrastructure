#!/usr/bin/env bash
set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-300s}"

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

wait_until_label_gone() {
  local label="$1"
  local timeout_seconds="${WAIT_TIMEOUT%s}"
  local interval=5
  local elapsed=0
  local remaining

  while true; do
    remaining=$(kubectl get applications.argoproj.io -n "${ARGOCD_NAMESPACE}" \
      -l "${label}" -o name 2>/dev/null || true)

    if [[ -z "${remaining}" ]]; then
      return 0
    fi

    if (( elapsed >= timeout_seconds )); then
      echo "Timed out waiting for platform Applications (label ${label}) to delete. Still present:" >&2
      echo "${remaining}" >&2
      exit 1
    fi

    sleep "${interval}"
    elapsed=$((elapsed + interval))
  done
}

require_kubectl
ensure_namespace

mapfile -t microservice_apps < <(
  kubectl get applications.argoproj.io -n "${ARGOCD_NAMESPACE}" \
    -l app.kubernetes.io/part-of=microservices \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true
)

# Delete the generator first so it stops reconciling the 12 generated
# Applications while the individual application finalizers clean up workloads.
delete_if_present "applicationsets.argoproj.io" "microservices"

for app in "${microservice_apps[@]}"; do
  delete_if_present "applications.argoproj.io" "${app}"
done
delete_if_present "applications.argoproj.io" "platform-root"

wait_until_gone "applicationsets.argoproj.io" "microservices"
for app in "${microservice_apps[@]}"; do
  wait_until_gone "applications.argoproj.io" "${app}"
done
wait_until_gone "applications.argoproj.io" "platform-root"

# platform-root's finalizer triggers ArgoCD's own cascade-prune of the ~15
# platform-<addon> Applications it manages; wait on those explicitly instead of
# assuming the cascade finished silently.
wait_until_label_gone "app.kubernetes.io/part-of=platform"
wait_until_gone "appprojects.argoproj.io" "platform"

echo "ArgoCD ApplicationSet/Application cascade deletion completed."
