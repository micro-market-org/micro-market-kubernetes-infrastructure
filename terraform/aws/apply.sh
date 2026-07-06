#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
REAL_DOMAIN="${REAL_DOMAIN:-danielgherasim.com}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
STATE_BUCKET="${TF_STATE_BUCKET:-terraform-state-${AWS_ACCOUNT_ID}-${AWS_REGION}}"
STATE_KEY="${TF_STATE_KEY:-kubernetes/aws/${ENVIRONMENT}/terraform.tfstate}"
VAR_FILE="./tfvars_files/${ENVIRONMENT}.tfvars"

if [[ ! -f "${VAR_FILE}" ]]; then
  echo "Missing variable file: ${VAR_FILE}" >&2
  exit 1
fi

# Credentials come from AWS_* environment variables (or an assumed role).
terraform init -reconfigure \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="use_lockfile=true"

terraform plan \
  -var-file="${VAR_FILE}" \
  -var aws_region="${AWS_REGION}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var real_domain="${REAL_DOMAIN}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -out=tfplan

terraform apply tfplan

rm -f tfplan
