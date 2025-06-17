resource "kubernetes_namespace_v1" "postgresql" {
  metadata {
    name = "postgresql"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "postgresql"
    }
  }
}

resource "random_password" "postgresql_password" {
  length  = 16
  special = false
}

resource "helm_release" "postgresql" {
  name             = "postgresql"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "12.5.8"
  namespace        = kubernetes_namespace_v1.postgresql.metadata[0].name
  create_namespace = false
  dependency_update = true
  lint              = true
  timeout           = 600
  depends_on        = [helm_release.cert_manager, helm_release.kube-prometheus]

  values = [
    <<-EOT
    global:
      postgresql:
        auth:
          username: "postgres"
          database: ${var.project_name}

    primary:
      persistence:
        enabled: true
        size: 10Gi

      resources:
        requests:
          memory: "256Mi"
          cpu: "250m"
        limits:
          memory: "1Gi"
          cpu: "1000m"

    metrics:
      enabled: true
      serviceMonitor:
        enabled: true
        namespace: "monitoring"
    EOT
  ]

  set_sensitive {
    name  = "global.postgresql.auth.postgresPassword"
    value = random_password.postgresql_password.result
  }

  set_sensitive {
    name  = "global.postgresql.auth.password"
    value = random_password.postgresql_password.result
  }
}

output "postgresql_host" {
  description = "PostgreSQL host"
  value       = "postgresql.postgresql.svc.cluster.local"
}

output "postgresql_port" {
  description = "PostgreSQL port"
  value       = 5432
}

output "postgresql_database" {
  description = "PostgreSQL database name"
  value       = var.project_name
}

output "postgresql_username" {
  description = "PostgreSQL username"
  value       = "postgres"
}

output "postgresql_password" {
  description = "PostgreSQL password"
  value       = random_password.postgresql_password.result
  sensitive   = true
}
