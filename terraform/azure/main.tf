terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }

  # Config is passed at init time via -backend-config (see apply.sh).
  # Credentials come from ARM_* environment variables.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

locals {
  kubernetes_host                   = data.terraform_remote_state.infra.outputs.kubernetes_host
  kubernetes_client_certificate     = base64decode(data.terraform_remote_state.infra.outputs.kubernetes_client_certificate)
  kubernetes_client_key             = base64decode(data.terraform_remote_state.infra.outputs.kubernetes_client_key)
  kubernetes_cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.kubernetes_cluster_ca_certificate)
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  client_certificate     = local.kubernetes_client_certificate
  client_key             = local.kubernetes_client_key
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}
