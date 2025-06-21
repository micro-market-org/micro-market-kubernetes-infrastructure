resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "monitoring"
    }
  }
}

resource "kubernetes_secret_v1" "alertmanager_config" {
  metadata {
    name      = "alertmanager-config"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "alertmanager.yaml" = templatefile("${path.root}/configs/alertmanager_config.yaml", {
      SMTP_AUTH_PASSWORD = random_password.grafana_password.result
    })
  }
}

resource "random_password" "grafana_password" {
  length = 16
}

resource "random_password" "loki_password" {
  length = 16
}

resource "kubernetes_secret_v1" "grafana_oauth_secret" {
  metadata {
    name      = "grafana-oauth"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "GRAFANA_OIDC_CLIENT_SECRET" = random_password.grafana_oidc_client_secret.result
    "DOMAIN"                     = local.current_domain
  }
}

resource "kubernetes_secret_v1" "loki_auth_secret" {
  metadata {
    name      = "loki-auth"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "LOKI_PASSWORD" = random_password.loki_password.result
  }
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "75.3.0"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  timeout    = 600
  values     = [file("${path.root}/configs/kube-prometheus_config.yaml")]
  force_update = true
  replace      = true
  recreate_pods = true
  depends_on = [kubernetes_config_map_v1.grafana_alert_rules, kubernetes_config_map_v1.grafana_contact_points]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.grafana_password.result
  }

  set {
    name  = "grafana.grafana\\.ini.server.domain"
    value = local.current_domain
  }

  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = "https://${local.current_domain}/grafana"
  }

  set {
    name  = "prometheus.prometheusSpec.externalLabels.cluster"
    value = var.environment
  }

  set {
    name  = "prometheus.prometheusSpec.externalLabels.environment"
    value = var.environment
  }

  set {
    name  = "prometheus.prometheusSpec.replicas"
    value = var.prometheus_replicas
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = var.prometheus_resources_requests_memory
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = var.prometheus_resources_requests_cpu
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = var.prometheus_resources_limits_memory
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.cpu"
    value = var.prometheus_resources_limits_cpu
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  set {
    name  = "alertmanager.alertmanagerSpec.replicas"
    value = var.alertmanager_replicas
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.memory"
    value = var.alertmanager_resources_requests_memory
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.cpu"
    value = var.alertmanager_resources_requests_cpu
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.limits.memory"
    value = var.alertmanager_resources_limits_memory
  }

  set {
    name  = "alertmanager.alertmanagerSpec.resources.limits.cpu"
    value = var.alertmanager_resources_limits_cpu
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.alertmanager_storage_size
  }

  set {
    name  = "grafana.replicas"
    value = var.grafana_replicas
  }

  set {
    name  = "grafana.resources.requests.memory"
    value = var.grafana_resources_requests_memory
  }

  set {
    name  = "grafana.resources.requests.cpu"
    value = var.grafana_resources_requests_cpu
  }

  set {
    name  = "grafana.resources.limits.memory"
    value = var.grafana_resources_limits_memory
  }

  set {
    name  = "grafana.resources.limits.cpu"
    value = var.grafana_resources_limits_cpu
  }

  set {
    name  = "grafana.image.tag"
    value = "10.4.5"
  }

  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }

  set {
    name  = "alertmanager.alertmanagerSpec.externalUrl"
    value = "https://${local.current_domain}/alertmanager"
  }

  set {
    name  = "alertmanager.config.global.smtp_auth_username"
    value = "alertmanager@monitoring.local"
  }

  set_sensitive {
    name  = "alertmanager.config.global.smtp_auth_password"
    value = random_password.grafana_password.result
  }

  set_sensitive {
    name  = "grafana.envFromSecret"
    value = kubernetes_secret_v1.grafana_oauth_secret.metadata[0].name
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "6.30.1"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  depends_on = [helm_release.kube-prometheus, kubernetes_secret_v1.loki_auth_secret]
  values     = [file("${path.root}/configs/loki_config.yaml")]
}

resource "helm_release" "grafana-alloy" {
  name       = "grafana-alloy"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "1.1.1"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  depends_on = [helm_release.kube-prometheus]
  values     = [file("${path.root}/configs/grafana-alloy.yaml")]
}

resource "kubernetes_config_map_v1" "grafana_alert_rules" {
  metadata {
    name      = "grafana-alert-rules"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      grafana_alert_rules = "1"
    }
  }

  data = {
    "alert-rules.yaml" = file("${path.root}/configs/grafana_alert_rules.yaml")
  }
}

resource "kubernetes_config_map_v1" "grafana_contact_points" {
  metadata {
    name      = "grafana-contact-points"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      grafana_contact_points = "1"
    }
  }

  data = {
    "contact-points.yaml" = file("${path.root}/configs/grafana_contact_points.yaml")
  }
}

resource "kubernetes_config_map_v1" "microservices_alerts" {
  metadata {
    name      = "microservices-alerts"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      prometheus_alerts = "1"
    }
  }

  data = {
    "microservices_alerts.yaml" = <<-EOT
      groups:
      - name: microservices
        rules:
        - alert: MicroserviceHighCPUUsage
          expr: sum(rate(container_cpu_usage_seconds_total{namespace="microservices"}[5m])) by (pod) > 0.8
          for: 5m
          labels:
            severity: warning
            team: platform
          annotations:
            summary: "High CPU usage for microservice pod {{ $labels.pod }}"
            description: "Microservice pod {{ $labels.pod }} has high CPU usage (> 80%) for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/high-cpu"
        - alert: MicroserviceCriticalCPUUsage
          expr: sum(rate(container_cpu_usage_seconds_total{namespace="microservices"}[5m])) by (pod) > 0.95
          for: 5m
          labels:
            severity: critical
            team: platform
          annotations:
            summary: "Critical CPU usage for microservice pod {{ $labels.pod }}"
            description: "Microservice pod {{ $labels.pod }} has critical CPU usage (> 95%) for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/critical-cpu"
        - alert: MicroserviceHighMemoryUsage
          expr: sum(container_memory_usage_bytes{namespace="microservices"}) by (pod) / sum(container_spec_memory_limit_bytes{namespace="microservices"}) by (pod) > 0.8
          for: 5m
          labels:
            severity: warning
            team: platform
          annotations:
            summary: "High memory usage for microservice pod {{ $labels.pod }}"
            description: "Microservice pod {{ $labels.pod }} has high memory usage (> 80%) for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/high-memory"
        - alert: MicroserviceCriticalMemoryUsage
          expr: sum(container_memory_usage_bytes{namespace="microservices"}) by (pod) / sum(container_spec_memory_limit_bytes{namespace="microservices"}) by (pod) > 0.95
          for: 5m
          labels:
            severity: critical
            team: platform
          annotations:
            summary: "Critical memory usage for microservice pod {{ $labels.pod }}"
            description: "Microservice pod {{ $labels.pod }} has critical memory usage (> 95%) for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/critical-memory"
        - alert: MicroserviceHighErrorRate
          expr: sum(rate(http_requests_total{namespace="microservices", status=~"5.."}[5m])) by (service) / sum(rate(http_requests_total{namespace="microservices"}[5m])) by (service) > 0.05
          for: 5m
          labels:
            severity: critical
            team: application
          annotations:
            summary: "High error rate for microservice {{ $labels.service }}"
            description: "Microservice {{ $labels.service }} has a high HTTP error rate (> 5%) for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/high-error-rate"
        - alert: MicroserviceHighLatency
          expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace="microservices"}[5m])) by (service, le)) > 1
          for: 5m
          labels:
            severity: warning
            team: application
          annotations:
            summary: "High latency for microservice {{ $labels.service }}"
            description: "Microservice {{ $labels.service }} has a 95th percentile latency of more than 1 second for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/high-latency"
        - alert: MicroserviceCriticalLatency
          expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace="microservices"}[5m])) by (service, le)) > 2
          for: 5m
          labels:
            severity: critical
            team: application
          annotations:
            summary: "Critical latency for microservice {{ $labels.service }}"
            description: "Microservice {{ $labels.service }} has a 95th percentile latency of more than 2 seconds for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/critical-latency"
        - alert: MicroserviceDown
          expr: up{namespace="microservices"} == 0
          for: 5m
          labels:
            severity: critical
            team: platform
          annotations:
            summary: "Microservice {{ $labels.service }} is down"
            description: "Microservice {{ $labels.service }} has been down for more than 5 minutes."
            runbook_url: "https://example.com/runbooks/service-down"
        - alert: MicroservicePodRestarts
          expr: increase(kube_pod_container_status_restarts_total{namespace="microservices"}[1h]) > 2
          for: 5m
          labels:
            severity: warning
            team: platform
          annotations:
            summary: "Microservice pod {{ $labels.pod }} is restarting frequently"
            description: "Microservice pod {{ $labels.pod }} has restarted more than 2 times in the last hour."
            runbook_url: "https://example.com/runbooks/pod-restarts"
    EOT
  }

  depends_on = [helm_release.kube-prometheus]
}
