locals {
  external_secrets_effective_role_arn = (
    var.external_secrets_role_arn != "" ? var.external_secrets_role_arn :
    var.cloud_provider == "aws" ? try(data.terraform_remote_state.aws[0].outputs.external_secrets_role_arn, "") :
    ""
  )
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "cert-manager"
    }
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "monitoring"
    }
  }
}

resource "kubernetes_namespace_v1" "postgresql" {
  metadata {
    name = "postgresql"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "postgresql"
    }
  }
}

resource "kubernetes_namespace_v1" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "keycloak"
    }
  }
}

resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "dns"
    }
  }
}

resource "kubernetes_namespace_v1" "microservices" {
  metadata {
    name = "microservices"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "microservices"
      "istio.io/dataplane-mode"      = "ambient"
    }
  }
}

resource "kubernetes_config_map_v1" "keycloak_config" {
  metadata {
    name      = "keycloak-config"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  data = {
    "url" = "https://${local.auth_domain}/auth/realms/microservices"
  }
}

resource "kubernetes_manifest" "argocd_platform_root_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "platform-root"
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
      labels = {
        "app.kubernetes.io/part-of" = "platform"
        "environment"               = var.environment
        "cloud-provider"            = var.cloud_provider
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.argocd_platform_repo_url
        targetRevision = var.argocd_platform_target_revision
        path           = "bootstrap/root"
        helm = {
          valuesObject = {
            global = {
              repoURL                      = var.argocd_platform_repo_url
              targetRevision               = var.argocd_platform_target_revision
              cloudProvider                = var.cloud_provider
              environment                  = var.environment
              domain                       = local.current_domain
              authDomain                   = local.auth_domain
              acmeEmail                    = var.lets_encrypt_email
              clusterIssuer                = var.cluster_issuer
              cloudflareApiTokenSecretName = var.cloudflare_api_token_secret_name
            }
            secretStores = {
              aws = {
                region                 = var.aws_region
                secretPrefix           = local.aws_secret_prefix
                externalSecretsRoleArn = local.external_secrets_effective_role_arn
              }
              azure = {
                vaultUrl                = local.azure_key_vault_uri
                tenantId                = var.tenant_id
                externalSecretsClientId = local.azure_external_secrets_client_id
              }
              gcp = {
                projectId                     = var.gcp_project
                clusterLocation               = var.gcp_zone
                clusterName                   = local.gcp_cluster_name
                secretPrefix                  = local.gcp_secret_prefix
                externalSecretsServiceAccount = local.gcp_external_secrets_service_account
              }
            }
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace_v1.argocd.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [
    helm_release.argocd,
  ]
}
