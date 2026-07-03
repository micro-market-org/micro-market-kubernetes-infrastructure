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

  backend "azurerm" {

  }
}

provider "azurerm" {
  features {}

  client_id       = local.azure_client_id
  client_secret   = local.azure_client_secret
  tenant_id       = local.azure_tenant_id
  subscription_id = local.azure_subscription_id
}

provider "google" {
  project     = local.google_project
  region      = local.google_region
  zone        = local.google_zone
  credentials = local.google_credentials
}

provider "aws" {
  region     = local.aws_provider_region
  access_key = local.aws_provider_access_key
  secret_key = local.aws_provider_secret_key
  token      = local.aws_provider_token
}

locals {
  azure_client_id       = var.cloud_provider == "azure" ? var.client_id : null
  azure_client_secret   = var.cloud_provider == "azure" ? var.client_secret : null
  azure_tenant_id       = var.cloud_provider == "azure" ? var.tenant_id : null
  azure_subscription_id = var.cloud_provider == "azure" ? var.subscription_id : null

  google_project     = var.cloud_provider == "gcp" ? var.gcp_project : null
  google_region      = var.cloud_provider == "gcp" ? var.gcp_region : null
  google_zone        = var.cloud_provider == "gcp" ? var.gcp_zone : null
  google_credentials = var.cloud_provider == "gcp" ? var.gcp_credentials : null

  aws_provider_region     = var.cloud_provider == "aws" ? var.aws_region : null
  aws_provider_access_key = var.cloud_provider == "aws" ? var.aws_access_key : null
  aws_provider_secret_key = var.cloud_provider == "aws" ? var.aws_secret_key : null
  aws_provider_token      = var.cloud_provider == "aws" ? var.aws_session_token : null

  use_gcp_auth         = var.cloud_provider == "gcp"
  use_aws_auth         = var.cloud_provider == "aws"
  aws_eks_cluster_name = var.cloud_provider == "aws" ? data.terraform_remote_state.aws[0].outputs.eks_cluster_name : null

  kubernetes_host = (
    var.cloud_provider == "azure" ? data.terraform_remote_state.azure[0].outputs.kubernetes_host : var.cloud_provider == "gcp" ? data.terraform_remote_state.gcp[0].outputs.kubernetes_host : var.cloud_provider == "aws" ? data.terraform_remote_state.aws[0].outputs.eks_cluster_endpoint : null
  )

  kubernetes_client_certificate = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_certificate) : null
  kubernetes_client_key         = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_key) : null

  kubernetes_cluster_ca_certificate = (
    var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_cluster_ca_certificate) : var.cloud_provider == "gcp" ? base64decode(data.terraform_remote_state.gcp[0].outputs.kubernetes_cluster_ca_certificate) : var.cloud_provider == "aws" ? base64decode(data.terraform_remote_state.aws[0].outputs.eks_cluster_certificate_authority_data) : null
  )

  kubernetes_config = {
    host                   = local.kubernetes_host
    client_certificate     = local.kubernetes_client_certificate
    client_key             = local.kubernetes_client_key
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_config.host
  client_certificate     = local.kubernetes_config.client_certificate
  client_key             = local.kubernetes_config.client_key
  cluster_ca_certificate = local.kubernetes_config.cluster_ca_certificate

  dynamic "exec" {
    for_each = local.use_gcp_auth ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }

  dynamic "exec" {
    for_each = local.use_aws_auth ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.aws_eks_cluster_name]
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
      for_each = local.use_gcp_auth ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "gke-gcloud-auth-plugin"
      }
    }

    dynamic "exec" {
      for_each = local.use_aws_auth ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", local.aws_eks_cluster_name]
      }
    }
  }
}
