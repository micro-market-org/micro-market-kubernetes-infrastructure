locals {
  argocd_domain = local.current_domain
}

resource "random_password" "argo_password" {
  length      = 16
  special     = true
  min_special = 2
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "random_password" "argo_oidc_client_secret" {
  length      = 16
  special     = true
  min_special = 2
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "random_password" "argo_redis_password" {
  length      = 16
  special     = true
  min_special = 2
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "argocd"
    }
  }
}


resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.0.15"
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  depends_on = [helm_release.cert_manager]
  create_namespace = false
  values = [
    templatefile("${path.root}/configs/argocd_config.yaml", {
      ARGOCD_URL      = "https://${local.argocd_domain}/argocd",
      KEYCLOAK_ISSUER = "https://${local.argocd_domain}/auth/realms/microservices",
      DOMAIN          = local.argocd_domain,
    })
  ]
  timeout = 200

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = random_password.argo_password.result
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
    value = "https://gitlab.com/microservices1691715"
  }

  set_sensitive {
    name  = "configs.secret.extra.argo-oidc-client-secret"
    value = random_password.argo_oidc_client_secret.result
  }

  set_sensitive {
    name  = "redis.password"
    value = random_password.argo_redis_password.result
  }

  set {
    name  = "redis.secretName"
    value = "argocd-redis"
  }
}
