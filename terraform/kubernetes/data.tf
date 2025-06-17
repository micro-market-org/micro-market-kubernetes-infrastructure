locals {
  current_domain = (
    var.cloud_provider == "azure" ? "${var.project_name}.westeurope.cloudapp.azure.com" :
    var.cloud_provider == "gcp" ? data.terraform_remote_state.gcp[0].outputs.cluster_endpoint :
    var.cloud_provider == "aws" ? data.terraform_remote_state.aws[0].outputs.eks_cluster_endpoint :
    null
  )
}

data "terraform_remote_state" "azure" {
  count   = var.cloud_provider == "azure" ? 1 : 0
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-infrastructure"
    storage_account_name = "terraformmicrostate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

data "terraform_remote_state" "gcp" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  backend = "gcs"
  config = {
    bucket = "terraformmicroservicesstate"
    prefix = "terraform/state"
  }
}

data "terraform_remote_state" "aws" {
  count   = var.cloud_provider == "aws" ? 1 : 0
  backend = "s3"
  config = {
    bucket = "terraform-microservices1691715-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
