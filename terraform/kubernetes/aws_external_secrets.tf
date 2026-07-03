locals {
  aws_secret_prefix = "${var.project_name}/${var.environment}"
}

resource "kubernetes_manifest" "aws_cluster_secret_store" {
  count = local.aws_platform_enabled ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = kubernetes_namespace_v1.external_secrets[0].metadata[0].name
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_manifest" "aws_microservice_db_external_secret" {
  for_each = local.aws_platform_enabled ? toset(["catalog", "orders", "audit"]) : toset([])

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "${each.key}-db-secret"
      namespace = kubernetes_namespace_v1.microservices.metadata[0].name
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "aws-secrets-manager"
      }
      target = {
        name           = "${each.key}-db-secret"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = "${local.aws_secret_prefix}/${each.key}/db"
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = "${local.aws_secret_prefix}/${each.key}/db"
            property = "password"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.aws_cluster_secret_store]
}

resource "kubernetes_manifest" "aws_keycloak_client_external_secret" {
  count = local.aws_platform_enabled ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "keycloak-secret"
      namespace = kubernetes_namespace_v1.microservices.metadata[0].name
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "aws-secrets-manager"
      }
      target = {
        name           = "keycloak-secret"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "catalog-service-secret"
          remoteRef = {
            key      = "${local.aws_secret_prefix}/keycloak/clients"
            property = "catalog-service-secret"
          }
        },
        {
          secretKey = "orders-service-secret"
          remoteRef = {
            key      = "${local.aws_secret_prefix}/keycloak/clients"
            property = "orders-service-secret"
          }
        },
        {
          secretKey = "audit-service-secret"
          remoteRef = {
            key      = "${local.aws_secret_prefix}/keycloak/clients"
            property = "audit-service-secret"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.aws_cluster_secret_store]
}
