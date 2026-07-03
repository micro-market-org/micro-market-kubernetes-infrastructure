environment    = "staging"
cluster_issuer = "letsencrypt-cloudflare-dns"
database       = "microservices"
azure_region   = "westeurope"

cert_manager_replicas                             = 1
cert_manager_webhook_replicas                     = 1
cert_manager_cainjector_replicas                  = 1
cert_manager_resources_requests_cpu               = "100m"
cert_manager_resources_requests_memory            = "128Mi"
cert_manager_resources_limits_cpu                 = "200m"
cert_manager_resources_limits_memory              = "256Mi"
cert_manager_webhook_resources_requests_cpu       = "50m"
cert_manager_webhook_resources_requests_memory    = "64Mi"
cert_manager_webhook_resources_limits_cpu         = "100m"
cert_manager_webhook_resources_limits_memory      = "128Mi"
cert_manager_cainjector_resources_requests_cpu    = "50m"
cert_manager_cainjector_resources_requests_memory = "64Mi"
cert_manager_cainjector_resources_limits_cpu      = "100m"
cert_manager_cainjector_resources_limits_memory   = "128Mi"


postgresql_architecture                            = "replication"
postgresql_primary_storage_size                    = "15Gi"
postgresql_primary_resources_requests_memory       = "256Mi"
postgresql_primary_resources_requests_cpu          = "250m"
postgresql_primary_resources_limits_memory         = "1Gi"
postgresql_primary_resources_limits_cpu            = "1000m"
postgresql_max_connections                         = "100"
postgresql_shared_buffers                          = "128MB"
postgresql_read_replicas_count                     = "1"
postgresql_read_replicas_storage_size              = "15Gi"
postgresql_read_replicas_resources_requests_memory = "256Mi"
postgresql_read_replicas_resources_requests_cpu    = "250m"
postgresql_read_replicas_resources_limits_memory   = "1Gi"
postgresql_read_replicas_resources_limits_cpu      = "500m"

prometheus_replicas                  = 1
prometheus_resources_requests_memory = "512Mi"
prometheus_resources_requests_cpu    = "200m"
prometheus_resources_limits_memory   = "1Gi"
prometheus_resources_limits_cpu      = "500m"
prometheus_storage_size              = "10Gi"

alertmanager_replicas                  = 1
alertmanager_resources_requests_memory = "128Mi"
alertmanager_resources_requests_cpu    = "100m"
alertmanager_resources_limits_memory   = "256Mi"
alertmanager_resources_limits_cpu      = "200m"
alertmanager_storage_size              = "2Gi"

grafana_replicas                  = 1
grafana_resources_requests_memory = "256Mi"
grafana_resources_requests_cpu    = "100m"
grafana_resources_limits_memory   = "512Mi"
grafana_resources_limits_cpu      = "200m"
grafana_storage_size              = "5Gi"

keycloak_replicas                  = 1
keycloak_resources_requests_memory = "600Mi"
keycloak_resources_requests_cpu    = "500m"
keycloak_resources_limits_memory   = "1Gi"
keycloak_resources_limits_cpu      = "1000m"

argocd_server_replicas                           = 1
argocd_server_resources_requests_memory          = "150Mi"
argocd_server_resources_requests_cpu             = "100m"
argocd_controller_replicas                       = 1
argocd_controller_resources_requests_memory      = "150Mi"
argocd_controller_resources_requests_cpu         = "100m"
argocd_repo_server_replicas                      = 1
argocd_repo_server_resources_requests_memory     = "80Mi"
argocd_repo_server_resources_requests_cpu        = "60m"
argocd_application_set_replicas                  = 1
argocd_application_set_resources_requests_memory = "80Mi"
argocd_application_set_resources_requests_cpu    = "60m"
argocd_notifications_resources_requests_memory   = "80Mi"
argocd_notifications_resources_requests_cpu      = "60m"
argocd_redis_resources_requests_memory           = "80Mi"
argocd_redis_resources_requests_cpu              = "60m"
