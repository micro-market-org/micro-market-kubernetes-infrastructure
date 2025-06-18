environment    = "dev"
cluster_issuer = "letsencrypt-production-cluster-issuer"
database       = "microservices"
azure_region   = "westeurope"

cert_manager_replicas                           = 1
cert_manager_webhook_replicas                   = 1
cert_manager_cainjector_replicas                = 1
cert_manager_resources_requests_cpu             = "100m"
cert_manager_resources_requests_memory          = "128Mi"
cert_manager_resources_limits_cpu               = "200m"
cert_manager_resources_limits_memory            = "256Mi"
cert_manager_webhook_resources_requests_cpu     = "50m"
cert_manager_webhook_resources_requests_memory  = "64Mi"
cert_manager_webhook_resources_limits_cpu       = "100m"
cert_manager_webhook_resources_limits_memory    = "128Mi"
cert_manager_cainjector_resources_requests_cpu  = "50m"
cert_manager_cainjector_resources_requests_memory = "64Mi"
cert_manager_cainjector_resources_limits_cpu    = "100m"
cert_manager_cainjector_resources_limits_memory = "128Mi"

nginx_ingress_replicas                = 1
nginx_ingress_autoscaling_enabled     = false
nginx_ingress_min_replicas            = 1
nginx_ingress_max_replicas            = 3
nginx_ingress_resources_requests_cpu  = "200m"
nginx_ingress_resources_requests_memory = "256Mi"
nginx_ingress_resources_limits_cpu    = "500m"
nginx_ingress_resources_limits_memory = "512Mi"

postgresql_architecture                           = "standalone"
postgresql_primary_storage_size                   = "10Gi"
postgresql_primary_resources_requests_memory      = "256Mi"
postgresql_primary_resources_requests_cpu         = "250m"
postgresql_primary_resources_limits_memory        = "1Gi"
postgresql_primary_resources_limits_cpu           = "1000m"
postgresql_max_connections                        = "50"
postgresql_shared_buffers                         = "64MB"
postgresql_read_replicas_count                    = "0"
postgresql_read_replicas_storage_size             = "10Gi"
postgresql_read_replicas_resources_requests_memory = "256Mi"
postgresql_read_replicas_resources_requests_cpu   = "250m"
postgresql_read_replicas_resources_limits_memory  = "1Gi"
postgresql_read_replicas_resources_limits_cpu     = "500m"

prometheus_replicas                    = 1
prometheus_resources_requests_memory   = "512Mi"
prometheus_resources_requests_cpu      = "200m"
prometheus_resources_limits_memory     = "1Gi"
prometheus_resources_limits_cpu        = "500m"
prometheus_storage_size                = "10Gi"

alertmanager_replicas                  = 1
alertmanager_resources_requests_memory = "128Mi"
alertmanager_resources_requests_cpu    = "100m"
alertmanager_resources_limits_memory   = "256Mi"
alertmanager_resources_limits_cpu      = "200m"
alertmanager_storage_size              = "2Gi"

grafana_replicas                       = 1
grafana_resources_requests_memory      = "256Mi"
grafana_resources_requests_cpu         = "100m"
grafana_resources_limits_memory        = "512Mi"
grafana_resources_limits_cpu           = "200m"
grafana_storage_size                   = "5Gi"

loki_replicas                          = 1
loki_resources_requests_memory         = "512Mi"
loki_resources_requests_cpu            = "200m"
loki_resources_limits_memory           = "1Gi"
loki_resources_limits_cpu              = "500m"
loki_storage_size                      = "10Gi"
