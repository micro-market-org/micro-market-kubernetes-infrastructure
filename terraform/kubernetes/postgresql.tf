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
  name              = "postgresql"
  repository        = "https://charts.bitnami.com/bitnami"
  chart             = "postgresql"
  version           = "12.5.8"
  namespace         = kubernetes_namespace_v1.postgresql.metadata[0].name
  create_namespace  = false
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
          database: ${var.database}

    architecture: ${var.postgresql_architecture}

    primary:
      persistence:
        enabled: true
        size: ${var.postgresql_primary_storage_size}
        storageClass: "managed-csi"

      resources:
        requests:
          memory: ${var.postgresql_primary_resources_requests_memory}
          cpu: ${var.postgresql_primary_resources_requests_cpu}
        limits:
          memory: ${var.postgresql_primary_resources_limits_memory}
          cpu: ${var.postgresql_primary_resources_limits_cpu}

      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: postgresql
                  app.kubernetes.io/instance: postgresql
              topologyKey: kubernetes.io/hostname

      podAnnotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9187"

      extraEnvVars:
        - name: POSTGRESQL_MAX_CONNECTIONS
          value: "${var.postgresql_max_connections}"
        - name: POSTGRESQL_SHARED_BUFFERS
          value: "${var.postgresql_shared_buffers}"

    readReplicas:
      replicaCount: ${var.postgresql_read_replicas_count}
      persistence:
        enabled: true
        size: ${var.postgresql_read_replicas_storage_size}
        storageClass: "managed-csi"

      resources:
        requests:
          memory: ${var.postgresql_read_replicas_resources_requests_memory}
          cpu: ${var.postgresql_read_replicas_resources_requests_cpu}
        limits:
          memory: ${var.postgresql_read_replicas_resources_limits_memory}
          cpu: ${var.postgresql_read_replicas_resources_limits_cpu}

      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app.kubernetes.io/name: postgresql
                  app.kubernetes.io/instance: postgresql
              topologyKey: kubernetes.io/hostname

      podAnnotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9187"

    metrics:
      enabled: true
      serviceMonitor:
        enabled: true
        namespace: "monitoring"
        interval: "30s"
      resources:
        requests:
          memory: "32Mi"
          cpu: "50m"
        limits:
          memory: "64Mi"
          cpu: "100m"
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
  value       = var.database
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
