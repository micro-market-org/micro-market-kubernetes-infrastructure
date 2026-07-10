#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"
STATE_KEY="${TF_STATE_KEY:-kubernetes/aws/${ENVIRONMENT}/terraform.tfstate}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=terraform/kubernetes/scripts/_common.sh
source "${SCRIPT_DIR}/scripts/_common.sh"

VAR_FILE="$(require_tfvars_file "${ENVIRONMENT}")"

# Credentials come from AWS_* environment variables (or an assumed role).
terraform_init_backend "aws"
terraform_select_or_create_workspace "${ENVIRONMENT}"

terraform plan -destroy \
  -var-file="${VAR_FILE}" \
  -var cloud_provider="aws" \
  -var aws_region="${AWS_REGION}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -out=tfplan.destroy

echo ""
echo "=== [CONFIRMATION] Review the destroy plan above. Destroy AWS Kubernetes bootstrap resources? (yes/no) ==="
read -r confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" != "yes" ]]; then
  echo "=== [INFO] Destruction cancelled by user ==="
  rm -f tfplan.destroy
  exit 0
fi

if [[ "${ARGOCD_CASCADE_SKIP:-false}" != "true" ]]; then
  echo "=== [INFO] Fetching EKS credentials for ArgoCD cascade cleanup ==="
  CLUSTER_NAME="${EKS_CLUSTER_NAME:-eks-${PROJECT_NAMESPACE}-${ENVIRONMENT}}"
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

  echo "=== [INFO] Cascade-deleting ArgoCD Applications before destroy ==="
  bash ./destroy_argocd_apps.sh
else
  echo "=== [WARN] ARGOCD_CASCADE_SKIP=true — skipping ArgoCD cascade cleanup; namespace may get stuck in Terminating and DNS records may orphan (see ADR-10). ===" >&2
fi

echo "=== [INFO] Applying Terraform destroy plan ==="
terraform apply tfplan.destroy

rm -f tfplan.destroy
