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

gcloud container clusters get-credentials "gke-${PROJECT_NAMESPACE}-${ENVIRONMENT}" \
  --zone="${GCP_ZONE}" --project="${GCP_PROJECT_ID}"

terraform_init_backend "gcp"
terraform_select_or_create_workspace "${ENVIRONMENT}"

terraform plan \
  -var-file="${VAR_FILE}" \
  -var cloud_provider="gcp" \
  -var gcp_project="${GCP_PROJECT_ID}" \
  -var gcp_region="${GCP_REGION}" \
  -var gcp_zone="${GCP_ZONE}" \
  -var gcp_credentials="${GOOGLE_APPLICATION_CREDENTIALS}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -out=tfplan

echo ""
echo "=== [CONFIRMATION] Do you want to apply these changes? (yes/no) ==="
read -r confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" != "yes" ]]; then
  echo "=== [INFO] Deployment cancelled by user ==="
  rm -f tfplan
  exit 0
fi

terraform apply tfplan

rm -f tfplan
