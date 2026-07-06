locals {
  current_domain = (
    var.real_domain != null && var.real_domain != "" ? var.real_domain :
    "${var.project_name}.${var.azure_region}.cloudapp.azure.com"
  )
  auth_domain = var.auth_domain != "" ? var.auth_domain : "auth.${var.real_domain}"

  argocd_oidc_client_secret = try(data.terraform_remote_state.infra.outputs.argocd_oidc_client_secret, "")
  argocd_admin_password     = try(data.terraform_remote_state.infra.outputs.argocd_admin_password, "")
  argocd_redis_password     = try(data.terraform_remote_state.infra.outputs.argocd_redis_password, "")

  azure_key_vault_uri              = try(data.terraform_remote_state.infra.outputs.key_vault_uri, "")
  azure_external_secrets_client_id = try(data.terraform_remote_state.infra.outputs.external_secrets_client_id, "")
}

data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.remote_state_resource_group
    storage_account_name = var.remote_state_storage_account
    container_name       = var.remote_state_container
    key                  = var.remote_state_key != "" ? var.remote_state_key : "terraform.tfstateenv:${var.environment}"
  }
}
