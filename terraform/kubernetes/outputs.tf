output "project_name" {
  value       = var.project_name
  description = "The name of the project"
}

output "domain" {
  value       = local.current_domain
  description = "The domain name for the cluster"
}

output "argocd_admin_password" {
  value       = local.argocd_admin_password
  description = "The admin password for ArgoCD (sourced from cloud secret manager via remote state)"
  sensitive   = true
}
