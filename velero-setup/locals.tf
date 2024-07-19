
locals {
  velero_default_values = {
    #"restoreOnlyMode"                                           = "false"
    #"defaultVolumesToRestic"                                    = "true"
    "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn" = aws_iam_role.kubernetes_velero[0].arn
    "configuration.backupStorageLocation.config.region" = var.aws_region
    "configuration.backupStorageLocation.bucket"                = var.bucket_name
   # "configuration.backupStorageLocation.config.resourceGroup"  = data.terraform_remote_state.mws_infra.outputs.resource_group_backup_name
    #"configuration.backupStorageLocation.config.storageAccount" = data.terraform_remote_state.mws_infra.outputs.storage_account_backup_name
    "configuration.backupStorageLocation.name"                  = var.bucket_name
    "configuration.provider"                                    = "aws"
   # "configuration.volumeSnapshotLocation.config.resourceGroup" = data.terraform_remote_state.mws_infra.outputs.resource_group_backup_name
    "configuration.volumeSnapshotLocation.name"                 = var.volume_snapshot_name
    "configuration.volumeSnapshotLocation.config.region" = var.aws_region
    "serviceAccount.server.name" = var.service_account_name
    #"credentials.existingSecret"                                = try(kubernetes_secret.velero.metadata[0].name, "")
    "credentials.useSecret"                                     = "false"
   # "deployRestic"                                              = "true"
   # "env.AZURE_CREDENTIALS_FILE"                                = "/credentials"
    "metrics.enabled"                                           = "true"
    "rbac.create"                                               = "true"
    "schedules.daily.schedule"                                  = "0 23 * * *"
   # "schedules.daily.template.includedNamespaces"               = "{${join(",", var.backup_namespaces)}}"
    "schedules.daily.template.snapshotVolumes"                  = "true"
    "schedules.daily.template.ttl"                              = "240h"
    "serviceAccount.server.create"                              = "true"
    "snapshotsEnabled"                                          = "false"
    "initContainers[0].name"                                    = "velero-plugin-for-aws"
    "initContainers[0].image"                                   = "velero/velero-plugin-for-aws:v1.8.0"
    "initContainers[0].volumeMounts[0].mountPath"               = "/target"
    "initContainers[0].volumeMounts[0].name"                    = "plugins"
    "image.repository"                                          = "velero/velero"
    "image.tag"                                                 = "v1.8.1"
    # "image.pullPolicy"                                          = "IfNotPresent"
    # "features"                                                  = "EnableCSI"
  }
}
