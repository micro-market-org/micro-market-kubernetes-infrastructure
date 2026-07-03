# Backend override for Azure. Copied to ../backend_override.tf by CI/scripts
# before `terraform init -backend-config=backends/azurerm.hcl`.
# Credentials come from ARM_* environment variables.
terraform {
  backend "azurerm" {}
}
