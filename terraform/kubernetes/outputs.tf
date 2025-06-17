output "project_name" {
  value       = var.project_name
  description = "The name of the project"
}

output "domain" {
  value       = local.current_domain
  description = "The domain name for the cluster"
}

output "argocd_admin_password" {
  value       = random_password.argo_password.result
  description = "The admin password for ArgoCD"
  sensitive   = true
}

output "grafana_admin_password" {
  value       = random_password.grafana_password.result
  description = "The admin password for Grafana"
  sensitive   = true
}
