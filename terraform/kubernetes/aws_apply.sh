#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
REAL_DOMAIN="${REAL_DOMAIN:-danielgherasim.com}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"
VAR_FILE="./tfvars_files/${ENVIRONMENT}.tfvars"

# Load secrets from .env if present (never committed — see .gitignore)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.env"
if [[ -f "${ENV_FILE}" ]]; then
  set -o allexport
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +o allexport
fi

: "${AWS_TF_STATE_BUCKET:?Set AWS_TF_STATE_BUCKET in .env or export it}"
: "${GITLAB_TOKEN:?Set GITLAB_TOKEN in .env or export it}"
: "${GITLAB_USERNAME:?Set GITLAB_USERNAME in .env or export it}"

STATE_KEY="kubernetes/aws/${ENVIRONMENT}/terraform.tfstate"

if [[ ! -f "${VAR_FILE}" ]]; then
  echo "Missing variable file: ${VAR_FILE}" >&2
  exit 1
fi

cp backends/s3.tf backend_override.tf

terraform init -reconfigure \
  -backend-config="backends/s3.hcl" \
  -backend-config="bucket=${AWS_TF_STATE_BUCKET}" \
  -backend-config="key=${STATE_KEY}"

# Use the same workspace name as CI so state is shared
if ! terraform workspace list | grep -q "^[* ]*${ENVIRONMENT}$"; then
  terraform workspace new "${ENVIRONMENT}"
else
  terraform workspace select "${ENVIRONMENT}"
fi

terraform plan \
  -var-file="${VAR_FILE}" \
  -var cloud_provider="aws" \
  -var aws_region="${AWS_REGION}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var real_domain="${REAL_DOMAIN}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -var aws_remote_state_bucket="${AWS_TF_STATE_BUCKET}" \
  -var gitlab_token="${GITLAB_TOKEN}" \
  -var gitlab_username="${GITLAB_USERNAME}" \
  -out=tfplan

echo
read -rp "Apply the plan above? [y/N] " CONFIRM
if [[ "${CONFIRM}" != "y" && "${CONFIRM}" != "Y" ]]; then
  echo "Aborted."
  rm -f tfplan
  exit 0
fi

terraform apply tfplan
rm -f tfplan
