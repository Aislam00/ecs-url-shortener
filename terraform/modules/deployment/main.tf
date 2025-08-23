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

resource "aws_s3_bucket" "deployment_replica" {
  bucket        = "${var.name_prefix}-deployments-replica"
  force_destroy = true
  
  tags = var.tags
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "deployment_bucket" {
  description         = "KMS key for deployment bucket encryption"
  enable_key_rotation = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SNS Service"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "deployment_bucket" {
  name          = "alias/${var.name_prefix}-deployment-bucket"
  target_key_id = aws_kms_key.deployment_bucket.key_id
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

resource "aws_s3_bucket_versioning" "deployment_replica" {
  bucket = aws_s3_bucket.deployment_replica.id
  versioning_configuration {
    status = "Enabled"
  }
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
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.deployment_bucket.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment_replica" {
  bucket = aws_s3_bucket.deployment_replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.deployment_bucket.arn
    }
  }
}

resource "aws_s3_bucket_logging" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "deployment-bucket-logs/"
}

resource "aws_s3_bucket_logging" "deployment_replica" {
  bucket = aws_s3_bucket.deployment_replica.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "replica-bucket-logs/"
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

resource "aws_s3_bucket_public_access_block" "deployment_replica" {
  bucket = aws_s3_bucket.deployment_replica.id

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

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "cleanup_old_logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_sns_topic" "s3_notifications" {
  name_prefix = "${var.name_prefix}-s3-notifications-"
  
  kms_master_key_id = aws_kms_key.deployment_bucket.arn
}

resource "aws_sns_topic_policy" "s3_notifications" {
  arn = aws_sns_topic.s3_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.s3_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "deployment_bucket" {
  bucket = aws_s3_bucket.deployment_bucket.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_s3_bucket_notification" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "deployment_replica" {
  bucket = aws_s3_bucket.deployment_replica.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_iam_role" "replication" {
  name_prefix = "${var.name_prefix}-s3-replication-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "replication" {
  name_prefix = "${var.name_prefix}-s3-replication-"
  role        = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.deployment_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.deployment_bucket.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.deployment_replica.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "deployment_bucket" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.deployment_bucket.id

  rule {
    id     = "replication_rule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.deployment_replica.arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.deployment_bucket,
    aws_s3_bucket_versioning.deployment_replica
  ]
}