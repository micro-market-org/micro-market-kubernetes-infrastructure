#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"

# Load secrets from .env if present (never committed — see .gitignore)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=terraform/kubernetes/scripts/_common.sh
source "${SCRIPT_DIR}/scripts/_common.sh"
ENV_FILE="${SCRIPT_DIR}/../../.env"
if [[ -f "${ENV_FILE}" ]]; then
  set -o allexport
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +o allexport
fi

: "${AWS_TF_STATE_BUCKET:?Set AWS_TF_STATE_BUCKET in .env or export it}"

STATE_KEY="kubernetes/aws/${ENVIRONMENT}/terraform.tfstate"
VAR_FILE="$(require_tfvars_file "${ENVIRONMENT}")"

terraform_init_backend "aws"
terraform_select_or_create_workspace "${ENVIRONMENT}"

terraform plan \
  -var-file="${VAR_FILE}" \
  -var cloud_provider="aws" \
  -var aws_region="${AWS_REGION}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -var aws_remote_state_bucket="${AWS_TF_STATE_BUCKET}" \
  -out=tfplan -lock=false

echo
read -rp "Apply the plan above? [y/N] " CONFIRM
if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
  echo "Aborted."
  rm -f tfplan
  exit 0
fi

terraform apply tfplan
rm -f tfplan
