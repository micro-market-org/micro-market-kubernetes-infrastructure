terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

locals {
  kubernetes_host                   = data.terraform_remote_state.infra.outputs.eks_cluster_endpoint
  kubernetes_cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.eks_cluster_certificate_authority_data)
  eks_cluster_name                  = data.terraform_remote_state.infra.outputs.eks_cluster_name
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.eks_cluster_name, "--region", var.aws_region]
    }
  }
}
