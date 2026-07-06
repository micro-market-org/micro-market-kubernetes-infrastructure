---
title: Multi-cloud Terraform root split for kubernetes-infrastructure
status: completed
created: 2026-07-06
updated: 2026-07-06
---

# Multi-cloud Terraform root split

## Context

`kubernetes-infrastructure/terraform/kubernetes/` was a single Terraform root that handled
AWS, Azure, and GCP through a `cloud_provider` variable. Every `terraform init` required all
three provider plugins (aws, azurerm, google) even when only one cloud was active. Provider
configuration, remote-state data sources, and the secretStores values for platform-root were
all wrapped in `var.cloud_provider` conditionals.

This mirrors the pattern already used by `infrastructure/terraform/{aws,azure,gcp}/` and
eliminates the conditional complexity.

## What changed

### New roots created

| Root | Providers |
|---|---|
| `kubernetes-infrastructure/terraform/aws/` | aws + helm + kubernetes (EKS token exec) |
| `kubernetes-infrastructure/terraform/azure/` | azurerm + helm + kubernetes (mTLS client cert) |
| `kubernetes-infrastructure/terraform/gcp/` | google + helm + kubernetes (gke-gcloud-auth-plugin) |

Each root contains:
- `main.tf` — provider block and connection locals from remote state
- `variables.tf` — shared ArgoCD/domain/GitLab vars + only that cloud's auth/remote-state vars
- `data.tf` — single remote state data source; no conditionals; direct locals for passwords, prefixes
- `bootstrap.tf` — namespace resources + ArgoCD Applications; `secretStores` passes only the active cloud's config
- `argocd.tf` — ArgoCD Helm release (identical across all three)
- `outputs.tf` — project_name, domain, argocd_admin_password
- `apply.sh` / `destroy.sh` — credential checks, single backend init, plan+apply
- `tfvars_files/{dev,staging,prod}.tfvars`
- `configs/argocd_config.yaml.template`

### Dead variables removed from each root

Variables declared in the old `kubernetes/variables.tf` but never referenced in any `.tf`
resource block were not carried into the new roots:
- `database`, `kubernetes_host`, `kubernetes_client_certificate`, `kubernetes_client_key`,
  `kubernetes_cluster_ca_certificate` (overridden by remote state)
- `container_registry`, `container_image_namespace`
- `enable_aws_platform_addons`, `aws_load_balancer_controller_role_arn`, `external_dns_role_arn`

### Azure apply/destroy standardised

Old `azure_apply.sh` used TF workspaces and an interactive confirmation prompt. New
`azure/apply.sh` and `azure/destroy.sh` follow the same no-workspace, plan-file pattern
as the AWS and GCP scripts.

### Old root preserved

`kubernetes-infrastructure/terraform/kubernetes/` is kept in place. It should be treated as
deprecated; new deployments use the cloud-specific roots above. A session also fixed its
`outputs.tf` to use `local.argocd_admin_password` (the `random_password.argo_password`
resource it previously referenced was removed in the ArgoCD→ESO migration).

## Tasks

- [x] Create `kubernetes-infrastructure/terraform/aws/` with all required files
- [x] Create `kubernetes-infrastructure/terraform/azure/` with all required files
- [x] Create `kubernetes-infrastructure/terraform/gcp/` with all required files
- [x] Run `terraform fmt -recursive` on all three roots (clean)
- [x] Verify no `var.cloud_provider` conditionals remain in the new roots
- [x] Fix `kubernetes/outputs.tf` broken reference to removed `random_password.argo_password`
