#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
REAL_DOMAIN="${REAL_DOMAIN:-danielgherasim.com}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"
VAR_FILE="./tfvars_files/${ENVIRONMENT}.tfvars"

if [[ ! -f "${VAR_FILE}" ]]; then
  echo "Missing variable file: ${VAR_FILE}" >&2
  exit 1
fi

if [[ -z "${ARM_CLIENT_ID:-}" || -z "${ARM_CLIENT_SECRET:-}" || -z "${ARM_TENANT_ID:-}" || -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
  echo "Error: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, and ARM_SUBSCRIPTION_ID must be set." >&2
  exit 1
fi

# Run the ArgoCD cascade-delete helper before Terraform destroy.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "${SCRIPT_DIR}/../kubernetes/destroy_argocd_apps.sh" ]]; then
  "${SCRIPT_DIR}/../kubernetes/destroy_argocd_apps.sh"
fi

terraform init -reconfigure \
  -backend-config="resource_group_name=rg-infrastructure" \
  -backend-config="storage_account_name=terraformmicrostate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=kubernetes-azure-${ENVIRONMENT}.tfstate"

terraform plan -destroy \
  -var-file="${VAR_FILE}" \
  -var client_id="${ARM_CLIENT_ID}" \
  -var client_secret="${ARM_CLIENT_SECRET}" \
  -var tenant_id="${ARM_TENANT_ID}" \
  -var subscription_id="${ARM_SUBSCRIPTION_ID}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var real_domain="${REAL_DOMAIN}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -out=tfplan.destroy

terraform apply tfplan.destroy

rm -f tfplan.destroy
