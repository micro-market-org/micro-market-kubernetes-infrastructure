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
    "GRAFANA_OIDC_CLIENT_SECRET" = random_password.grafana_password.result
    "DOMAIN"                     = local.current_domain
  }
}


resource "helm_release" "grafana-agent-operator" {
  name       = "grafana-agent-operator"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana-agent-operator"
  version    = "0.2.14"
  depends_on = [helm_release.cert_manager]
  timeout    = 300

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "57.1.0"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  depends_on = [helm_release.cert_manager, helm_release.grafana-agent-operator]
  timeout    = 600
  values     = [file("${path.root}/configs/kube-prometheus_config.yaml")]

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

  set_sensitive {
    name  = "grafana.envFromSecret"
    value = kubernetes_secret_v1.grafana_oauth_secret.metadata[0].name
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "5.41.5"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  depends_on = [helm_release.kube-prometheus, helm_release.grafana-agent-operator]
  timeout    = 300
  values     = [file("${path.root}/configs/loki_config.yaml")]

  set {
    name  = "crds.create"
    value = "true"
  }

  set {
    name  = "singleBinary.persistence.enabled"
    value = "true"
  }

  set {
    name  = "singleBinary.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "singleBinary.persistence.storageClassName"
    value = "managed-csi"
  }

  set {
    name  = "singleBinary.persistence.name"
    value = "storage"
  }


  set {
    name  = "loki.extraArgs"
    value = "[\"-config.expand-env=true\"]"
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
}

resource "helm_release" "promtail" {
  name       = "promtail"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "6.15.3"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  depends_on = [helm_release.loki]
  timeout    = 300
  values     = [file("${path.root}/configs/promtail_config.yaml")]
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
  }

  depends_on = [helm_release.kube-prometheus]
}
