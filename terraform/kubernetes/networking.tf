resource "kubernetes_namespace_v1" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.17.2"
  namespace        = kubernetes_namespace_v1.nginx.metadata[0].name
  create_namespace = true
  timeout          = 300

  values = [
    yamlencode({
      installCRDs  = true
      replicaCount = var.cert_manager_replicas

      webhook = {
        replicaCount = var.cert_manager_webhook_replicas
        securePort   = 10250
        hostNetwork  = false
        securityContext = {
          enabled = true
        }
        extraArgs      = ["--v=5"]
        timeoutSeconds = 30
        resources = {
          requests = {
            cpu    = var.cert_manager_webhook_resources_requests_cpu
            memory = var.cert_manager_webhook_resources_requests_memory
          }
          limits = {
            cpu    = var.cert_manager_webhook_resources_limits_cpu
            memory = var.cert_manager_webhook_resources_limits_memory
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [
                      {
                        key      = "app.kubernetes.io/name"
                        operator = "In"
                        values   = ["webhook"]
                      }
                    ]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
      }

      cainjector = {
        replicaCount = var.cert_manager_cainjector_replicas
        enabled      = true
        resources = {
          requests = {
            cpu    = var.cert_manager_cainjector_resources_requests_cpu
            memory = var.cert_manager_cainjector_resources_requests_memory
          }
          limits = {
            cpu    = var.cert_manager_cainjector_resources_limits_cpu
            memory = var.cert_manager_cainjector_resources_limits_memory
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [
                      {
                        key      = "app.kubernetes.io/name"
                        operator = "In"
                        values   = ["cainjector"]
                      }
                    ]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
      }

      startupapicheck = {
        timeout = "5m"
        enabled = false
      }

      ingressShim = {
        defaultIssuerName = var.cluster_issuer
        defaultIssuerKind = "ClusterIssuer"
      }

      prometheus = {
        enabled = true
        servicemonitor = {
          enabled            = true
          prometheusInstance = "kube-prometheus-stack"
          interval           = "30s"
          scrapeTimeout      = "10s"
        }
      }

      resources = {
        requests = {
          cpu    = var.cert_manager_resources_requests_cpu
          memory = var.cert_manager_resources_requests_memory
        }
        limits = {
          cpu    = var.cert_manager_resources_limits_cpu
          memory = var.cert_manager_resources_limits_memory
        }
      }

      affinity = {
        podAntiAffinity = {
          preferredDuringSchedulingIgnoredDuringExecution = [
            {
              weight = 100
              podAffinityTerm = {
                labelSelector = {
                  matchExpressions = [
                    {
                      key      = "app.kubernetes.io/name"
                      operator = "In"
                      values   = ["cert-manager"]
                    }
                  ]
                }
                topologyKey = "kubernetes.io/hostname"
              }
            }
          ]
        }
      }

      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/path"   = "/metrics"
        "prometheus.io/port"   = "9402"
      }
    })
  ]
}

resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = kubernetes_namespace_v1.nginx.metadata[0].name
  chart      = "ingress-nginx"
  version    = "4.12.2"

  values = [
    yamlencode({
      controller = {
        replicaCount = var.nginx_ingress_replicas
        autoscaling = {
          enabled                           = var.nginx_ingress_autoscaling_enabled
          minReplicas                       = var.nginx_ingress_min_replicas
          maxReplicas                       = var.nginx_ingress_max_replicas
          targetCPUUtilizationPercentage    = 80
          targetMemoryUtilizationPercentage = 80
        }
        admissionWebhooks = {
          certManager = {
            enabled = true
          }
        }
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
        service = {
          externalTrafficPolicy = "Local"
          annotations = {
            "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = var.cloud_provider == "azure" ? "/healthz" : null
            "service.beta.kubernetes.io/aws-load-balancer-type"                        = var.cloud_provider == "aws" ? "external" : null
            "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"             = var.cloud_provider == "aws" ? "ip" : null
            "service.beta.kubernetes.io/aws-load-balancer-scheme"                      = var.cloud_provider == "aws" ? "internet-facing" : null
            "cloud.google.com/neg"                                                     = var.cloud_provider == "gcp" ? "{\"ingress\": true}" : null
            "cloud.google.com/load-balancer-type"                                      = var.cloud_provider == "gcp" ? "External" : null
          }
        }
        allowSnippetAnnotations = false
        config = {
          "enable-real-ip"                 = "true"
          "proxy-body-size"                = "20m"
          "ssl-protocols"                  = "TLSv1.2 TLSv1.3"
          "ssl-ciphers"                    = "HIGH:!aNULL:!MD5"
          "hsts"                           = "true"
          "hsts-max-age"                   = "31536000"
          "hsts-include-subdomains"        = "true"
          "keep-alive"                     = "75"
          "keep-alive-requests"            = "100"
          "upstream-keepalive-connections" = "200"
          "upstream-keepalive-timeout"     = "60"
          "use-forwarded-headers"          = "true"
        }
        resources = {
          requests = {
            cpu    = var.nginx_ingress_resources_requests_cpu
            memory = var.nginx_ingress_resources_requests_memory
          }
          limits = {
            cpu    = var.nginx_ingress_resources_limits_cpu
            memory = var.nginx_ingress_resources_limits_memory
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [
                      {
                        key      = "app.kubernetes.io/name"
                        operator = "In"
                        values   = ["ingress-nginx"]
                      }
                    ]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.cert_manager, helm_release.aws_load_balancer_controller]
}

resource "kubernetes_ingress_v1" "ingress_grafana" {
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer"                    = var.cluster_issuer
      "kubernetes.io/ingress.class"                       = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size"       = "20m"
      "nginx.ingress.kubernetes.io/force-ssl-redirect"    = "true"
      "nginx.ingress.kubernetes.io/ssl-redirect"          = "true"
      "nginx.ingress.kubernetes.io/backend-protocol"      = "HTTP"
      "nginx.ingress.kubernetes.io/use-forwarded-headers" = "true"
    }
  }
  depends_on = [helm_release.nginx-ingress, helm_release.cert_manager, helm_release.kube-prometheus]

  spec {
    tls {
      hosts       = [local.current_domain]
      secret_name = "tls-secret-monitoring"
    }

    rule {
      host = local.current_domain
      http {
        path {
          path_type = "Prefix"
          path      = "/grafana"
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
