# resource "helm_release" "velero" {
#   count      = var.enabled ? 1 : 0
#   depends_on = [ kubernetes_namespace.velero ]
#   name       = "velero"
#   chart      = "velero"
#   repository = "https://vmware-tanzu.github.io/helm-charts/"
#   namespace  = var.namespace
#   version    = "5.0.2"

#   dynamic "set" {
#     for_each = local.velero_default_values
#     iterator = setting
#     content {
#       name  = setting.key
#       value = setting.value
#     }
#   }

# }


resource "helm_release" "velero" {
  depends_on = [ kubernetes_namespace.velero]
  count      = var.enabled ? 1 : 0
  name       = var.helm_chart_name
  chart      = var.helm_chart_release_name
  repository = var.helm_chart_repo
  version    = var.helm_chart_version
  namespace  = var.namespace

  set {
    name  = "credentials.useSecret"
    value = false
  }

   set {
    name  = "serviceAccount.server.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.server.name"
    value = var.service_account_name
  }

  set {
    name  = "securityContext.fsGroup"
    value = 65534
  }

  set {
    name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.kubernetes_velero[0].arn
  }

  set {
    name  = "configuration.provider"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = var.create_bucket ? aws_s3_bucket.velero[0].id : var.bucket_name
  }

  set {
    name  = "configuration.backupStorageLocation.config.region"
    value = var.aws_region
  }

  set {
    name  = "configuration.volumeSnapshotLocation.name"
    value = var.volume_snapshot_name
  }

  set {
    name  = "configuration.volumeSnapshotLocation.config.region"
    value = var.aws_region
  }

  set {
    name  = "image.repository"
    value = "velero/velero"
  }

  set {
    name  = "image.tag"
    value = "v1.8.1"
  }

  # set {
  #   name  = "schedules.daily.schedule"
  #   value = "0 23 * * *"
  # }

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }

  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1..0"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }

  values = [
    yamlencode(var.settings)
  ]

}