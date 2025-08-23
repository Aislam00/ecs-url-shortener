resource "aws_s3_bucket" "deployment_bucket" {
  bucket        = "${var.name_prefix}-deployments"
  force_destroy = true
  
  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  rule {
    id     = "cleanup_old_deployments"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
