terraform {
  # required_version = "=1.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.30.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "=5.10.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "=5.40.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "=2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=2.37.1"
    }
  }

  backend "BACKEND_PLACEHOLDER" {

  }
}

provider "azurerm" {
  features {}

  client_id       = var.cloud_provider == "azure" ? var.client_id : null
  client_secret   = var.cloud_provider == "azure" ? var.client_secret : null
  tenant_id       = var.cloud_provider == "azure" ? var.tenant_id : null
  subscription_id = var.cloud_provider == "azure" ? var.subscription_id : null
}

provider "google" {
  project     = var.cloud_provider == "gcp" ? var.gcp_project : null
  region      = var.cloud_provider == "gcp" ? var.gcp_region : null
  zone        = var.cloud_provider == "gcp" ? var.gcp_zone : null
  credentials = var.cloud_provider == "gcp" ? var.gcp_credentials : null
}

provider "aws" {
  region     = var.cloud_provider == "aws" ? var.aws_region : null
  access_key = var.cloud_provider == "aws" ? var.aws_access_key : null
  secret_key = var.cloud_provider == "aws" ? var.aws_secret_key : null
  token      = var.cloud_provider == "aws" ? var.aws_session_token : null
}

locals {
  kubernetes_config = {
    host = (
      var.cloud_provider == "azure" ? data.terraform_remote_state.azure[0].outputs.kubernetes_host : var.cloud_provider == "gcp" ? data.terraform_remote_state.gcp[0].outputs.kubernetes_host : var.cloud_provider == "aws" ? data.terraform_remote_state.aws[0].outputs.eks_cluster_endpoint : null
    )

    client_certificate = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_certificate) : null
    client_key         = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_key) : null

    cluster_ca_certificate = (
      var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_cluster_ca_certificate) : var.cloud_provider == "gcp" ? base64decode(data.terraform_remote_state.gcp[0].outputs.kubernetes_cluster_ca_certificate) : var.cloud_provider == "aws" ? base64decode(data.terraform_remote_state.aws[0].outputs.eks_cluster_certificate_authority_data) : null
    )
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_config.host
  client_certificate     = local.kubernetes_config.client_certificate
  client_key             = local.kubernetes_config.client_key
  cluster_ca_certificate = local.kubernetes_config.cluster_ca_certificate

  dynamic "exec" {
    for_each = var.cloud_provider == "gcp" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }

  dynamic "exec" {
    for_each = var.cloud_provider == "aws" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.aws[0].outputs.eks_cluster_name]
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_config.host
    client_certificate     = local.kubernetes_config.client_certificate
    client_key             = local.kubernetes_config.client_key
    cluster_ca_certificate = local.kubernetes_config.cluster_ca_certificate

    dynamic "exec" {
      for_each = var.cloud_provider == "gcp" ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "gke-gcloud-auth-plugin"
      }
    }

    dynamic "exec" {
      for_each = var.cloud_provider == "aws" ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.aws[0].outputs.eks_cluster_name]
      }
    }
  }
}
