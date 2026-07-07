#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
GCP_REGION="${GCP_REGION:-europe-central2}"
GCP_ZONE="${GCP_ZONE:-europe-central2-a}"
REAL_DOMAIN="${REAL_DOMAIN:-danielgherasim.com}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"
VAR_FILE="./tfvars_files/${ENVIRONMENT}.tfvars"

if [[ ! -f "${VAR_FILE}" ]]; then
  echo "Missing variable file: ${VAR_FILE}" >&2
  exit 1
fi

: "${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
: "${GOOGLE_APPLICATION_CREDENTIALS:?Set GOOGLE_APPLICATION_CREDENTIALS to a service-account key path (or use gcloud ADC)}"

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

gcloud container clusters get-credentials "gke-${PROJECT_NAMESPACE}-${ENVIRONMENT}" \
  --zone="${GCP_ZONE}" --project="${GCP_PROJECT_ID}"

# Run the ArgoCD cascade-delete helper before Terraform destroy.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "${SCRIPT_DIR}/../kubernetes/destroy_argocd_apps.sh" ]]; then
  "${SCRIPT_DIR}/../kubernetes/destroy_argocd_apps.sh"
fi

terraform init -reconfigure \
  -backend-config="bucket=terraformmicroservicesstate" \
  -backend-config="prefix=kubernetes/gcp/${ENVIRONMENT}"

terraform plan -destroy \
  -var-file="${VAR_FILE}" \
  -var gcp_project="${GCP_PROJECT_ID}" \
  -var gcp_region="${GCP_REGION}" \
  -var gcp_zone="${GCP_ZONE}" \
  -var gcp_credentials="${GOOGLE_APPLICATION_CREDENTIALS}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var real_domain="${REAL_DOMAIN}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -out=tfplan.destroy

terraform apply tfplan.destroy

rm -f tfplan.destroy
