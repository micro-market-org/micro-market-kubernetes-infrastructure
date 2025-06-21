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
nginx_ingress_resources_requests_memory = "192Mi"
nginx_ingress_resources_limits_cpu    = "500m"
nginx_ingress_resources_limits_memory = "384Mi"

postgresql_architecture                           = "standalone"
postgresql_primary_storage_size                   = "10Gi"
postgresql_primary_resources_requests_memory      = "192Mi"
postgresql_primary_resources_requests_cpu         = "250m"
postgresql_primary_resources_limits_memory        = "512Mi"
postgresql_primary_resources_limits_cpu           = "500m"
postgresql_max_connections                        = "50"
postgresql_shared_buffers                         = "64MB"
postgresql_read_replicas_count                    = "0"
postgresql_read_replicas_storage_size             = "10Gi"
postgresql_read_replicas_resources_requests_memory = "192Mi"
postgresql_read_replicas_resources_requests_cpu   = "250m"
postgresql_read_replicas_resources_limits_memory  = "512Mi"
postgresql_read_replicas_resources_limits_cpu     = "500m"

prometheus_replicas                    = 1
prometheus_resources_requests_memory   = "192Mi"
prometheus_resources_requests_cpu      = "200m"
prometheus_resources_limits_memory     = "384Mi"
prometheus_resources_limits_cpu        = "500m"
prometheus_storage_size                = "10Gi"

alertmanager_replicas                  = 1
alertmanager_resources_requests_memory = "128Mi"
alertmanager_resources_requests_cpu    = "100m"
alertmanager_resources_limits_memory   = "256Mi"
alertmanager_resources_limits_cpu      = "200m"
alertmanager_storage_size              = "2Gi"

grafana_replicas                       = 1
grafana_resources_requests_memory      = "192Mi"
grafana_resources_requests_cpu         = "100m"
grafana_resources_limits_memory        = "384Mi"
grafana_resources_limits_cpu           = "200m"
grafana_storage_size                   = "5Gi"

loki_replicas                          = 1
loki_resources_requests_memory         = "192Mi"
loki_resources_requests_cpu            = "200m"
loki_resources_limits_memory           = "384Mi"
loki_resources_limits_cpu              = "500m"
loki_storage_size                      = "10Gi"

keycloak_replicas                      = 1
keycloak_resources_requests_memory     = "192Mi"
keycloak_resources_requests_cpu        = "200m"
keycloak_resources_limits_memory       = "768Mi"
keycloak_resources_limits_cpu          = "600m"

argocd_server_replicas                 = 1
argocd_server_resources_requests_memory = "100Mi"
argocd_server_resources_requests_cpu   = "80m"
argocd_controller_replicas             = 1
argocd_controller_resources_requests_memory = "100Mi"
argocd_controller_resources_requests_cpu = "80m"
argocd_repo_server_replicas            = 1
argocd_repo_server_resources_requests_memory = "50Mi"
argocd_repo_server_resources_requests_cpu = "40m"
argocd_application_set_replicas        = 1
argocd_application_set_resources_requests_memory = "50Mi"
argocd_application_set_resources_requests_cpu = "40m"
argocd_notifications_resources_requests_memory = "50Mi"
argocd_notifications_resources_requests_cpu = "40m"
argocd_redis_resources_requests_memory = "50Mi"
argocd_redis_resources_requests_cpu    = "40m"

grafana_agent_operator_resources_requests_memory = "100Mi"
grafana_agent_operator_resources_requests_cpu = "80m"
grafana_agent_operator_resources_limits_memory = "200Mi"
grafana_agent_operator_resources_limits_cpu = "160m"

postgresql_metrics_resources_requests_memory = "25Mi"
postgresql_metrics_resources_requests_cpu = "40m"
postgresql_metrics_resources_limits_memory = "50Mi"
postgresql_metrics_resources_limits_cpu = "80m"
