# Backend override for GCP. Copied to ../backend_override.tf by CI/scripts
# before `terraform init -backend-config=backends/gcs.hcl`.
# Credentials come from GOOGLE_APPLICATION_CREDENTIALS.
terraform {
  backend "gcs" {}
}
