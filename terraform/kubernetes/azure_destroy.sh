#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-prod}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-azure}"

if [ -z "${ARM_CLIENT_ID:-}" ] || [ -z "${ARM_CLIENT_SECRET:-}" ] || [ -z "${ARM_TENANT_ID:-}" ] || [ -z "${ARM_SUBSCRIPTION_ID:-}" ]; then
  echo "Error: Azure credentials not set. Set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, and ARM_SUBSCRIPTION_ID." >&2
  exit 1
fi

echo "=== [INFO] Destroying environment: $ENVIRONMENT ==="
echo "=== [INFO] Project namespace: $PROJECT_NAMESPACE ==="

export TF_VAR_client_id=$ARM_CLIENT_ID
export TF_VAR_client_secret=$ARM_CLIENT_SECRET
export TF_VAR_tenant_id=$ARM_TENANT_ID
export TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_cloud_provider=$CLOUD_PROVIDER
export TF_VAR_project_name=$PROJECT_NAMESPACE
export TF_VAR_environment=$ENVIRONMENT

echo "=== [INFO] Initializing Terraform ==="
cp backends/azurerm.tf backend_override.tf
terraform init -reconfigure -backend-config="backends/azurerm.hcl"

echo "=== [INFO] Selecting workspace: $ENVIRONMENT ==="
terraform workspace select "$ENVIRONMENT"

echo "=== [INFO] Destroying Terraform resources ==="
terraform destroy --var-file=./tfvars_files/$ENVIRONMENT.tfvars -auto-approve

echo "=== [SUCCESS] Destruction completed successfully ==="
