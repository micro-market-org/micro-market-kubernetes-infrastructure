terraform {
  required_version = ">= 1.10.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
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
  # Credentials come from GOOGLE_APPLICATION_CREDENTIALS.
  backend "gcs" {}
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
  credentials = var.gcp_credentials
}

locals {
  kubernetes_host                   = data.terraform_remote_state.infra.outputs.kubernetes_host
  kubernetes_cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.kubernetes_cluster_ca_certificate)
}

provider "kubernetes" {
  host                   = local.kubernetes_host
  cluster_ca_certificate = local.kubernetes_cluster_ca_certificate

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes_host
    cluster_ca_certificate = local.kubernetes_cluster_ca_certificate

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}
