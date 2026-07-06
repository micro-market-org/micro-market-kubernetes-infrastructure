locals {
  argocd_domain = local.current_domain
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "environment"                        = var.environment
      "app.kubernetes.io/part-of"          = "argocd"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}


resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.0.15"
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  create_namespace = false
  values = [
    templatefile("${path.root}/configs/argocd_config.yaml.template", {
      ARGOCD_URL                      = "https://${local.argocd_domain}/argocd",
      KEYCLOAK_ISSUER                 = "https://${local.auth_domain}/auth/realms/microservices",
      DOMAIN                          = local.argocd_domain,
      CLUSTER_ISSUER                  = var.cluster_issuer,
      ARGOCD_SERVER_REPLICAS          = var.argocd_server_replicas,
      ARGOCD_SERVER_CPU               = var.argocd_server_resources_requests_cpu,
      ARGOCD_SERVER_MEMORY            = var.argocd_server_resources_requests_memory,
      ARGOCD_CONTROLLER_REPLICAS      = var.argocd_controller_replicas,
      ARGOCD_CONTROLLER_CPU           = var.argocd_controller_resources_requests_cpu,
      ARGOCD_CONTROLLER_MEMORY        = var.argocd_controller_resources_requests_memory,
      ARGOCD_REPO_SERVER_REPLICAS     = var.argocd_repo_server_replicas,
      ARGOCD_REPO_SERVER_CPU          = var.argocd_repo_server_resources_requests_cpu,
      ARGOCD_REPO_SERVER_MEMORY       = var.argocd_repo_server_resources_requests_memory,
      ARGOCD_APPLICATION_SET_REPLICAS = var.argocd_application_set_replicas,
      ARGOCD_APPLICATION_SET_CPU      = var.argocd_application_set_resources_requests_cpu,
      ARGOCD_APPLICATION_SET_MEMORY   = var.argocd_application_set_resources_requests_memory,
      ARGOCD_NOTIFICATIONS_CPU        = var.argocd_notifications_resources_requests_cpu,
      ARGOCD_NOTIFICATIONS_MEMORY     = var.argocd_notifications_resources_requests_memory,
      ARGOCD_REDIS_CPU                = var.argocd_redis_resources_requests_cpu,
      ARGOCD_REDIS_MEMORY             = var.argocd_redis_resources_requests_memory
    })
  ]
  timeout = 200

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = local.argocd_admin_password
  }

  set {
    name  = "configs.secret.createSecret"
    value = "true"
  }

  set_sensitive {
    name  = "configs.credentialTemplates.https-creds.password"
    value = var.gitlab_token
  }

  set {
    name  = "configs.credentialTemplates.https-creds.username"
    value = var.gitlab_username
  }

  set {
    name  = "configs.credentialTemplates.https-creds.url"
    value = trimsuffix(var.argocd_deployment_repo_url, "/deployment.git")
  }

  set_sensitive {
    name  = "configs.credentialTemplates.platform-gitops.password"
    value = var.gitlab_token
  }

  set {
    name  = "configs.credentialTemplates.platform-gitops.username"
    value = var.gitlab_username
  }

  set {
    name  = "configs.credentialTemplates.platform-gitops.url"
    value = trimsuffix(var.argocd_platform_repo_url, "/platform-gitops.git")
  }

  set_sensitive {
    name  = "configs.secret.extra.argo-oidc-client-secret"
    value = local.argocd_oidc_client_secret
  }

  set_sensitive {
    name  = "redis.password"
    value = local.argocd_redis_password
  }

  set {
    name  = "redis.secretName"
    value = "argocd-redis"
  }
}
