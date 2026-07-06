#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
REAL_DOMAIN="${REAL_DOMAIN:-danielgherasim.com}"
CLUSTER_ISSUER="${CLUSTER_ISSUER:-letsencrypt-cloudflare-dns}"
STATE_KEY="${TF_STATE_KEY:-kubernetes/aws/${ENVIRONMENT}/terraform.tfstate}"
VAR_FILE="./tfvars_files/${ENVIRONMENT}.tfvars"

if [[ ! -f "${VAR_FILE}" ]]; then
  echo "Missing variable file: ${VAR_FILE}" >&2
  exit 1
fi

# Credentials come from AWS_* environment variables (or an assumed role).
cp backends/s3.tf backend_override.tf
terraform init -reconfigure \
  -backend-config="backends/s3.hcl" \
  -backend-config="key=${STATE_KEY}"

terraform plan -destroy \
  -var-file="${VAR_FILE}" \
  -var cloud_provider="aws" \
  -var aws_region="${AWS_REGION}" \
  -var environment="${ENVIRONMENT}" \
  -var project_name="${PROJECT_NAMESPACE}" \
  -var real_domain="${REAL_DOMAIN}" \
  -var cluster_issuer="${CLUSTER_ISSUER}" \
  -out=tfplan.destroy

terraform apply tfplan.destroy

rm -f tfplan.destroy
