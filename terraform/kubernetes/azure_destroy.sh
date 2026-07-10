#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=terraform/kubernetes/scripts/_common.sh
source "${SCRIPT_DIR}/scripts/_common.sh"
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

ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-azure}"
AZURE_KUBERNETES_TF_STATE_KEY="${AZURE_KUBERNETES_TF_STATE_KEY:-kubernetes.tfstate}"
VAR_FILE="$(require_tfvars_file "${ENVIRONMENT}")"

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
terraform_init_backend "azure"

echo "=== [INFO] Selecting workspace: $ENVIRONMENT ==="
terraform_select_or_create_workspace "${ENVIRONMENT}"

echo "=== [INFO] Creating Terraform destroy plan ==="
terraform plan -destroy --var-file="${VAR_FILE}" -out=tfplan.destroy

echo ""
echo "=== [CONFIRMATION] Review the destroy plan above. Destroy Azure Kubernetes bootstrap resources? (yes/no) ==="
read -r confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" == "yes" ]]; then
  if [[ "${ARGOCD_CASCADE_SKIP:-false}" != "true" ]]; then
    echo "=== [INFO] Fetching AKS credentials for ArgoCD cascade cleanup ==="
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" >/dev/null
    az account set --subscription "$ARM_SUBSCRIPTION_ID"

    AKS_RESOURCE_GROUP="${AKS_RESOURCE_GROUP:-rg-${PROJECT_NAMESPACE}-${ENVIRONMENT}}"
    AKS_CLUSTER_NAME="${AKS_CLUSTER_NAME:-k8s-${PROJECT_NAMESPACE}-${ENVIRONMENT}}"
    az aks get-credentials --resource-group "$AKS_RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --overwrite-existing

    echo "=== [INFO] Cascade-deleting ArgoCD Applications before destroy ==="
    bash ./destroy_argocd_apps.sh
  else
    echo "=== [WARN] ARGOCD_CASCADE_SKIP=true — skipping ArgoCD cascade cleanup; namespace may get stuck in Terminating and DNS records may orphan (see ADR-10). ===" >&2
  fi

  echo "=== [INFO] Applying Terraform destroy plan ==="
  terraform apply -auto-approve tfplan.destroy
  rm -f tfplan.destroy
else
  echo "=== [INFO] Destruction cancelled by user ==="
  rm -f tfplan.destroy
  exit 0
fi

echo "=== [SUCCESS] Destruction completed successfully ==="
