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
  default     = "terraform-microservices1691715-state"
}

variable "aws_remote_state_key" {
  description = "AWS key for remote state"
  type        = string
  default     = "terraform.tfstate"
}

variable "aws_remote_state_region" {
  description = "AWS region for remote state"
  type        = string
  default     = "us-east-1"
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
  default     = "us-east-1"
}

variable "aws_access_key" {
  type        = string
  description = "The AWS access key for authentication"
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  type        = string
  description = "The AWS secret key for authentication"
  sensitive   = true
  default     = ""
}

variable "aws_session_token" {
  description = "AWS session token for temporary credentials"
  type        = string
  sensitive   = true
  default     = ""
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

variable "gitops_applications" {
  description = "Applications managed by the ArgoCD ApplicationSet"
  type = list(object({
    name = string
    path = string
  }))
  default = [
    {
      name = "catalog"
      path = "catalog"
    },
    {
      name = "audit"
      path = "audit"
    },
    {
      name = "orders"
      path = "orders"
    },
    {
      name = "micro-market-frontend"
      path = "micro-market-frontend"
    }
  ]
}

variable "database" {
  description = "Postgres database"
  type        = string
  default     = "microservices"
}

variable "cert_manager_replicas" {
  description = "Number of cert-manager replicas"
  type        = number
  default     = 1
}

variable "cert_manager_webhook_replicas" {
  description = "Number of cert-manager webhook replicas"
  type        = number
  default     = 1
}

variable "cert_manager_cainjector_replicas" {
  description = "Number of cert-manager cainjector replicas"
  type        = number
  default     = 1
}

variable "cert_manager_resources_requests_cpu" {
  description = "CPU requests for cert-manager"
  type        = string
  default     = "80m"
}

variable "cert_manager_resources_requests_memory" {
  description = "Memory requests for cert-manager"
  type        = string
  default     = "100Mi"
}

variable "cert_manager_resources_limits_cpu" {
  description = "CPU limits for cert-manager"
  type        = string
  default     = "160m"
}

variable "cert_manager_resources_limits_memory" {
  description = "Memory limits for cert-manager"
  type        = string
  default     = "200Mi"
}

variable "cert_manager_webhook_resources_requests_cpu" {
  description = "CPU requests for cert-manager webhook"
  type        = string
  default     = "40m"
}

variable "cert_manager_webhook_resources_requests_memory" {
  description = "Memory requests for cert-manager webhook"
  type        = string
  default     = "50Mi"
}

variable "cert_manager_webhook_resources_limits_cpu" {
  description = "CPU limits for cert-manager webhook"
  type        = string
  default     = "80m"
}

variable "cert_manager_webhook_resources_limits_memory" {
  description = "Memory limits for cert-manager webhook"
  type        = string
  default     = "100Mi"
}

variable "cert_manager_cainjector_resources_requests_cpu" {
  description = "CPU requests for cert-manager cainjector"
  type        = string
  default     = "40m"
}

variable "cert_manager_cainjector_resources_requests_memory" {
  description = "Memory requests for cert-manager cainjector"
  type        = string
  default     = "50Mi"
}

variable "cert_manager_cainjector_resources_limits_cpu" {
  description = "CPU limits for cert-manager cainjector"
  type        = string
  default     = "80m"
}

variable "cert_manager_cainjector_resources_limits_memory" {
  description = "Memory limits for cert-manager cainjector"
  type        = string
  default     = "100Mi"
}

variable "nginx_ingress_replicas" {
  description = "Number of NGINX Ingress replicas"
  type        = number
  default     = 1
}

variable "nginx_ingress_autoscaling_enabled" {
  description = "Enable autoscaling for NGINX Ingress"
  type        = bool
  default     = false
}

variable "nginx_ingress_min_replicas" {
  description = "Minimum number of NGINX Ingress replicas for autoscaling"
  type        = number
  default     = 1
}

variable "nginx_ingress_max_replicas" {
  description = "Maximum number of NGINX Ingress replicas for autoscaling"
  type        = number
  default     = 3
}

variable "nginx_ingress_resources_requests_cpu" {
  description = "CPU requests for NGINX Ingress"
  type        = string
  default     = "150m"
}

variable "nginx_ingress_resources_requests_memory" {
  description = "Memory requests for NGINX Ingress"
  type        = string
  default     = "200Mi"
}

variable "nginx_ingress_resources_limits_cpu" {
  description = "CPU limits for NGINX Ingress"
  type        = string
  default     = "400m"
}

variable "nginx_ingress_resources_limits_memory" {
  description = "Memory limits for NGINX Ingress"
  type        = string
  default     = "400Mi"
}

variable "postgresql_architecture" {
  description = "PostgreSQL architecture (standalone or replication)"
  type        = string
  default     = "standalone"
}

variable "postgresql_primary_storage_size" {
  description = "Storage size for PostgreSQL primary"
  type        = string
  default     = "10Gi"
}

variable "postgresql_primary_resources_requests_memory" {
  description = "Memory requests for PostgreSQL primary"
  type        = string
  default     = "200Mi"
}

variable "postgresql_primary_resources_requests_cpu" {
  description = "CPU requests for PostgreSQL primary"
  type        = string
  default     = "200m"
}

variable "postgresql_primary_resources_limits_memory" {
  description = "Memory limits for PostgreSQL primary"
  type        = string
  default     = "800Mi"
}

variable "postgresql_primary_resources_limits_cpu" {
  description = "CPU limits for PostgreSQL primary"
  type        = string
  default     = "800m"
}

variable "postgresql_max_connections" {
  description = "PostgreSQL max connections"
  type        = string
  default     = "50"
}

variable "postgresql_shared_buffers" {
  description = "PostgreSQL shared buffers"
  type        = string
  default     = "64MB"
}

variable "postgresql_read_replicas_count" {
  description = "Number of PostgreSQL read replicas"
  type        = string
  default     = "0"
}

variable "postgresql_read_replicas_storage_size" {
  description = "Storage size for PostgreSQL read replicas"
  type        = string
  default     = "10Gi"
}

variable "postgresql_read_replicas_resources_requests_memory" {
  description = "Memory requests for PostgreSQL read replicas"
  type        = string
  default     = "200Mi"
}

variable "postgresql_read_replicas_resources_requests_cpu" {
  description = "CPU requests for PostgreSQL read replicas"
  type        = string
  default     = "200m"
}

variable "postgresql_read_replicas_resources_limits_memory" {
  description = "Memory limits for PostgreSQL read replicas"
  type        = string
  default     = "800Mi"
}

variable "postgresql_read_replicas_resources_limits_cpu" {
  description = "CPU limits for PostgreSQL read replicas"
  type        = string
  default     = "400m"
}

variable "prometheus_replicas" {
  description = "Number of Prometheus replicas"
  type        = number
  default     = 1
}

variable "prometheus_resources_requests_memory" {
  description = "Memory requests for Prometheus"
  type        = string
  default     = "400Mi"
}

variable "prometheus_resources_requests_cpu" {
  description = "CPU requests for Prometheus"
  type        = string
  default     = "150m"
}

variable "prometheus_resources_limits_memory" {
  description = "Memory limits for Prometheus"
  type        = string
  default     = "800Mi"
}

variable "prometheus_resources_limits_cpu" {
  description = "CPU limits for Prometheus"
  type        = string
  default     = "400m"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"
}

variable "alertmanager_replicas" {
  description = "Number of Alertmanager replicas"
  type        = number
  default     = 1
}

variable "alertmanager_resources_requests_memory" {
  description = "Memory requests for Alertmanager"
  type        = string
  default     = "100Mi"
}

variable "alertmanager_resources_requests_cpu" {
  description = "CPU requests for Alertmanager"
  type        = string
  default     = "80m"
}

variable "alertmanager_resources_limits_memory" {
  description = "Memory limits for Alertmanager"
  type        = string
  default     = "200Mi"
}

variable "alertmanager_resources_limits_cpu" {
  description = "CPU limits for Alertmanager"
  type        = string
  default     = "160m"
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "2Gi"
}

variable "grafana_replicas" {
  description = "Number of Grafana replicas"
  type        = number
  default     = 1
}

variable "grafana_resources_requests_memory" {
  description = "Memory requests for Grafana"
  type        = string
  default     = "200Mi"
}

variable "grafana_resources_requests_cpu" {
  description = "CPU requests for Grafana"
  type        = string
  default     = "80m"
}

variable "grafana_resources_limits_memory" {
  description = "Memory limits for Grafana"
  type        = string
  default     = "400Mi"
}

variable "grafana_resources_limits_cpu" {
  description = "CPU limits for Grafana"
  type        = string
  default     = "160m"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "5Gi"
}

variable "keycloak_replicas" {
  description = "Number of Keycloak replicas"
  type        = number
  default     = 1
}

variable "keycloak_resources_requests_memory" {
  description = "Memory requests for Keycloak"
  type        = string
  default     = "400Mi"
}

variable "keycloak_resources_requests_cpu" {
  description = "CPU requests for Keycloak"
  type        = string
  default     = "400m"
}

variable "keycloak_resources_limits_memory" {
  description = "Memory limits for Keycloak"
  type        = string
  default     = "800Mi"
}

variable "keycloak_resources_limits_cpu" {
  description = "CPU limits for Keycloak"
  type        = string
  default     = "800m"
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

variable "postgresql_metrics_resources_requests_memory" {
  description = "Memory requests for PostgreSQL metrics"
  type        = string
  default     = "25Mi"
}

variable "postgresql_metrics_resources_requests_cpu" {
  description = "CPU requests for PostgreSQL metrics"
  type        = string
  default     = "40m"
}

variable "postgresql_metrics_resources_limits_memory" {
  description = "Memory limits for PostgreSQL metrics"
  type        = string
  default     = "50Mi"
}

variable "postgresql_metrics_resources_limits_cpu" {
  description = "CPU limits for PostgreSQL metrics"
  type        = string
  default     = "80m"
}

variable "real_domain" {
  description = "The real domain to use for the cluster"
  type        = string
  default     = "danielgherasim.com"
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
