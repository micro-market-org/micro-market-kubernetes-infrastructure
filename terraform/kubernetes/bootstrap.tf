locals {
  external_secrets_effective_role_arn = (
    var.external_secrets_role_arn != "" ? var.external_secrets_role_arn :
    var.cloud_provider == "aws" ? try(data.terraform_remote_state.aws[0].outputs.external_secrets_role_arn, "") :
    ""
  )

  argocd_bootstrap_objects = [
    {
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "AppProject"
      metadata = {
        name      = "microservices"
        namespace = kubernetes_namespace_v1.argocd.metadata[0].name
      }
      spec = {
        description = "Microservices platform — restricts GitOps to known repos and namespaces"
        sourceRepos = [
          var.argocd_platform_repo_url,
          var.argocd_deployment_repo_url,
        ]
        destinations = [
          { server = "https://kubernetes.default.svc", namespace = "argocd" },
          { server = "https://kubernetes.default.svc", namespace = "cert-manager" },
          { server = "https://kubernetes.default.svc", namespace = "monitoring" },
          { server = "https://kubernetes.default.svc", namespace = "keycloak" },
          { server = "https://kubernetes.default.svc", namespace = "external-dns" },
          { server = "https://kubernetes.default.svc", namespace = "micro-market-${var.environment}" },
          { server = "https://kubernetes.default.svc", namespace = "kube-system" },
          { server = "https://kubernetes.default.svc", namespace = "istio-system" },
          { server = "https://kubernetes.default.svc", namespace = "external-secrets" },
        ]
        clusterResourceWhitelist = [
          { group = "*", kind = "ClusterRole" },
          { group = "*", kind = "ClusterRoleBinding" },
          { group = "*", kind = "CustomResourceDefinition" },
          { group = "*", kind = "Namespace" },
          { group = "*", kind = "IngressClass" },
          { group = "*", kind = "ClusterIssuer" },
        ]
      }
    },
    {
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
    },
    {
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "ApplicationSet"
      metadata = {
        name      = "microservices"
        namespace = kubernetes_namespace_v1.argocd.metadata[0].name
        labels = {
          "app.kubernetes.io/part-of" = "microservices"
          "cloud-provider"            = var.cloud_provider
        }
      }
      spec = {
        generators = [
          {
            matrix = {
              generators = [
                {
                  list = {
                    elements = [
                      { app = "catalog" },
                      { app = "orders" },
                      { app = "audit" },
                      { app = "micro-market-frontend" },
                    ]
                  }
                },
                {
                  list = {
                    elements = [
                      { env = var.environment },
                    ]
                  }
                },
              ]
            }
          }
        ]
        template = {
          metadata = {
            name = "{{app}}-{{env}}"
            labels = {
              "app.kubernetes.io/part-of" = "microservices"
              "environment"               = "{{env}}"
              "cloud-provider"            = var.cloud_provider
            }
          }
          spec = {
            project = "microservices"
            source = {
              repoURL        = var.argocd_deployment_repo_url
              targetRevision = var.argocd_deployment_target_revision
              path           = "{{app}}"
              helm = {
                valueFiles = [
                  "../environments/{{env}}/{{app}}-values.yaml",
                ]
              }
            }
            destination = {
              server    = "https://kubernetes.default.svc"
              namespace = "micro-market-{{env}}"
            }
            syncPolicy = {
              automated = {
                prune    = true
                selfHeal = true
              }
              syncOptions = [
                "CreateNamespace=true",
              ]
            }
          }
        }
      }
    },
  ]
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform-bootstrap"
      "environment"                        = var.environment
      "app.kubernetes.io/part-of"          = "cert-manager"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform-bootstrap"
      "environment"                        = var.environment
      "app.kubernetes.io/part-of"          = "monitoring"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_namespace_v1" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform-bootstrap"
      "environment"                        = var.environment
      "app.kubernetes.io/part-of"          = "keycloak"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform-bootstrap"
      "environment"                        = var.environment
      "app.kubernetes.io/part-of"          = "dns"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_namespace_v1" "micro_market" {
  metadata {
    name = "micro-market-${var.environment}"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform-bootstrap"
      "environment"                        = var.environment
      "app.kubernetes.io/part-of"          = "microservices"
      "istio.io/dataplane-mode"            = "ambient"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_config_map_v1" "keycloak_config" {
  metadata {
    name      = "keycloak-config"
    namespace = kubernetes_namespace_v1.micro_market.metadata[0].name
  }

  data = {
    "url" = "https://${local.auth_domain}/auth/realms/microservices"
  }
}
