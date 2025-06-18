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

resource "random_password" "grafana_password" {
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


resource "helm_release" "grafana-agent-operator" {
  name       = "grafana-agent-operator"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana-agent-operator"
  version    = "0.4.0"
  depends_on = [helm_release.cert_manager]
  timeout    = 300

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "75.2.1"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  timeout    = 600
  values     = [file("${path.root}/configs/kube-prometheus_config.yaml")]
  force_update = true
  replace      = true
  recreate_pods = true

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
    value = "10.4.2"
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
  depends_on = [helm_release.kube-prometheus, helm_release.grafana-agent-operator]
  timeout    = 300
  values     = [file("${path.root}/configs/loki_config.yaml")]
  force_update = true
  replace      = true
  recreate_pods = true

  set {
    name  = "crds.create"
    value = "true"
  }

  set {
    name  = "singleBinary.replicas"
    value = var.loki_replicas
  }

  set {
    name  = "singleBinary.resources.requests.memory"
    value = var.loki_resources_requests_memory
  }

  set {
    name  = "singleBinary.resources.requests.cpu"
    value = var.loki_resources_requests_cpu
  }

  set {
    name  = "singleBinary.resources.limits.memory"
    value = var.loki_resources_limits_memory
  }

  set {
    name  = "singleBinary.resources.limits.cpu"
    value = var.loki_resources_limits_cpu
  }

  set {
    name  = "loki.extraArgs[0]"
    value = "-config.expand-env=true"
  }

  set {
    name  = "loki.auth_enabled"
    value = "false"
  }

  set {
    name  = "loki.commonConfig.replication_factor"
    value = "1"
  }

  set {
    name  = "monitoring.serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "monitoring.serviceMonitor.interval"
    value = "30s"
  }

  set {
    name  = "monitoring.selfMonitoring.enabled"
    value = "true"
  }

  set {
    name  = "monitoring.selfMonitoring.lokiCanary.enabled"
    value = "true"
  }

  set {
    name  = "loki.useTestSchema"
    value = "true"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.datasources[0].name"
    value = "Loki"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.datasources[0].type"
    value = "loki"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.datasources[0].url"
    value = "http://loki-gateway.monitoring.svc.cluster.local"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "false"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.datasources[0].jsonData.timeout"
    value = "60"
  }

  set {
    name  = "grafana.datasources.datasources\\.yaml.datasources[0].jsonData.maxLines"
    value = "5000"
  }
}

resource "helm_release" "promtail" {
  name       = "promtail"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "6.16.0"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  depends_on = [helm_release.loki]
  timeout    = 300
  values     = [file("${path.root}/configs/promtail_config.yaml")]

  set {
    name  = "serviceMonitor.enabled"
    value = "true"
  }

  set {
    name  = "serviceMonitor.interval"
    value = "30s"
  }

  set {
    name  = "config.lokiAddress"
    value = "http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push"
  }

  set {
    name  = "config.snippets.pipelineStages[0].cri.maxPartialLines"
    value = "100"
  }
}

resource "kubernetes_config_map_v1" "grafana_dashboards" {
  metadata {
    name      = "grafana-microservices-dashboards"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "microservices-logs.json" = file("${path.root}/configs/microservices_logs_dashboard.json")
    "microservices-metrics.json" = file("${path.root}/configs/microservices_metrics_dashboard.json")
    "microservices-health.json"  = file("${path.root}/configs/microservices_health_dashboard.json")
  }

  depends_on = [helm_release.kube-prometheus]
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
          annotations:
            summary: "High CPU usage for microservice pod {{ $labels.pod }}"
            description: "Microservice pod {{ $labels.pod }} has high CPU usage (> 80%) for more than 5 minutes."

        - alert: MicroserviceHighMemoryUsage
          expr: sum(container_memory_usage_bytes{namespace="microservices"}) by (pod) / sum(container_spec_memory_limit_bytes{namespace="microservices"}) by (pod) > 0.8
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High memory usage for microservice pod {{ $labels.pod }}"
            description: "Microservice pod {{ $labels.pod }} has high memory usage (> 80%) for more than 5 minutes."

        - alert: MicroserviceHighErrorRate
          expr: sum(rate(http_requests_total{namespace="microservices", status=~"5.."}[5m])) by (service) / sum(rate(http_requests_total{namespace="microservices"}[5m])) by (service) > 0.05
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "High error rate for microservice {{ $labels.service }}"
            description: "Microservice {{ $labels.service }} has a high HTTP error rate (> 5%) for more than 5 minutes."

        - alert: MicroserviceHighLatency
          expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{namespace="microservices"}[5m])) by (service, le)) > 1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High latency for microservice {{ $labels.service }}"
            description: "Microservice {{ $labels.service }} has a 95th percentile latency of more than 1 second for more than 5 minutes."

        - alert: MicroserviceDown
          expr: up{namespace="microservices"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Microservice {{ $labels.service }} is down"
            description: "Microservice {{ $labels.service }} has been down for more than 5 minutes."
    EOT
  }

  depends_on = [helm_release.kube-prometheus]
}
