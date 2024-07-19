# Policy
data "aws_iam_policy_document" "kubernetes_velero" {
  count = var.enabled ? 1 : 0

  statement {
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}"
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "kubernetes_velero" {
  #depends_on  = [var.mod_dependency]
  count       = var.enabled ? 1 : 0
  name        = "${var.cluster_name}-velero"
  path        = "/"
  description = "Policy for velero service"

  policy = data.aws_iam_policy_document.kubernetes_velero[0].json
}

# Role
data "aws_iam_policy_document" "kubernetes_velero_assume" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_identity_oidc_issuer_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_identity_oidc_issuer, "https://", "")}:sub"

      values = [
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "kubernetes_velero" {
  count              = var.enabled ? 1 : 0
  name               = "${var.cluster_name}-velero"
  assume_role_policy = data.aws_iam_policy_document.kubernetes_velero_assume[0].json
}

resource "aws_iam_role_policy_attachment" "kubernetes_velero" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.kubernetes_velero[0].name
  policy_arn = aws_iam_policy.kubernetes_velero[0].arn
}



# resource "kubernetes_service_account" "velero" {
#   count = var.enabled ? 1 : 0

#   metadata {
#     name      = "velero"
#     namespace = var.namespace
#     annotations = {
#       # This annotation is only used when running on EKS which can
#       # use IAM roles for service accounts.
#       "eks.amazonaws.com/role-arn" = aws_iam_role.kubernetes_velero[0].arn
#     }

#     labels = {
#       "app.kubernetes.io/name"       = "velero"
#       "app.kubernetes.io/component"  = "controller"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }
# }


# resource "kubernetes_role" "velero" {
#     count      = var.enabled ? 1 : 0
#   metadata {
#     name = "velero"

#     labels = {
#       "app.kubernetes.io/name"       = "velero"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   rule {
#     api_groups = [
#       "velero.io"
#     ]

#     resources = [
#       "*"
#     ]

#     verbs = [
#       "*"
#     ]
#   }
# }

# resource "kubernetes_role_binding" "velero" {
#     count      = var.enabled ? 1 : 0
#   metadata {
#     name = "velero"
#     namespace = var.namespace

#     labels = {
#       "app.kubernetes.io/name"       = "velero"
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_role.velero[0].metadata[0].name
#   }

#   subject {
#     api_group = ""
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.velero[0].metadata[0].name
#     namespace = kubernetes_service_account.velero[0].metadata[0].namespace
#   }
# }