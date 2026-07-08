#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BOOTSTRAP_ENV_FILE="${BOOTSTRAP_ENV_FILE:-${SCRIPT_DIR}/../../../utilities/scripts/.env.bootstrap}"

load_bootstrap_env_defaults() {
  local old_environment="${ENVIRONMENT-}"
  local old_project_namespace="${PROJECT_NAMESPACE-}"
  local old_cloud_provider="${CLOUD_PROVIDER-}"
  local old_arm_client_id="${ARM_CLIENT_ID-}"
  local old_arm_client_secret="${ARM_CLIENT_SECRET-}"
  local old_arm_tenant_id="${ARM_TENANT_ID-}"
  local old_arm_subscription_id="${ARM_SUBSCRIPTION_ID-}"
  local old_azure_rg="${AZURE_TF_STATE_RESOURCE_GROUP-}"
  local old_azure_account="${AZURE_TF_STATE_STORAGE_ACCOUNT-}"
  local old_azure_container="${AZURE_TF_STATE_CONTAINER-}"

  if [[ -f "${BOOTSTRAP_ENV_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${BOOTSTRAP_ENV_FILE}"
    echo "=== [INFO] Loaded defaults from ${BOOTSTRAP_ENV_FILE} ==="
  fi

  [[ -n "${old_environment}" ]] && ENVIRONMENT="${old_environment}"
  [[ -n "${old_project_namespace}" ]] && PROJECT_NAMESPACE="${old_project_namespace}"
  [[ -n "${old_cloud_provider}" ]] && CLOUD_PROVIDER="${old_cloud_provider}"
  [[ -n "${old_arm_client_id}" ]] && ARM_CLIENT_ID="${old_arm_client_id}"
  [[ -n "${old_arm_client_secret}" ]] && ARM_CLIENT_SECRET="${old_arm_client_secret}"
  [[ -n "${old_arm_tenant_id}" ]] && ARM_TENANT_ID="${old_arm_tenant_id}"
  [[ -n "${old_arm_subscription_id}" ]] && ARM_SUBSCRIPTION_ID="${old_arm_subscription_id}"
  [[ -n "${old_azure_rg}" ]] && AZURE_TF_STATE_RESOURCE_GROUP="${old_azure_rg}"
  [[ -n "${old_azure_account}" ]] && AZURE_TF_STATE_STORAGE_ACCOUNT="${old_azure_account}"
  [[ -n "${old_azure_container}" ]] && AZURE_TF_STATE_CONTAINER="${old_azure_container}"

  return 0
}

load_bootstrap_env_defaults

AZURE_TF_STATE_RESOURCE_GROUP="${AZURE_TF_STATE_RESOURCE_GROUP:-${AZURE_STATE_RESOURCE_GROUP:-rg-infrastructure}}"
AZURE_TF_STATE_STORAGE_ACCOUNT="${AZURE_TF_STATE_STORAGE_ACCOUNT:-${AZURE_STATE_STORAGE_ACCOUNT:-}}"
AZURE_TF_STATE_CONTAINER="${AZURE_TF_STATE_CONTAINER:-${AZURE_STATE_CONTAINER:-tfstate}}"

ENVIRONMENT="${ENVIRONMENT:-prod}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-azure}"
AZURE_KUBERNETES_TF_STATE_KEY="${AZURE_KUBERNETES_TF_STATE_KEY:-kubernetes.tfstate}"

if [ -z "${ARM_CLIENT_ID:-}" ] || [ -z "${ARM_CLIENT_SECRET:-}" ] || [ -z "${ARM_TENANT_ID:-}" ] || [ -z "${ARM_SUBSCRIPTION_ID:-}" ]; then
  echo "Error: Azure credentials not set. Set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, and ARM_SUBSCRIPTION_ID." >&2
  exit 1
fi

export ARM_CLIENT_ID
export ARM_CLIENT_SECRET
export ARM_TENANT_ID
export ARM_SUBSCRIPTION_ID

echo "=== [INFO] Destroying environment: $ENVIRONMENT ==="
echo "=== [INFO] Project namespace: $PROJECT_NAMESPACE ==="

export TF_VAR_client_id=$ARM_CLIENT_ID
export TF_VAR_client_secret=$ARM_CLIENT_SECRET
export TF_VAR_tenant_id=$ARM_TENANT_ID
export TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_cloud_provider=$CLOUD_PROVIDER
export TF_VAR_project_name=$PROJECT_NAMESPACE
export TF_VAR_environment=$ENVIRONMENT

if [[ -z "${AZURE_TF_STATE_STORAGE_ACCOUNT}" || "${AZURE_TF_STATE_STORAGE_ACCOUNT}" == "terraformmicrostate" ]]; then
  subscription_part=$(echo "${ARM_SUBSCRIPTION_ID}" | tr -d '-' | tr '[:upper:]' '[:lower:]' | cut -c1-12)
  environment_part=$(echo "${ENVIRONMENT}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-5)
  AZURE_TF_STATE_STORAGE_ACCOUNT="tfstate${subscription_part}${environment_part}"
fi

export TF_VAR_azure_remote_state_resource_group=$AZURE_TF_STATE_RESOURCE_GROUP
export TF_VAR_azure_remote_state_storage_account=$AZURE_TF_STATE_STORAGE_ACCOUNT
export TF_VAR_azure_remote_state_container=$AZURE_TF_STATE_CONTAINER

echo "=== [INFO] Initializing Terraform ==="
cp backends/azurerm.tf backend_override.tf
terraform init -reconfigure \
  -backend-config="resource_group_name=${AZURE_TF_STATE_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${AZURE_TF_STATE_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${AZURE_TF_STATE_CONTAINER}" \
  -backend-config="key=${AZURE_KUBERNETES_TF_STATE_KEY}"

echo "=== [INFO] Selecting workspace: $ENVIRONMENT ==="
terraform workspace select "$ENVIRONMENT"

echo "=== [INFO] Creating Terraform destroy plan ==="
terraform plan -destroy --var-file=./tfvars_files/$ENVIRONMENT.tfvars -out=tfplan

echo ""
echo "=== [CONFIRMATION] Review the destroy plan above. Destroy Azure Kubernetes bootstrap resources? (yes/no) ==="
read -r confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" == "yes" ]]; then
  echo "=== [INFO] Applying Terraform destroy plan ==="
  terraform apply -auto-approve tfplan
  rm -f tfplan
else
  echo "=== [INFO] Destruction cancelled by user ==="
  rm -f tfplan
  exit 0
fi

echo "=== [SUCCESS] Destruction completed successfully ==="
