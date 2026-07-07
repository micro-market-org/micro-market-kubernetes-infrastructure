variable "gcp_project" {
  type        = string
  description = "GCP project ID where the GKE cluster resides"
  default     = ""
}

variable "gcp_region" {
  type        = string
  description = "GCP region where resources are deployed"
  default     = "europe-central2"
}

variable "gcp_zone" {
  type        = string
  description = "GCP zone where the GKE cluster is deployed"
  default     = "europe-central2-a"
}

variable "gcp_credentials" {
  type        = string
  description = "Path to the GCP service-account credentials file (or use ADC)"
  sensitive   = true
  default     = ""
}

variable "remote_state_bucket" {
  description = "GCS bucket containing the infrastructure Terraform state"
  type        = string
  default     = "terraformmicroservicesstate"
}

variable "remote_state_prefix" {
  description = "GCS prefix for the infrastructure state"
  type        = string
  default     = "terraform/state"
}

variable "project_name" {
  type    = string
  default = "danielgherasim-microservices"
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "cluster_issuer" {
  type        = string
  description = "cert-manager ClusterIssuer to use for TLS certificates"
  default     = "letsencrypt-cloudflare-dns"
}

variable "real_domain" {
  description = "Public domain name for the platform"
  type        = string
  default     = "danielgherasim.com"
}

variable "auth_domain" {
  description = "Dedicated Keycloak hostname; defaults to auth.<real_domain>"
  type        = string
  default     = ""
}

variable "lets_encrypt_email" {
  description = "Email used for Let's Encrypt account registration"
  type        = string
  default     = "admin@danielgherasim.com"
}

variable "enable_keycloak_demo_users" {
  description = "Import demo Keycloak users (dev only)"
  type        = bool
  default     = false
}

variable "keycloak_log_level" {
  description = "Keycloak runtime log level"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["trace", "debug", "info", "warn", "error", "fatal"], var.keycloak_log_level)
    error_message = "keycloak_log_level must be one of: trace, debug, info, warn, error, fatal."
  }
}

variable "cloudflare_api_token" {
  description = "Scoped Cloudflare API token for DNS and DNS-01 validation"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_api_token_secret_name" {
  description = "Kubernetes secret name containing the Cloudflare API token"
  type        = string
  default     = "cloudflare-api-token"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for danielgherasim.com"
  type        = string
  default     = ""
}

variable "gitlab_token" {
  description = "GitLab personal access token for ArgoCD repo credentials"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_username" {
  description = "GitLab username for ArgoCD repo credentials"
  type        = string
  default     = ""
}

variable "argocd_deployment_repo_url" {
  type    = string
  default = "https://gitlab.com/microservices1691715/deployment.git"
}

variable "argocd_deployment_target_revision" {
  type    = string
  default = "HEAD"
}

variable "argocd_platform_repo_url" {
  type    = string
  default = "https://gitlab.com/microservices1691715/platform-gitops.git"
}

variable "argocd_platform_target_revision" {
  type    = string
  default = "HEAD"
}

variable "argocd_server_replicas" {
  type    = number
  default = 1
}

variable "argocd_server_resources_requests_memory" {
  type    = string
  default = "100Mi"
}

variable "argocd_server_resources_requests_cpu" {
  type    = string
  default = "80m"
}

variable "argocd_controller_replicas" {
  type    = number
  default = 1
}

variable "argocd_controller_resources_requests_memory" {
  type    = string
  default = "100Mi"
}

variable "argocd_controller_resources_requests_cpu" {
  type    = string
  default = "80m"
}

variable "argocd_repo_server_replicas" {
  type    = number
  default = 1
}

variable "argocd_repo_server_resources_requests_memory" {
  type    = string
  default = "50Mi"
}

variable "argocd_repo_server_resources_requests_cpu" {
  type    = string
  default = "40m"
}

variable "argocd_application_set_replicas" {
  type    = number
  default = 1
}

variable "argocd_application_set_resources_requests_memory" {
  type    = string
  default = "50Mi"
}

variable "argocd_application_set_resources_requests_cpu" {
  type    = string
  default = "40m"
}

variable "argocd_notifications_resources_requests_memory" {
  type    = string
  default = "50Mi"
}

variable "argocd_notifications_resources_requests_cpu" {
  type    = string
  default = "40m"
}

variable "argocd_redis_resources_requests_memory" {
  type    = string
  default = "50Mi"
}

variable "argocd_redis_resources_requests_cpu" {
  type    = string
  default = "40m"
}
