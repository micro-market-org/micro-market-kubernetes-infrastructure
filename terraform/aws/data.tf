locals {
  current_domain = var.real_domain != null && var.real_domain != "" ? var.real_domain : data.terraform_remote_state.infra.outputs.eks_cluster_endpoint
  auth_domain    = var.auth_domain != "" ? var.auth_domain : "auth.${var.real_domain}"

  argocd_oidc_client_secret = try(data.terraform_remote_state.infra.outputs.argocd_oidc_client_secret, "")
  argocd_admin_password     = try(data.terraform_remote_state.infra.outputs.argocd_admin_password, "")
  argocd_redis_password     = try(data.terraform_remote_state.infra.outputs.argocd_redis_password, "")

  aws_secret_prefix                     = try(data.terraform_remote_state.infra.outputs.secret_prefix, "${var.project_name}/${var.environment}")
  external_secrets_role_arn             = try(data.terraform_remote_state.infra.outputs.external_secrets_role_arn, "")
  aws_load_balancer_controller_role_arn = try(data.terraform_remote_state.infra.outputs.aws_load_balancer_controller_role_arn, "")
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = var.remote_state_key != "" ? var.remote_state_key : "aws/${var.environment}/terraform.tfstate"
    region = var.remote_state_region
  }
}
