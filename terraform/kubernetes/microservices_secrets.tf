
resource "kubernetes_namespace_v1" "microservices" {
  metadata {
    name = "microservices"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "microservices"
    }
  }
}

resource "random_password" "catalog_client_secret" {
  length  = 16
  special = false
}

resource "random_password" "orders_client_secret" {
  length  = 16
  special = false
}

resource "random_password" "audit_client_secret" {
  length  = 16
  special = false
}

resource "kubernetes_secret_v1" "orders_db_secret" {
  count = local.aws_platform_enabled ? 0 : 1

  metadata {
    name      = "orders-db-secret"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  data = {
    "username" = "postgres"
    "password" = random_password.postgresql_password.result
  }
}

resource "kubernetes_secret_v1" "audit_db_secret" {
  count = local.aws_platform_enabled ? 0 : 1

  metadata {
    name      = "audit-db-secret"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  data = {
    "username" = "postgres"
    "password" = random_password.postgresql_password.result
  }
}

resource "kubernetes_secret_v1" "catalog_db_secret" {
  count = local.aws_platform_enabled ? 0 : 1

  metadata {
    name      = "catalog-db-secret"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  data = {
    "username" = "postgres"
    "password" = random_password.postgresql_password.result
  }
}

resource "kubernetes_secret_v1" "keycloak_client_secrets" {
  count = local.aws_platform_enabled ? 0 : 1

  metadata {
    name      = "keycloak-secret"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  data = {
    "audit-service-secret"   = random_password.audit_client_secret.result
    "catalog-service-secret" = random_password.catalog_client_secret.result
    "orders-service-secret"  = random_password.orders_client_secret.result
  }
}

locals {
  catalog_client_secret = random_password.catalog_client_secret.result
  orders_client_secret  = random_password.orders_client_secret.result
  audit_client_secret   = random_password.audit_client_secret.result
}

output "microservices_db_credentials" {
  description = "Database credentials for microservices"
  value = {
    username = "postgres"
    password = random_password.postgresql_password.result
  }
  sensitive = true
}

resource "kubernetes_config_map_v1" "keycloak_config" {
  metadata {
    name      = "keycloak-config"
    namespace = kubernetes_namespace_v1.microservices.metadata[0].name
  }

  data = {
    "url" = "https://${local.current_domain}/auth/realms/microservices"
  }
}

output "microservices_keycloak_client_secrets" {
  description = "Keycloak client secrets for microservices"
  value = {
    catalog = random_password.catalog_client_secret.result
    orders  = random_password.orders_client_secret.result
    audit   = random_password.audit_client_secret.result
  }
  sensitive = true
}
