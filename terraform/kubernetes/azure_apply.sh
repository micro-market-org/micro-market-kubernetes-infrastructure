#!/bin/bash

ENVIRONMENT="${ENVIRONMENT:-prod}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
DOMAIN="${DOMAIN:-danielgherasim.com}"
CLOUD_PROVIDER="${CLOUD_PROVIDER:-azure}"
BACKEND_TYPE="azurerm"
CONTAINER_REGISTRY_NAME="${CONTAINER_REGISTRY_NAME:-acr${PROJECT_NAMESPACE}${ENVIRONMENT}.azurecr.io}"


if [ -z "${ARM_CLIENT_ID:-}" ] || [ -z "${ARM_CLIENT_SECRET:-}" ] || [ -z "${ARM_TENANT_ID:-}" ] || [ -z "${ARM_SUBSCRIPTION_ID:-}" ]; then
  echo "Error: Azure credentials not set. Set ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, and ARM_SUBSCRIPTION_ID." >&2
  exit 1
fi

if [ -z "${GITLAB_ACCESS_TOKEN:-}" ] || [ -z "${GITLAB_USERNAME:-}" ]; then
  echo "Error: GitLab credentials not set. Set GITLAB_ACCESS_TOKEN and GITLAB_USERNAME." >&2
  exit 1
fi

echo "=== [INFO] Deploying to environment: $ENVIRONMENT ==="
echo "=== [INFO] Project namespace: $PROJECT_NAMESPACE ==="

export TF_VAR_client_id=$ARM_CLIENT_ID
export TF_VAR_client_secret=$ARM_CLIENT_SECRET
export TF_VAR_tenant_id=$ARM_TENANT_ID
export TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_cloud_provider=$CLOUD_PROVIDER
export TF_VAR_project_name=$PROJECT_NAMESPACE
export TF_VAR_environment=$ENVIRONMENT

sed -i "s/BACKEND_PLACEHOLDER/${BACKEND_TYPE}/g" main.tf

echo "=== [INFO] Initializing Terraform ==="
terraform init -migrate-state \
  -backend-config="resource_group_name=rg-infrastructure" \
  -backend-config="storage_account_name=terraformmicrostate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=kubernetes.tfstate"

echo "=== [INFO] Selecting workspace: $ENVIRONMENT ==="
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

echo "=== [INFO] Creating Terraform plan ==="
terraform plan --var-file=./tfvars_files/$ENVIRONMENT.tfvars -var project_name="$PROJECT_NAMESPACE" -var gitlab_token="$GITLAB_ACCESS_TOKEN" -var gitlab_username="$GITLAB_USERNAME" -out=tfplan

echo ""
echo "=== [CONFIRMATION] Do you want to apply these changes? (yes/no) ==="
read -r confirmation

confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" == "yes" ]]; then
  echo "=== [INFO] Applying Terraform plan ==="
  terraform apply -auto-approve tfplan

  echo "=== [INFO] Applying Kubernetes configurations ==="
  kubectl apply -f ./configs/production_issuer.yaml
  kubectl apply -f ./configs/argocd_network_policies.yaml
  kubectl apply -f ./configs/prometheus_recording_rules.yaml
  kubectl apply -f ./configs/prometheus_alerting_rules.yaml
  kubectl apply -f ./configs/argocd_project.yaml

  echo "=== [INFO] Creating ArgoCD application configuration ==="
  cat ./configs/argocd_application.yaml.template | \
    sed "s/\${ENV}/$ENVIRONMENT/g" | \
    sed "s/\${REGISTRY}/$CONTAINER_REGISTRY_NAME/g" | \
    sed "s/\${PROJECT_NAME}/$PROJECT_NAMESPACE/g" | \
    sed "s/\${DOMAIN}/$DOMAIN/g" | \
    sed "s/\${PROVIDER}/$CLOUD_PROVIDER/g" > ./configs/argocd_application.yaml

  kubectl apply -f ./configs/argocd_application.yaml

  echo "=== [INFO] Updating public IP DNS name ==="
  PUBLIC_IP_NAME=$(az network public-ip list --resource-group rg-$PROJECT_NAMESPACE-$ENVIRONMENT-aks --query "[?contains(name, 'kubernetes-')].name" -o tsv)
  az network public-ip update --resource-group rg-$PROJECT_NAMESPACE-$ENVIRONMENT-aks --name $PUBLIC_IP_NAME --dns-name $PROJECT_NAMESPACE

  echo "=== [SUCCESS] Deployment completed successfully ==="
else
  echo "=== [INFO] Deployment cancelled by user ==="
  exit 0
fi
