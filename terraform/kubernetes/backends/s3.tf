# Backend override for AWS. Copied to ../backend_override.tf by CI/scripts
# before `terraform init -backend-config=backends/s3.hcl`.
# Credentials come from AWS_* environment variables; the state key is passed
# per environment: -backend-config="key=kubernetes/aws/<env>/terraform.tfstate".
terraform {
  backend "s3" {}
}
