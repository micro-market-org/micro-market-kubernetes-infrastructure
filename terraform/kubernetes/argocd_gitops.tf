locals {
  gitops_image_namespace = var.container_image_namespace != "" ? var.container_image_namespace : var.project_name

  gitops_aws_ecr_repository_urls = (
    var.cloud_provider == "aws" ? try(data.terraform_remote_state.aws[0].outputs.ecr_repository_urls, {}) : {}
  )

  gitops_applications = [
    for app in var.gitops_applications : merge(app, {
      env      = var.environment
      provider = var.cloud_provider
      domain   = local.current_domain
      imageRepository = lookup(
        local.gitops_aws_ecr_repository_urls,
        app.name,
        var.container_registry != "" ? "${var.container_registry}/${local.gitops_image_namespace}/${app.name}" : "${local.gitops_image_namespace}/${app.name}"
      )
    })
  ]
}

resource "kubernetes_manifest" "argocd_microservices_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "microservices"
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
      finalizers = [
        "resources-finalizer.argocd.argoproj.io/finalizer"
      ]
    }
    spec = {
      description = "Microservices Project"
      sourceRepos = [
        var.argocd_deployment_repo_url
      ]
      destinations = [
        {
          namespace = kubernetes_namespace_v1.microservices.metadata[0].name
          server    = "https://kubernetes.default.svc"
        }
      ]
      clusterResourceWhitelist = [
        {
          group = ""
          kind  = "Namespace"
        }
      ]
      namespaceResourceWhitelist = [
        {
          group = ""
          kind  = "ConfigMap"
        },
        {
          group = ""
          kind  = "Secret"
        },
        {
          group = ""
          kind  = "Service"
        },
        {
          group = ""
          kind  = "ServiceAccount"
        },
        {
          group = "apps"
          kind  = "Deployment"
        },
        {
          group = "autoscaling"
          kind  = "HorizontalPodAutoscaler"
        },
        {
          group = "networking.k8s.io"
          kind  = "Ingress"
        },
        {
          group = "networking.k8s.io"
          kind  = "NetworkPolicy"
        },
        {
          group = "policy"
          kind  = "PodDisruptionBudget"
        },
        {
          group = "external-secrets.io"
          kind  = "ExternalSecret"
        }
      ]
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "argocd_microservices_applicationset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "microservices"
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    }
    spec = {
      generators = [
        {
          list = {
            elements = local.gitops_applications
          }
        }
      ]
      template = {
        metadata = {
          name      = "{{name}}"
          namespace = kubernetes_namespace_v1.argocd.metadata[0].name
          labels = {
            environment = "{{env}}"
            provider    = "{{provider}}"
          }
        }
        spec = {
          project = "microservices"
          source = {
            repoURL        = var.argocd_deployment_repo_url
            targetRevision = "HEAD"
            path           = "{{path}}"
            helm = {
              valueFiles = [
                "values.yaml",
                "environments/{{env}}-values.yaml"
              ]
              parameters = [
                {
                  name  = "global.environment"
                  value = "{{env}}"
                },
                {
                  name  = "image.repository"
                  value = "{{imageRepository}}"
                },
                {
                  name  = "global.domain"
                  value = "{{domain}}"
                },
                {
                  name  = "ingress.hosts[0].host"
                  value = "{{domain}}"
                },
                {
                  name  = "ingress.tls[0].hosts[0]"
                  value = "{{domain}}"
                },
                {
                  name  = "configMaps.micro-market-frontend-config.data.NEXT_PUBLIC_KEYCLOAK_URL"
                  value = "https://{{domain}}/auth"
                },
                {
                  name  = "configMaps.micro-market-frontend-config.data.NEXT_PUBLIC_API_URL"
                  value = "https://{{domain}}"
                }
              ]
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = kubernetes_namespace_v1.microservices.metadata[0].name
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true"
            ]
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_manifest.argocd_microservices_project
  ]
}
