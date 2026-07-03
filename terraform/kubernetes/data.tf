locals {
  current_domain = (
    var.real_domain != null && var.real_domain != "" ? var.real_domain :
    var.cloud_provider == "azure" ? "${var.project_name}.${var.azure_region}.cloudapp.azure.com" :
    var.cloud_provider == "gcp" ? data.terraform_remote_state.gcp[0].outputs.cluster_endpoint :
    var.cloud_provider == "aws" ? data.terraform_remote_state.aws[0].outputs.eks_cluster_endpoint :
    null
  )

  auth_domain = var.auth_domain != "" ? var.auth_domain : "auth.${var.real_domain}"

  argocd_oidc_client_secret = (
    var.cloud_provider == "azure" ? try(data.terraform_remote_state.azure[0].outputs.argocd_oidc_client_secret, random_password.argo_oidc_client_secret.result) :
    var.cloud_provider == "gcp" ? try(data.terraform_remote_state.gcp[0].outputs.argocd_oidc_client_secret, random_password.argo_oidc_client_secret.result) :
    var.cloud_provider == "aws" ? try(data.terraform_remote_state.aws[0].outputs.argocd_oidc_client_secret, random_password.argo_oidc_client_secret.result) :
    random_password.argo_oidc_client_secret.result
  )

  aws_secret_prefix = (
    var.cloud_provider == "aws" ? try(data.terraform_remote_state.aws[0].outputs.secret_prefix, "${var.project_name}/${var.environment}") : "${var.project_name}/${var.environment}"
  )

  azure_key_vault_uri = (
    var.cloud_provider == "azure" ? try(data.terraform_remote_state.azure[0].outputs.key_vault_uri, "") : ""
  )

  azure_external_secrets_client_id = (
    var.cloud_provider == "azure" ? try(data.terraform_remote_state.azure[0].outputs.external_secrets_client_id, "") : ""
  )

  gcp_secret_prefix = (
    var.cloud_provider == "gcp" ? try(data.terraform_remote_state.gcp[0].outputs.secret_prefix, "${var.project_name}-${var.environment}") : "${var.project_name}-${var.environment}"
  )

  gcp_cluster_name = (
    var.cloud_provider == "gcp" ? try(data.terraform_remote_state.gcp[0].outputs.cluster_name, "") : ""
  )

  gcp_external_secrets_service_account = (
    var.cloud_provider == "gcp" ? try(data.terraform_remote_state.gcp[0].outputs.external_secrets_service_account_email, "") : ""
  )
}

data "terraform_remote_state" "azure" {
  count   = var.cloud_provider == "azure" ? 1 : 0
  backend = "azurerm"
  config = {
    resource_group_name  = var.azure_remote_state_resource_group
    storage_account_name = var.azure_remote_state_storage_account
    container_name       = var.azure_remote_state_container
    key                  = "terraform.tfstateenv:${var.environment}"
  }
}

data "terraform_remote_state" "gcp" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  backend = "gcs"
  config = {
    bucket = var.gcp_remote_state_bucket
    prefix = var.gcp_remote_state_prefix
  }
}

data "terraform_remote_state" "aws" {
  count   = var.cloud_provider == "aws" ? 1 : 0
  backend = "s3"
  config = {
    bucket = var.aws_remote_state_bucket
    # Must match the key the infrastructure repo's aws root writes to
    # (see infrastructure/terraform/aws/apply.sh: aws/<env>/terraform.tfstate).
    key    = var.aws_remote_state_key != "" ? var.aws_remote_state_key : "aws/${var.environment}/terraform.tfstate"
    region = var.aws_remote_state_region
  }
}
