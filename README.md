# kubernetes-infrastructure

Bootstrap-only Terraform for the in-cluster GitOps entry point. This repo does **not** manage platform add-ons (no Helm releases for cert-manager/Istio/monitoring/Keycloak/etc. live here anymore) — its entire job is to stand up just enough for ArgoCD to take over everything else. That's a deliberate "hybrid GitOps" split from the multicloud overhaul (Phase 2): Terraform bootstraps the cluster connection, ArgoCD, the microservices AppProject, and the two root ArgoCD entry points; **ArgoCD, syncing from `../platform-gitops` and `../deployment`, owns every workload from there on.**

> **Branch note:** this repo is currently checked out on `prod` (not `main`/`dev`), same as `../infrastructure`.

## What it actually creates

Everything lives under `terraform/kubernetes/`. Reads `../infrastructure`'s remote state (`data.tf`, `data.terraform_remote_state`) for cluster credentials/endpoint — **`infrastructure` must be applied first** for the target cloud. The cloud connection itself is provider-conditional (`var.cloud_provider`): only the matching `azurerm`/`google`/`aws` remote-state block and the matching `kubernetes`/`helm` provider `exec` plugin (AWS: `aws eks get-token`; GCP: `gke-gcloud-auth-plugin`; Azure: client cert/key from remote state) are actually used per apply.

Beyond that, `bootstrap.tf` creates:

- Kubernetes namespaces: `cert-manager`, `monitoring`, `postgresql`, `keycloak`, `external-dns`, and `microservices` (the last one labeled `istio.io/dataplane-mode: ambient` so Istio's ambient mesh picks it up automatically).
- A `keycloak-config` ConfigMap (just the realm issuer URL — not a secret).
- `helm_release.argocd` (ArgoCD itself) plus repo-credential secrets so ArgoCD can pull from the private `deployment` and `platform-gitops` GitLab repos.
- Three ArgoCD bootstrap custom resources rendered through the ArgoCD Helm chart's `extraObjects`, not through standalone `kubernetes_manifest` resources. This is deliberate: the Terraform Kubernetes provider validates CRD-backed GVKs during planning, so direct `kubernetes_manifest` resources fail on a fresh cluster before ArgoCD installs its CRDs. Helm installs the chart CRDs first and then applies these bootstrap objects in the same release:
  1. **`microservices` AppProject** — restricts the microservice applications to the expected repos, namespaces, and cluster-scoped kinds.
  2. **`platform-root` Application** — points at `platform-gitops`'s `bootstrap/root` path. This is platform-gitops's single entry point; everything else in that repo hangs off this one Application as an app-of-apps.
  3. **`microservices` ApplicationSet** — fans out the 4 microservice Helm charts from `../deployment` across all 3 environments (see below).

`state_migration.tf` contains `removed` blocks for the former direct
`kubernetes_manifest` addresses with `destroy = false`. Existing states will
forget those old addresses without deleting the live ArgoCD objects; the Helm
release then owns the rendered definitions going forward.

There is currently no other ArgoCD resource created by this repo's Terraform — every platform add-on and every per-environment microservice deployment is the responsibility of the bootstrap resources above, resolved by ArgoCD at sync time.

The only file that remains under `terraform/kubernetes/configs/` is
`argocd_config.yaml.template`, which is still active: `argocd.tf` passes it to
the ArgoCD Helm release as values. Older monitoring, Loki, Prometheus,
Alertmanager, Alloy, network-policy, and static AppProject YAML files were
removed after the GitOps split because their live equivalents now belong in
`platform-gitops` or are rendered through the ArgoCD Helm release.

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

The `platform-root` Application is part of the Helm release `extraObjects` list and injects a large `global`/`secretStores` `valuesObject` (cloud provider, environment, domain, auth domain, ACME email, cluster issuer, and per-cloud External Secrets Operator wiring — role ARN for AWS, Key Vault URL/client ID for Azure, service account for GCP) into `platform-gitops`'s `bootstrap/root` chart.

## CI pipeline (`.gitlab-ci.yml`)

Same shape and cloud-parameterization pattern as `../infrastructure`: stages `validate → plan → apply (manual) → destroy (manual)`, backend selection via `backends/{azurerm,gcs,s3}.{tf,hcl}` copied to a gitignored `backend_override.tf` and `terraform init -reconfigure -backend-config=...`. A `checkov` job runs in `validate`, independent of the `validate` (fmt+validate) job, scanning `terraform/`.

For AWS, CI uses GitLab OIDC rather than static AWS keys: `AWS_ROLE_ARN` points
at an IAM role trusted by the `kubernetes-infrastructure` protected branch,
GitLab provides `GITLAB_OIDC_TOKEN`, and the pipeline exchanges it for one-hour
STS credentials before running Terraform and `aws eks get-token`.

## Destroy order and ArgoCD cascade cleanup

Before running a Kubernetes-layer destroy, run `terraform/kubernetes/destroy_argocd_apps.sh` against the target cluster. The helper deletes the `microservices` ApplicationSet, its 12 generated microservice Applications, and `platform-root` with ArgoCD foreground finalizers so ArgoCD prunes managed resources before Terraform removes the bootstrap layer. This implements the pre-destroy cascade-delete step called out in the root runbook.

## `.checkov.yaml` — much shorter than `infrastructure`'s

`skip-check: []` — empty. This root is intentionally tiny after the Phase 2 bootstrap-only shrink (namespaces + ArgoCD + three ArgoCD bootstrap resources rendered as Helm `extraObjects`, nothing else), so a full checkov run comes back with zero findings; there's nothing to document a skip for. The file exists purely so the CI `checkov` job has a stable, version-controlled config to point at, with a comment explaining the pattern to follow (`../infrastructure/.checkov.yaml`) if a future change ever introduces a genuine, accepted finding here.
