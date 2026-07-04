# kubernetes-infrastructure

Bootstrap-only Terraform for the in-cluster GitOps entry point. This repo does **not** manage platform add-ons (no Helm releases for cert-manager/Istio/monitoring/Keycloak/etc. live here anymore) — its entire job is to stand up just enough for ArgoCD to take over everything else. That's a deliberate "hybrid GitOps" split from the multicloud overhaul (Phase 2): Terraform bootstraps the cluster connection + ArgoCD + two root ArgoCD resources; **ArgoCD, syncing from `../platform-gitops` and `../deployment`, owns every workload from there on.**

> **Branch note:** this repo is currently checked out on `prod` (not `main`/`dev`), same as `../infrastructure`.

## What it actually creates

Everything lives under `terraform/kubernetes/`. Reads `../infrastructure`'s remote state (`data.tf`, `data.terraform_remote_state`) for cluster credentials/endpoint — **`infrastructure` must be applied first** for the target cloud. The cloud connection itself is provider-conditional (`var.cloud_provider`): only the matching `azurerm`/`google`/`aws` remote-state block and the matching `kubernetes`/`helm` provider `exec` plugin (AWS: `aws eks get-token`; GCP: `gke-gcloud-auth-plugin`; Azure: client cert/key from remote state) are actually used per apply.

Beyond that, `bootstrap.tf` creates:

- Kubernetes namespaces: `cert-manager`, `monitoring`, `postgresql`, `keycloak`, `external-dns`, and `microservices` (the last one labeled `istio.io/dataplane-mode: ambient` so Istio's ambient mesh picks it up automatically).
- A `keycloak-config` ConfigMap (just the realm issuer URL — not a secret).
- `helm_release.argocd` (ArgoCD itself) plus repo-credential secrets so ArgoCD can pull from the private `deployment` and `platform-gitops` GitLab repos.
- **Exactly two `kubernetes_manifest` resources**, both created directly by Terraform rather than committed as YAML synced from a repo path (the same way ArgoCD itself is installed via `helm_release`, not GitOps):
  1. **`platform-root`** — an ArgoCD `Application` pointing at `platform-gitops`'s `bootstrap/root` path. This is platform-gitops's single entry point; everything else in that repo hangs off this one Application as an app-of-apps.
  2. **`microservices`** — an ArgoCD `ApplicationSet` (Phase 10) that fans out the 4 microservice Helm charts from `../deployment` across all 3 environments (see below).

There is currently no other ArgoCD resource created by this repo's Terraform — every platform add-on and every per-environment microservice deployment is the responsibility of the two resources above, resolved by ArgoCD at sync time.

## The `microservices` ApplicationSet — matrix generator mechanics

This is the most structurally interesting piece of this repo. It uses ArgoCD's **matrix generator**: an inline **list generator** of the 4 apps crossed with an inline **list generator** of the 3 environments —

```
generators:
  - matrix:
      generators:
        - list: { elements: [{app: catalog}, {app: orders}, {app: audit}, {app: micro-market-frontend}] }
        - list: { elements: [{env: dev}, {env: staging}, {env: prod}] }
```

— producing 12 generated `Application` resources (4 × 3), each named `{{app}}-{{env}}` (classic fasttemplate substitution, not `goTemplate`). Each generated Application:

- `source.repoURL`/`targetRevision`: the `../deployment` repo (`argocd_deployment_repo_url` var, default `https://gitlab.com/microservices1691715/deployment.git`, `HEAD`).
- `source.path`: `{{app}}` — i.e. the chart directory (`deployment/catalog`, `deployment/orders`, ...).
- `source.helm.valueFiles`: `../environments/{{env}}/{{app}}-values.yaml` — pointing at `deployment`'s top-level `environments/<env>/<app>-values.yaml` overlay (see `../deployment`'s README for that layout).
- `destination.namespace`: `micro-market-{{env}}`.
- `syncPolicy.automated.{prune,selfHeal}` + `CreateNamespace=true`.

Image repository/tag are deliberately **not** injected as ApplicationSet Helm parameters here — they live inside the per-env values files themselves, which is also the write-back target of `deployment`'s CI promote stage. This keeps one single source of truth for "what image is actually running in env X" (the git-committed values file) instead of splitting it between Terraform-templated ApplicationSet parameters and CI-written values.

The `platform-root` Application follows the same "Terraform creates a `kubernetes_manifest` directly" pattern and injects a large `global`/`secretStores` `valuesObject` (cloud provider, environment, domain, auth domain, ACME email, cluster issuer, and per-cloud External Secrets Operator wiring — role ARN for AWS, Key Vault URL/client ID for Azure, service account for GCP) into `platform-gitops`'s `bootstrap/root` chart.

## CI pipeline (`.gitlab-ci.yml`)

Same shape and cloud-parameterization pattern as `../infrastructure`: stages `validate → plan → apply (manual) → destroy (manual)`, backend selection via `backends/{azurerm,gcs,s3}.{tf,hcl}` copied to a gitignored `backend_override.tf` and `terraform init -reconfigure -backend-config=...`. A `checkov` job runs in `validate`, independent of the `validate` (fmt+validate) job, scanning `terraform/`.

## `.checkov.yaml` — much shorter than `infrastructure`'s

`skip-check: []` — empty. This root is intentionally tiny after the Phase 2 bootstrap-only shrink (namespaces + ArgoCD + two `kubernetes_manifest` resources, nothing else), so a full checkov run comes back with zero findings; there's nothing to document a skip for. The file exists purely so the CI `checkov` job has a stable, version-controlled config to point at, with a comment explaining the pattern to follow (`../infrastructure/.checkov.yaml`) if a future change ever introduces a genuine, accepted finding here. One pre-existing false positive (`CKV_SECRET_6` on a `configSecret: "alertmanager-config"` line in `configs/kube-prometheus_config.yaml` — a Kubernetes Secret *name*, not a value, that happened to trip the generic high-entropy-string check) is suppressed inline rather than repo-wide, so real secret-value detection stays active everywhere else.
