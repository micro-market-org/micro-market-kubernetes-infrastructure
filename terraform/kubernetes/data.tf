locals {
  current_domain = (
    var.real_domain != null && var.real_domain != "" ? var.real_domain :
    var.cloud_provider == "azure" ? "${var.project_name}.${var.azure_region}.cloudapp.azure.com" :
    var.cloud_provider == "gcp" ? data.terraform_remote_state.gcp[0].outputs.cluster_endpoint :
    var.cloud_provider == "aws" ? data.terraform_remote_state.aws[0].outputs.eks_cluster_endpoint :
    null
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
    key    = var.aws_remote_state_key
    region = var.aws_remote_state_region
  }
}
