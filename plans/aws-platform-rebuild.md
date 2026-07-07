---
status: abandoned
created: 2026-07-03
updated: 2026-07-03
owner: codex
repo: kubernetes-infrastructure
objective: Rebuild Kubernetes platform add-ons for AWS-first production readiness with Cloudflare DNS-only domain integration.
superseded-by: ../../plans/2026-07-03-multicloud-platform-overhaul.md
---

> **Superseded 2026-07-03**: absorbed into the workspace-root plan
> `Sources/plans/2026-07-03-multicloud-platform-overhaul.md` (all-clouds-equal strategy).
> Completed work here is kept; remaining tasks continue in that plan.

# AWS Platform Rebuild

## Context
- This repo owns Kubernetes add-ons and platform bootstrap for the dissertation microservices project.
- AWS is the production reference cloud; Azure/GCP remain compatibility paths.
- Cloudflare usage is DNS/free-tier only for `danielgherasim.com`.
- Backups and disaster recovery are out of scope.
- Current platform is Azure-oriented and needs AWS Load Balancer Controller, ExternalDNS, cert-manager DNS-01, External Secrets Operator, AWS storage classes, and restricted ArgoCD/Keycloak settings.

## Tasks
- [x] Remove hardcoded credentials from AWS helper scripts.
- [x] Remove hardcoded Azure/GitLab credentials from Azure helper scripts.
- [ ] Split or restructure provider-specific platform roots/backends.
- [x] Add AWS load balancer, DNS, certificate, and secrets add-ons.
- [x] Replace Azure-specific storage assumptions with AWS EBS CSI storage classes for AWS.
- [~] Harden ArgoCD, Keycloak, GitOps, network policies, and ingress model.

## Decisions
- Keep helper scripts environment-driven only; do not commit cloud or GitLab credentials.
- Use Cloudflare only for DNS records and optional DNS-01 validation token.
- AWS platform add-ons are gated by `cloud_provider == "aws"` and `enable_aws_platform_addons`.
- The Cloudflare token can be injected by Terraform for demos, but the preferred production path is a pre-created/external secret referenced by name.

## Validation
- Git Bash `bash -n` passed for `aws_apply.sh`, `aws_destroy.sh`, `azure_apply.sh`, and `azure_destroy.sh`.
- Secret-pattern scan excluding `.terraform` found no remaining live-looking AWS session key, GitLab PAT, or hardcoded Azure secret patterns in this repo.
- Added `aws_platform_addons.tf` with AWS Load Balancer Controller, ExternalDNS for Cloudflare DNS-only, External Secrets Operator, Cloudflare DNS-01 ClusterIssuer, and AWS `gp3` StorageClass.
- Updated `networking.tf` so ingress-nginx uses AWS NLB annotations when `cloud_provider = "aws"` and disables snippet annotations.
- Updated PostgreSQL chart values to use provider-specific storage class: `gp3` for AWS, `managed-csi` for non-AWS.
- Updated AWS helper scripts to pass `real_domain=danielgherasim.com` and `cluster_issuer=letsencrypt-cloudflare-dns` by default.
- AWS Load Balancer Controller and External Secrets Operator service accounts now read role ARNs from explicit variables or AWS infrastructure remote state outputs.
- On AWS, direct Kubernetes app secrets are disabled and replaced with ExternalSecret resources targeting AWS Secrets Manager while preserving existing secret names expected by Helm charts.
- Added ClusterSecretStore `aws-secrets-manager` and ExternalSecrets for `catalog-db-secret`, `orders-db-secret`, `audit-db-secret`, and `keycloak-secret`.
- `terraform fmt -recursive` ran in `terraform/kubernetes`.
- `terraform validate -no-color` passed for `terraform/kubernetes`.
- `terraform init -backend=false`/validation surfaced stale Azure backend credentials from the local working directory once, but a clean standalone `terraform validate` passed.
- Re-validation after AWS remote-state role wiring passed with `terraform validate -no-color`.
- Re-validation after External Secrets resources passed with `terraform validate -no-color`.
- ArgoCD hardening started:
  - `argocd_project.yaml` now restricts destinations to the `microservices` namespace and whitelists only expected application resource kinds instead of wildcarding all resources everywhere.
  - `argocd_config.yaml.template` disables the local admin user and sets OIDC `insecureSkipVerify` to false.
  - ArgoCD certificate issuer now uses the Terraform `cluster_issuer` variable, allowing AWS to use the Cloudflare DNS-01 issuer.
- Re-validation after ArgoCD hardening passed with `terraform validate -no-color`.
- Keycloak hardening continued:
  - Demo realm users are now gated by `enable_keycloak_demo_users` and disabled by default.
  - Keycloak log level is controlled by `keycloak_log_level`.
  - Direct access grants are disabled for the imported frontend/service clients.
  - Realm import extra args are only enabled when demo users are enabled.
- Re-validation after Keycloak hardening passed with `terraform validate -no-color`; Terraform still exits successfully but reports the local `C:\Users\adria\AppData\Roaming\terraform.d` access warning in the managed shell.
- GitOps ApplicationSet AWS/domain parameterization implemented:
  - Added Terraform-managed ArgoCD AppProject and ApplicationSet resources in `argocd_gitops.tf`.
  - Application image repositories now use full per-app AWS ECR URLs from AWS infrastructure remote state when `cloud_provider = "aws"`.
  - Non-AWS providers can still supply `container_registry` and `container_image_namespace`.
  - Added configurable `argocd_deployment_repo_url`, `gitops_applications`, and container image variables.
  - Changed Kubernetes Terraform default `project_name` to `danielgherasim-microservices`.
  - Changed default and per-environment `cluster_issuer` values to `letsencrypt-cloudflare-dns`.
  - Updated static ArgoCD ApplicationSet/config examples to remove old Azure registry, `micro-market.cloud`, HTTP-01 ingress annotations, enabled admin user, and insecure OIDC verification.
- Re-validation after GitOps parameterization passed with `terraform validate -no-color`; Terraform still reports the managed-shell `terraform.d` access warning.
- Stale-string scan found no remaining old Azure registry/domain, enabled ArgoCD admin, insecure OIDC, or HTTP-01 annotations in active Terraform/config paths. The standalone `production_issuer.yaml` still defines the legacy HTTP-01 issuer and is intentionally left as a non-AWS option.

## Next Steps
- Split provider-specific roots/backends so AWS platform validation no longer sees Azure backend state.
- Review whether to remove or archive legacy static HTTP-01 issuer manifests after non-AWS compatibility decisions are finalized.
- Continue application/network policy review from the deployment chart plan.
