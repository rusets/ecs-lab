# Create namespace first (if you don't already)
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
    labels = {
      "app.kubernetes.io/name" = "external-secrets"
    }
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.10.5" # <- при необходимости скорректируй версию под свой кластер

  # Вместо множества set{...} используем values + yamlencode.
  # Это надежно для ключей вида serviceAccount.annotations."eks.amazonaws.com/role-arn"
  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = true
        name   = "external-secrets"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.eso_irsa_role_arn
        }
      }
      # Пример дополнительных опций:
      # metrics = { service = { enabled = true } }
    })
  ]

  # Ждем, пока создастся namespace
  depends_on = [kubernetes_namespace.external_secrets]
}