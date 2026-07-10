#!/usr/bin/env bash

require_tfvars_file() {
  local environment="$1"
  local var_file="./tfvars_files/${environment}.tfvars"

  if [[ ! -f "${var_file}" ]]; then
    echo "ERROR: ${var_file} not found" >&2
    return 1
  fi

  printf '%s\n' "${var_file}"
}

terraform_init_backend() {
  local cloud_provider="$1"

  case "${cloud_provider}" in
    aws)
      : "${AWS_TF_STATE_BUCKET:?Set AWS_TF_STATE_BUCKET in .env or export it}"
      : "${STATE_KEY:?Set STATE_KEY before initializing the AWS backend}"
      cp backends/s3.tf backend_override.tf
      terraform init -reconfigure \
        -backend-config="backends/s3.hcl" \
        -backend-config="bucket=${AWS_TF_STATE_BUCKET}" \
        -backend-config="key=${STATE_KEY}"
      ;;
    azure)
      : "${AZURE_TF_STATE_RESOURCE_GROUP:?Set AZURE_TF_STATE_RESOURCE_GROUP before initializing the Azure backend}"
      : "${AZURE_TF_STATE_STORAGE_ACCOUNT:?Set AZURE_TF_STATE_STORAGE_ACCOUNT before initializing the Azure backend}"
      : "${AZURE_TF_STATE_CONTAINER:?Set AZURE_TF_STATE_CONTAINER before initializing the Azure backend}"
      : "${AZURE_KUBERNETES_TF_STATE_KEY:?Set AZURE_KUBERNETES_TF_STATE_KEY before initializing the Azure backend}"
      cp backends/azurerm.tf backend_override.tf
      terraform init -reconfigure \
        -backend-config="resource_group_name=${AZURE_TF_STATE_RESOURCE_GROUP}" \
        -backend-config="storage_account_name=${AZURE_TF_STATE_STORAGE_ACCOUNT}" \
        -backend-config="container_name=${AZURE_TF_STATE_CONTAINER}" \
        -backend-config="key=${AZURE_KUBERNETES_TF_STATE_KEY}"
      ;;
    gcp)
      cp backends/gcs.tf backend_override.tf
      terraform init -reconfigure -backend-config="backends/gcs.hcl"
      ;;
    *)
      echo "ERROR: Unsupported cloud provider: ${cloud_provider}" >&2
      return 1
      ;;
  esac
}

terraform_select_or_create_workspace() {
  local environment="$1"

  if ! terraform workspace list | grep -q "^[* ]*${environment}$"; then
    terraform workspace new "${environment}"
  else
    terraform workspace select "${environment}"
  fi
}
