variable "cloud_provider" {
  type        = string
  description = "The cloud provider to use (azure, gcp, or aws)"
  validation {
    condition     = contains(["azure", "gcp", "aws"], var.cloud_provider)
    error_message = "The cloud_provider value must be 'azure', 'gcp', or 'aws'."
  }
}

variable "azure_remote_state_resource_group" {
  description = "Azure resource group name for remote state"
  type        = string
  default     = "rg-infrastructure"
}

variable "azure_remote_state_storage_account" {
  description = "Azure storage account name for remote state"
  type        = string
  default     = "terraformmicrostate"
}

variable "azure_remote_state_container" {
  description = "Azure storage container name for remote state"
  type        = string
  default     = "tfstate"
}

variable "gcp_remote_state_bucket" {
  description = "GCP bucket name for remote state"
  type        = string
  default     = "terraformmicroservicesstate"
}

variable "gcp_remote_state_prefix" {
  description = "GCP prefix for remote state"
  type        = string
  default     = "terraform/state"
}

variable "aws_remote_state_bucket" {
  description = "AWS bucket name for remote state"
  type        = string
  default     = ""
}

variable "aws_remote_state_key" {
  description = "AWS key for remote state; empty derives aws/<environment>/terraform.tfstate to match the infrastructure repo"
  type        = string
  default     = ""
}

variable "aws_remote_state_region" {
  description = "AWS region for remote state"
  type        = string
  default     = "eu-central-1"
}

variable "client_id" {
  type        = string
  description = "The Azure AD Application ID (Client ID) for authentication"
  sensitive   = true
  default     = ""
}
variable "client_secret" {
  type        = string
  description = "The Azure AD Application Secret (Client Secret) for authentication"
  sensitive   = true
  default     = ""
}
variable "tenant_id" {
  type        = string
  description = "The Azure AD Tenant ID for authentication"
  sensitive   = true
  default     = ""
}
variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID where resources will be deployed"
  sensitive   = true
  default     = ""
}
variable "gcp_project" {
  type        = string
  description = "The Google Cloud project ID"
  default     = ""
}
variable "gcp_region" {
  type        = string
  description = "The Google Cloud region where resources will be deployed"
  default     = "europe-central2"
}
variable "gcp_zone" {
  type        = string
  description = "The Google Cloud zone where resources will be deployed"
  default     = "europe-central2-a"
}
variable "gcp_credentials" {
  type        = string
  description = "The path to the Google Cloud credentials file"
  default     = ""
  sensitive   = true
}
variable "project_name" {
  type    = string
  default = "danielgherasim-microservices"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "cluster_issuer" {
  type        = string
  description = "The cert-manager ClusterIssuer to use for certificate issuance"
  default     = "letsencrypt-cloudflare-dns"
}

variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be deployed"
  default     = "eu-central-1"
}

variable "azure_region" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "westeurope"
}

variable "kubernetes_host" {
  description = "Kubernetes host"
  type        = string
  default     = null
}

variable "kubernetes_client_certificate" {
  description = "Kubernetes client certificate"
  type        = string
  sensitive   = true
  default     = null
}

variable "kubernetes_client_key" {
  description = "Kubernetes client key"
  type        = string
  sensitive   = true
  default     = null
}

variable "kubernetes_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_token" {
  description = "GitLab personal access token for ArgoCD"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_username" {
  description = "GitLab username for ArgoCD"
  type        = string
  default     = ""
}

variable "argocd_deployment_repo_url" {
  description = "Git repository URL containing the deployment Helm charts consumed by ArgoCD"
  type        = string
  default     = "https://gitlab.com/microservices1691715/deployment.git"
}

variable "argocd_deployment_target_revision" {
  description = "Git target revision for the microservices ApplicationSet source (deployment repo)"
  type        = string
  default     = "HEAD"
}

variable "argocd_platform_repo_url" {
  description = "Git repository URL containing platform add-on GitOps source consumed by ArgoCD"
  type        = string
  default     = "https://gitlab.com/microservices1691715/platform-gitops.git"
}

variable "argocd_platform_target_revision" {
  description = "Git target revision for the platform-gitops root application"
  type        = string
  default     = "HEAD"
}

variable "container_registry" {
  description = "Container registry host for non-AWS image repositories. AWS uses ECR repository URLs from remote state when available."
  type        = string
  default     = ""
}

variable "container_image_namespace" {
  description = "Image namespace/project path used with container_registry for non-AWS providers"
  type        = string
  default     = ""
}

variable "database" {
  description = "Postgres database"
  type        = string
  default     = "microservices"
}


variable "argocd_server_replicas" {
  description = "Number of ArgoCD server replicas"
  type        = number
  default     = 1
}

variable "argocd_server_resources_requests_memory" {
  description = "Memory requests for ArgoCD server"
  type        = string
  default     = "100Mi"
}

variable "argocd_server_resources_requests_cpu" {
  description = "CPU requests for ArgoCD server"
  type        = string
  default     = "80m"
}

variable "argocd_controller_replicas" {
  description = "Number of ArgoCD controller replicas"
  type        = number
  default     = 1
}

variable "argocd_controller_resources_requests_memory" {
  description = "Memory requests for ArgoCD controller"
  type        = string
  default     = "100Mi"
}

variable "argocd_controller_resources_requests_cpu" {
  description = "CPU requests for ArgoCD controller"
  type        = string
  default     = "80m"
}

variable "argocd_repo_server_replicas" {
  description = "Number of ArgoCD repo server replicas"
  type        = number
  default     = 1
}

variable "argocd_repo_server_resources_requests_memory" {
  description = "Memory requests for ArgoCD repo server"
  type        = string
  default     = "50Mi"
}

variable "argocd_repo_server_resources_requests_cpu" {
  description = "CPU requests for ArgoCD repo server"
  type        = string
  default     = "40m"
}

variable "argocd_application_set_replicas" {
  description = "Number of ArgoCD application set replicas"
  type        = number
  default     = 1
}

variable "argocd_application_set_resources_requests_memory" {
  description = "Memory requests for ArgoCD application set"
  type        = string
  default     = "50Mi"
}

variable "argocd_application_set_resources_requests_cpu" {
  description = "CPU requests for ArgoCD application set"
  type        = string
  default     = "40m"
}

variable "argocd_notifications_resources_requests_memory" {
  description = "Memory requests for ArgoCD notifications"
  type        = string
  default     = "50Mi"
}

variable "argocd_notifications_resources_requests_cpu" {
  description = "CPU requests for ArgoCD notifications"
  type        = string
  default     = "40m"
}

variable "argocd_redis_resources_requests_memory" {
  description = "Memory requests for ArgoCD Redis"
  type        = string
  default     = "50Mi"
}

variable "argocd_redis_resources_requests_cpu" {
  description = "CPU requests for ArgoCD Redis"
  type        = string
  default     = "40m"
}

variable "real_domain" {
  description = "The real domain to use for the cluster"
  type        = string
  default     = "danielgherasim.com"
}

variable "auth_domain" {
  description = "Dedicated Keycloak hostname. Defaults to auth.<real_domain> so dev/staging app hostnames can share one IdP hostname."
  type        = string
  default     = ""
}

variable "enable_aws_platform_addons" {
  description = "Install AWS-specific Kubernetes platform add-ons when cloud_provider is aws"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller service account"
  type        = string
  default     = ""
}

variable "external_dns_role_arn" {
  description = "IAM role ARN used by ExternalDNS service account"
  type        = string
  default     = ""
}

variable "external_secrets_role_arn" {
  description = "IAM role ARN used by External Secrets Operator controller service account"
  type        = string
  default     = ""
}

variable "cloudflare_api_token" {
  description = "Scoped Cloudflare API token for DNS record automation and DNS-01 validation"
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

variable "lets_encrypt_email" {
  description = "Email used for Let's Encrypt account registration"
  type        = string
  default     = "admin@danielgherasim.com"
}

variable "enable_keycloak_demo_users" {
  description = "Import demo Keycloak users. Keep disabled outside development."
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
