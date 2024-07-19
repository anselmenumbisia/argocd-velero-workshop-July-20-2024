resource "aws_s3_bucket" "velero" {
  count = (var.enabled && var.create_bucket) ? 1 : 0

  bucket = var.bucket_name
  
  tags = {
    Name = "EKS Velero"
  }
}

resource "aws_s3_bucket_ownership_controls" "velero" {
  count = (var.create_bucket) ? 1 : 0
  bucket = aws_s3_bucket.velero[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "velero" {
  count = (var.create_bucket) ? 1 : 0
  depends_on = [aws_s3_bucket_ownership_controls.velero]
  bucket = aws_s3_bucket.velero[0].id
  acl    = "private"
}