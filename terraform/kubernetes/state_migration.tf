removed {
  from = kubernetes_manifest.argocd_appproject_microservices

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_manifest.argocd_platform_root_application

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_manifest.argocd_microservices_appset

  lifecycle {
    destroy = false
  }
}
