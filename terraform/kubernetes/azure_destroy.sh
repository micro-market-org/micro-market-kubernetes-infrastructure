#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-prod}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-azure}"
BACKEND_TYPE="azurerm"
# ACR names are alphanumeric only — mirror infrastructure's replace(project_name, "-", "")
CONTAINER_REGISTRY_NAME="${CONTAINER_REGISTRY_NAME:-acr$(tr -d '-' <<<"${PROJECT_NAMESPACE}")${ENVIRONMENT}.azurecr.io}"

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

echo "=== [INFO] Deleting Kubernetes resources ==="
kubectl delete -f ./configs/argocd_application.yaml || true
kubectl delete -f ./configs/argocd_network_policies.yaml || true
kubectl delete -f ./configs/argocd_project.yaml || true
kubectl delete -f ./configs/prometheus_recording_rules.yaml || true
kubectl delete -f ./configs/prometheus_alerting_rules.yaml || true

echo "=== [INFO] Destroying Terraform resources ==="
terraform destroy --var-file=./tfvars_files/$ENVIRONMENT.tfvars -auto-approve

echo "=== [SUCCESS] Destruction completed successfully ==="
