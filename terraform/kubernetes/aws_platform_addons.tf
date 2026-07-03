locals {
  aws_platform_enabled = var.cloud_provider == "aws" && var.enable_aws_platform_addons
  aws_load_balancer_controller_effective_role_arn = (
    var.aws_load_balancer_controller_role_arn != "" ? var.aws_load_balancer_controller_role_arn :
    try(data.terraform_remote_state.aws[0].outputs.aws_load_balancer_controller_role_arn, "")
  )
  external_secrets_effective_role_arn = (
    var.external_secrets_role_arn != "" ? var.external_secrets_role_arn :
    try(data.terraform_remote_state.aws[0].outputs.external_secrets_role_arn, "")
  )

  aws_load_balancer_controller_annotations = local.aws_load_balancer_controller_effective_role_arn != "" ? {
    "eks.amazonaws.com/role-arn" = local.aws_load_balancer_controller_effective_role_arn
  } : {}

  external_dns_annotations = var.external_dns_role_arn != "" ? {
    "eks.amazonaws.com/role-arn" = var.external_dns_role_arn
  } : {}

  external_secrets_annotations = local.external_secrets_effective_role_arn != "" ? {
    "eks.amazonaws.com/role-arn" = local.external_secrets_effective_role_arn
  } : {}

  platform_storage_class = var.cloud_provider == "aws" ? "gp3" : "managed-csi"
}

resource "kubernetes_namespace_v1" "external_dns" {
  count = local.aws_platform_enabled ? 1 : 0

  metadata {
    name = "external-dns"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "dns"
    }
  }
}

resource "kubernetes_namespace_v1" "external_secrets" {
  count = local.aws_platform_enabled ? 1 : 0

  metadata {
    name = "external-secrets"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "secrets"
    }
  }
}

resource "kubernetes_secret_v1" "cloudflare_api_token" {
  count = local.aws_platform_enabled && var.cloudflare_api_token != "" ? 1 : 0

  metadata {
    name      = var.cloudflare_api_token_secret_name
    namespace = kubernetes_namespace_v1.external_dns[0].metadata[0].name
  }

  data = {
    "api-token" = var.cloudflare_api_token
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "cert_manager_cloudflare_api_token" {
  count = local.aws_platform_enabled && var.cloudflare_api_token != "" ? 1 : 0

  metadata {
    name      = var.cloudflare_api_token_secret_name
    namespace = kubernetes_namespace_v1.nginx.metadata[0].name
  }

  data = {
    "api-token" = var.cloudflare_api_token
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "letsencrypt_cloudflare_cluster_issuer" {
  count = local.aws_platform_enabled ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-cloudflare-dns"
    }
    spec = {
      acme = {
        email  = var.lets_encrypt_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-cloudflare-dns-account-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                apiTokenSecretRef = {
                  name = var.cloudflare_api_token_secret_name
                  key  = "api-token"
                }
              }
            }
            selector = {
              dnsZones = [var.real_domain]
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret_v1.cert_manager_cloudflare_api_token,
  ]
}

resource "kubernetes_storage_class_v1" "aws_gp3" {
  count = local.aws_platform_enabled ? 1 : 0

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  count = local.aws_platform_enabled ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.2"
  namespace  = "kube-system"
  timeout    = 300

  values = [
    yamlencode({
      clusterName = local.aws_eks_cluster_name
      region      = var.aws_region

      serviceAccount = {
        create      = true
        name        = "aws-load-balancer-controller"
        annotations = local.aws_load_balancer_controller_annotations
      }

      enableServiceMutatorWebhook = false

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    })
  ]
}

resource "helm_release" "external_dns" {
  count = local.aws_platform_enabled ? 1 : 0

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.15.2"
  namespace  = kubernetes_namespace_v1.external_dns[0].metadata[0].name
  timeout    = 300

  values = [
    yamlencode({
      provider = {
        name = "cloudflare"
      }

      domainFilters = [var.real_domain]
      policy        = "sync"
      txtOwnerId    = "${var.project_name}-${var.environment}"

      env = [
        {
          name = "CF_API_TOKEN"
          valueFrom = {
            secretKeyRef = {
              name = var.cloudflare_api_token_secret_name
              key  = "api-token"
            }
          }
        }
      ]

      serviceAccount = {
        create      = true
        name        = "external-dns"
        annotations = local.external_dns_annotations
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
    })
  ]

  depends_on = [kubernetes_secret_v1.cloudflare_api_token]
}

resource "helm_release" "external_secrets" {
  count = local.aws_platform_enabled ? 1 : 0

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.10.5"
  namespace  = kubernetes_namespace_v1.external_secrets[0].metadata[0].name
  timeout    = 300

  values = [
    yamlencode({
      installCRDs = true

      serviceAccount = {
        create      = true
        name        = "external-secrets"
        annotations = local.external_secrets_annotations
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }

      webhook = {
        resources = {
          requests = {
            cpu    = "25m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
    })
  ]
}
