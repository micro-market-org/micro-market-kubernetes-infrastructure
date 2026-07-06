locals {
  current_domain = var.real_domain != null && var.real_domain != "" ? var.real_domain : data.terraform_remote_state.infra.outputs.cluster_endpoint
  auth_domain    = var.auth_domain != "" ? var.auth_domain : "auth.${var.real_domain}"

  argocd_oidc_client_secret = try(data.terraform_remote_state.infra.outputs.argocd_oidc_client_secret, "")
  argocd_admin_password     = try(data.terraform_remote_state.infra.outputs.argocd_admin_password, "")
  argocd_redis_password     = try(data.terraform_remote_state.infra.outputs.argocd_redis_password, "")

  gcp_secret_prefix                    = try(data.terraform_remote_state.infra.outputs.secret_prefix, "${var.project_name}-${var.environment}")
  gcp_cluster_name                     = try(data.terraform_remote_state.infra.outputs.cluster_name, "")
  gcp_external_secrets_service_account = try(data.terraform_remote_state.infra.outputs.external_secrets_service_account_email, "")
}

data "terraform_remote_state" "infra" {
  backend = "gcs"
  config = {
    bucket = var.remote_state_bucket
    prefix = var.remote_state_prefix
  }
}
