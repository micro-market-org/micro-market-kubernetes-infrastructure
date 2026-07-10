#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
GCP_REGION="${GCP_REGION:-europe-central2}"
GCP_ZONE="${GCP_ZONE:-europe-central2-a}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=terraform/kubernetes/scripts/_common.sh
source "${SCRIPT_DIR}/scripts/_common.sh"

# Credentials come from the environment; never reference key files in the repo.
: "${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
: "${GOOGLE_APPLICATION_CREDENTIALS:?Set GOOGLE_APPLICATION_CREDENTIALS to a service-account key path (or use gcloud ADC)}"

VAR_FILE="$(require_tfvars_file "${ENVIRONMENT}")"

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

terraform_init_backend "gcp"
terraform_select_or_create_workspace "${ENVIRONMENT}"

terraform plan -destroy \
  -var-file="${VAR_FILE}" \
  -var cloud_provider="gcp" \
  -var gcp_project="${GCP_PROJECT_ID}" \
  -var gcp_region="${GCP_REGION}" \
  -var gcp_zone="${GCP_ZONE}" \
  -var gcp_credentials="${GOOGLE_APPLICATION_CREDENTIALS}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -out=tfplan.destroy

echo ""
echo "=== [CONFIRMATION] Review the destroy plan above. Destroy GCP Kubernetes bootstrap resources? (yes/no) ==="
read -r confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" != "yes" ]]; then
  echo "=== [INFO] Destruction cancelled by user ==="
  rm -f tfplan.destroy
  exit 0
fi

if [[ "${ARGOCD_CASCADE_SKIP:-false}" != "true" ]]; then
  echo "=== [INFO] Fetching GKE credentials for ArgoCD cascade cleanup ==="
  gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
  gcloud container clusters get-credentials "gke-${PROJECT_NAMESPACE}-${ENVIRONMENT}" \
    --zone="${GCP_ZONE}" --project="${GCP_PROJECT_ID}"

  echo "=== [INFO] Cascade-deleting ArgoCD Applications before destroy ==="
  bash ./destroy_argocd_apps.sh
else
  echo "=== [WARN] ARGOCD_CASCADE_SKIP=true — skipping ArgoCD cascade cleanup; namespace may get stuck in Terminating and DNS records may orphan (see ADR-10). ===" >&2
fi

echo "=== [INFO] Applying Terraform destroy plan ==="
terraform apply tfplan.destroy

rm -f tfplan.destroy
