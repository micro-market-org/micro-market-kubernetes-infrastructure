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

resource "kubernetes_namespace_v1" "postgresql" {
  metadata {
    name = "postgresql"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform-bootstrap"
      "environment"                        = var.environment
      "app.kubernetes.io/part-of"          = "postgresql"
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

resource "kubernetes_namespace_v1" "microservices" {
  metadata {
    name = "microservices"
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
        "cloud-provider"            = "aws"
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
              cloudProvider                = "aws"
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
                externalSecretsRoleArn = local.external_secrets_role_arn
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

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "argocd_microservices_appset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "microservices"
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
      labels = {
        "app.kubernetes.io/part-of" = "microservices"
        "cloud-provider"            = "aws"
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
                    { env = "dev" },
                    { env = "staging" },
                    { env = "prod" },
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
            "cloud-provider"            = "aws"
          }
        }
        spec = {
          project = "default"
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
  }

  depends_on = [helm_release.argocd]
}
