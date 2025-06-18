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
  default = "cloud-infra"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "cluster_issuer" {
  type        = string
  description = "The cert-manager ClusterIssuer to use for certificate issuance"
  default     = "letsencrypt-production-cluster-issuer"
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
  default     = "100m"
}

variable "cert_manager_resources_requests_memory" {
  description = "Memory requests for cert-manager"
  type        = string
  default     = "128Mi"
}

variable "cert_manager_resources_limits_cpu" {
  description = "CPU limits for cert-manager"
  type        = string
  default     = "200m"
}

variable "cert_manager_resources_limits_memory" {
  description = "Memory limits for cert-manager"
  type        = string
  default     = "256Mi"
}

variable "cert_manager_webhook_resources_requests_cpu" {
  description = "CPU requests for cert-manager webhook"
  type        = string
  default     = "50m"
}

variable "cert_manager_webhook_resources_requests_memory" {
  description = "Memory requests for cert-manager webhook"
  type        = string
  default     = "64Mi"
}

variable "cert_manager_webhook_resources_limits_cpu" {
  description = "CPU limits for cert-manager webhook"
  type        = string
  default     = "100m"
}

variable "cert_manager_webhook_resources_limits_memory" {
  description = "Memory limits for cert-manager webhook"
  type        = string
  default     = "128Mi"
}

variable "cert_manager_cainjector_resources_requests_cpu" {
  description = "CPU requests for cert-manager cainjector"
  type        = string
  default     = "50m"
}

variable "cert_manager_cainjector_resources_requests_memory" {
  description = "Memory requests for cert-manager cainjector"
  type        = string
  default     = "64Mi"
}

variable "cert_manager_cainjector_resources_limits_cpu" {
  description = "CPU limits for cert-manager cainjector"
  type        = string
  default     = "100m"
}

variable "cert_manager_cainjector_resources_limits_memory" {
  description = "Memory limits for cert-manager cainjector"
  type        = string
  default     = "128Mi"
}

# NGINX Ingress variables
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
  default     = "200m"
}

variable "nginx_ingress_resources_requests_memory" {
  description = "Memory requests for NGINX Ingress"
  type        = string
  default     = "256Mi"
}

variable "nginx_ingress_resources_limits_cpu" {
  description = "CPU limits for NGINX Ingress"
  type        = string
  default     = "500m"
}

variable "nginx_ingress_resources_limits_memory" {
  description = "Memory limits for NGINX Ingress"
  type        = string
  default     = "512Mi"
}

# PostgreSQL variables
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
  default     = "256Mi"
}

variable "postgresql_primary_resources_requests_cpu" {
  description = "CPU requests for PostgreSQL primary"
  type        = string
  default     = "250m"
}

variable "postgresql_primary_resources_limits_memory" {
  description = "Memory limits for PostgreSQL primary"
  type        = string
  default     = "1Gi"
}

variable "postgresql_primary_resources_limits_cpu" {
  description = "CPU limits for PostgreSQL primary"
  type        = string
  default     = "1000m"
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
  default     = "256Mi"
}

variable "postgresql_read_replicas_resources_requests_cpu" {
  description = "CPU requests for PostgreSQL read replicas"
  type        = string
  default     = "250m"
}

variable "postgresql_read_replicas_resources_limits_memory" {
  description = "Memory limits for PostgreSQL read replicas"
  type        = string
  default     = "1Gi"
}

variable "postgresql_read_replicas_resources_limits_cpu" {
  description = "CPU limits for PostgreSQL read replicas"
  type        = string
  default     = "500m"
}

variable "prometheus_replicas" {
  description = "Number of Prometheus replicas"
  type        = number
  default     = 1
}

variable "prometheus_resources_requests_memory" {
  description = "Memory requests for Prometheus"
  type        = string
  default     = "512Mi"
}

variable "prometheus_resources_requests_cpu" {
  description = "CPU requests for Prometheus"
  type        = string
  default     = "200m"
}

variable "prometheus_resources_limits_memory" {
  description = "Memory limits for Prometheus"
  type        = string
  default     = "1Gi"
}

variable "prometheus_resources_limits_cpu" {
  description = "CPU limits for Prometheus"
  type        = string
  default     = "500m"
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
  default     = "128Mi"
}

variable "alertmanager_resources_requests_cpu" {
  description = "CPU requests for Alertmanager"
  type        = string
  default     = "100m"
}

variable "alertmanager_resources_limits_memory" {
  description = "Memory limits for Alertmanager"
  type        = string
  default     = "256Mi"
}

variable "alertmanager_resources_limits_cpu" {
  description = "CPU limits for Alertmanager"
  type        = string
  default     = "200m"
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
  default     = "256Mi"
}

variable "grafana_resources_requests_cpu" {
  description = "CPU requests for Grafana"
  type        = string
  default     = "100m"
}

variable "grafana_resources_limits_memory" {
  description = "Memory limits for Grafana"
  type        = string
  default     = "512Mi"
}

variable "grafana_resources_limits_cpu" {
  description = "CPU limits for Grafana"
  type        = string
  default     = "200m"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "5Gi"
}

variable "loki_replicas" {
  description = "Number of Loki replicas"
  type        = number
  default     = 1
}

variable "loki_resources_requests_memory" {
  description = "Memory requests for Loki"
  type        = string
  default     = "512Mi"
}

variable "loki_resources_requests_cpu" {
  description = "CPU requests for Loki"
  type        = string
  default     = "200m"
}

variable "loki_resources_limits_memory" {
  description = "Memory limits for Loki"
  type        = string
  default     = "1Gi"
}

variable "loki_resources_limits_cpu" {
  description = "CPU limits for Loki"
  type        = string
  default     = "500m"
}

variable "loki_storage_size" {
  description = "Storage size for Loki"
  type        = string
  default     = "10Gi"
}
