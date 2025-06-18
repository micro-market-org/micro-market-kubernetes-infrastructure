#!/bin/bash

set -e

ENVIRONMENT="prod"
PROJECT_NAMESPACE="microservices1691719"
CLOUD_PROVIDER="azure"
BACKEND_TYPE="azurerm"
CONTAINER_REGISTRY_NAME=""
GITLAB_ACCESS_TOKEN=""
GITLAB_USERNAME="adriangherasim1@gmail.com"
ARM_CLIENT_ID=""
ARM_CLIENT_SECRET=""
ARM_TENANT_ID=""
ARM_SUBSCRIPTION_ID=""


# Check if required environment variables are set
if [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_TENANT_ID" ] || [ -z "$ARM_SUBSCRIPTION_ID" ]; then
  echo "Error: Azure credentials not set. Please set the following environment variables:"
  echo "  ARM_CLIENT_ID"
  echo "  ARM_CLIENT_SECRET"
  echo "  ARM_TENANT_ID"
  echo "  ARM_SUBSCRIPTION_ID"
  exit 1
fi

echo "=== [INFO] Destroying environment: $ENVIRONMENT ==="
echo "=== [INFO] Project namespace: $PROJECT_NAMESPACE ==="

# Export Terraform variables
export TF_VAR_client_id=$ARM_CLIENT_ID
export TF_VAR_client_secret=$ARM_CLIENT_SECRET
export TF_VAR_tenant_id=$ARM_TENANT_ID
export TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_cloud_provider=$CLOUD_PROVIDER
export TF_VAR_project_name=$PROJECT_NAMESPACE
export TF_VAR_environment=$ENVIRONMENT

# Replace backend placeholder in main.tf
sed -i "s/BACKEND_PLACEHOLDER/${BACKEND_TYPE}/g" main.tf

# Initialize Terraform
echo "=== [INFO] Initializing Terraform ==="
terraform init -migrate-state \
  -backend-config="resource_group_name=rg-infrastructure" \
  -backend-config="storage_account_name=terraformmicrostate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=kubernetes.tfstate"

# Select workspace
echo "=== [INFO] Selecting workspace: $ENVIRONMENT ==="
terraform workspace select "$ENVIRONMENT"

# Delete Kubernetes resources
echo "=== [INFO] Deleting Kubernetes resources ==="
kubectl delete -f ./configs/argocd_application.yaml || true
kubectl delete -f ./configs/argocd_network_policies.yaml || true
kubectl delete -f ./configs/argocd_project.yaml || true
kubectl delete -f ./configs/prometheus_recording_rules.yaml || true
kubectl delete -f ./configs/prometheus_alerting_rules.yaml || true

# Destroy Terraform resources
echo "=== [INFO] Destroying Terraform resources ==="
terraform destroy --var-file=./tfvars_files/$ENVIRONMENT.tfvars -auto-approve

echo "=== [SUCCESS] Destruction completed successfully ==="

