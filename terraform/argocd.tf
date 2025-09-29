resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "8.2.0"
  namespace  = "argocd"
  timeout    = "1200"
  values     = [templatefile("../argocd/install.yaml", {})]
}

resource "kubectl_manifest" "app_of_apps_infra" {
  yaml_body   = file("../gitops/app-of-apps.yaml")
  depends_on = [helm_release.argocd]
}
