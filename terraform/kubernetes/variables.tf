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

variable "argocd_deployment_repo_url" {
  description = "Git repository URL containing the deployment Helm charts consumed by ArgoCD"
  type        = string
  default     = "https://github.com/devdanielgherasim/micro-market-deployment.git"
}

variable "argocd_deployment_target_revision" {
  description = "Git target revision for the microservices ApplicationSet source (deployment repo)"
  type        = string
  default     = "HEAD"
}

variable "argocd_platform_repo_url" {
  description = "Git repository URL containing platform add-on GitOps source consumed by ArgoCD"
  type        = string
  default     = "https://github.com/devdanielgherasim/micro-market-platform-gitops.git"
}

variable "argocd_platform_target_revision" {
  description = "Git target revision for the platform-gitops root application"
  type        = string
  default     = "HEAD"
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

variable "external_secrets_role_arn" {
  description = "IAM role ARN used by External Secrets Operator controller service account"
  type        = string
  default     = ""
}

variable "cloudflare_api_token_secret_name" {
  description = "Kubernetes secret name containing the Cloudflare API token"
  type        = string
  default     = "cloudflare-api-token"
}

variable "lets_encrypt_email" {
  description = "Email used for Let's Encrypt account registration"
  type        = string
  default     = "admin@danielgherasim.com"
}
