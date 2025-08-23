resource "aws_s3_bucket" "deployment_bucket" {
  bucket        = "${var.name_prefix}-deployments"
  force_destroy = true
  
  tags = var.tags
}

resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.name_prefix}-deployment-access-logs"
  force_destroy = true
  
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "deployment_bucket" {
  description         = "KMS key for deployment bucket encryption"
  enable_key_rotation = true
}

resource "aws_kms_alias" "deployment_bucket" {
  name          = "alias/${var.name_prefix}-deployment-bucket"
  target_key_id = aws_kms_key.deployment_bucket.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.deployment_bucket.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "deployment-bucket-logs/"
}

resource "aws_s3_bucket_public_access_block" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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