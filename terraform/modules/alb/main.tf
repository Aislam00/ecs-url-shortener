data "aws_caller_identity" "current" {}

resource "aws_kms_key" "alb_logs" {
  description         = "KMS key for ALB logs encryption"
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
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.name_prefix}-alb-logs"
  force_destroy = true
}

resource "aws_s3_bucket" "alb_logs_access_logs" {
  bucket        = "${var.name_prefix}-alb-logs-access-logs"
  force_destroy = true
}

resource "aws_s3_bucket" "alb_logs_replica" {
  bucket        = "${var.name_prefix}-alb-logs-replica"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "alb_logs_access_logs" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "alb_logs_replica" {
  bucket = aws_s3_bucket.alb_logs_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.alb_logs.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_access_logs" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.alb_logs.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_replica" {
  bucket = aws_s3_bucket.alb_logs_replica.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.alb_logs.arn
    }
  }
}

resource "aws_s3_bucket_notification" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  topic {
    topic_arn = aws_sns_topic.alb_logs_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.alb_logs_notifications]
}

resource "aws_s3_bucket_notification" "alb_logs_access_logs" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  topic {
    topic_arn = aws_sns_topic.alb_logs_access_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.alb_logs_access_notifications]
}

resource "aws_s3_bucket_notification" "alb_logs_replica" {
  bucket = aws_s3_bucket.alb_logs_replica.id

  topic {
    topic_arn = aws_sns_topic.alb_logs_replica_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.alb_logs_replica_notifications]
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "alb_logs_access_logs" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "alb_logs_replica" {
  bucket = aws_s3_bucket.alb_logs_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    filter {
      prefix = ""
    }
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 30
    }
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_access_logs" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  rule {
    filter {
      prefix = ""
    }
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 30
    }
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_replica" {
  bucket = aws_s3_bucket.alb_logs_replica.id

  rule {
    filter {
      prefix = ""
    }
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 30
    }
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  target_bucket = aws_s3_bucket.alb_logs_access_logs.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_logging" "alb_logs_replica" {
  bucket = aws_s3_bucket.alb_logs_replica.id

  target_bucket = aws_s3_bucket.alb_logs_access_logs.id
  target_prefix = "replica-log/"
}

resource "aws_s3_bucket_replication_configuration" "alb_logs" {
  role   = aws_iam_role.alb_logs_replication.arn
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    filter {
      prefix = ""
    }
    id     = "replicate_all"
    status = "Enabled"

    delete_marker_replication {
      status = "Enabled"
    }
    destination {
      bucket        = aws_s3_bucket.alb_logs_replica.arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [aws_s3_bucket_versioning.alb_logs]
}

resource "aws_s3_bucket_replication_configuration" "alb_logs_access_logs" {
  role   = aws_iam_role.alb_logs_replication.arn
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  rule {
    filter {
      prefix = ""
    }
    id     = "replicate_all"
    status = "Enabled"

    delete_marker_replication {
      status = "Enabled"
    }
    destination {
      bucket        = aws_s3_bucket.alb_logs_replica.arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [aws_s3_bucket_versioning.alb_logs_access_logs]
}

resource "aws_iam_role" "alb_logs_replication" {
  name_prefix = "${var.name_prefix}-replication-"

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

resource "aws_iam_role_policy" "alb_logs_replication" {
  name_prefix = "${var.name_prefix}-replication-"
  role        = aws_iam_role.alb_logs_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.alb_logs.arn}/*",
          "${aws_s3_bucket.alb_logs_access_logs.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          aws_s3_bucket.alb_logs_access_logs.arn
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.alb_logs_replica.arn}/*"
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

# SNS Topics for S3 notifications
resource "aws_kms_key" "sns" {
  description         = "KMS key for SNS topics encryption"
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
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_sns_topic" "alb_logs_notifications" {
  name              = "${var.name_prefix}-alb-logs-notifications"
  kms_master_key_id = aws_kms_key.sns.arn
  tags              = var.tags
}

resource "aws_sns_topic" "alb_logs_access_notifications" {
  name              = "${var.name_prefix}-alb-access-notifications"
  kms_master_key_id = aws_kms_key.sns.arn
  tags              = var.tags
}

resource "aws_sns_topic" "alb_logs_replica_notifications" {
  name              = "${var.name_prefix}-alb-replica-notifications"
  kms_master_key_id = aws_kms_key.sns.arn
  tags              = var.tags
}

resource "aws_sns_topic_policy" "alb_logs_notifications" {
  arn = aws_sns_topic.alb_logs_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alb_logs_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_s3_bucket.alb_logs.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_policy" "alb_logs_access_notifications" {
  arn = aws_sns_topic.alb_logs_access_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alb_logs_access_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_s3_bucket.alb_logs_access_logs.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_policy" "alb_logs_replica_notifications" {
  arn = aws_sns_topic.alb_logs_replica_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alb_logs_replica_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_s3_bucket.alb_logs_replica.arn
          }
        }
      }
    ]
  })
}

resource "aws_lb" "main" {
  name               = var.name_prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    enabled = false
  }

  tags = var.tags
}

resource "aws_lb_target_group" "blue" {
  name        = "${var.name_prefix}-blue"
  port        = var.container_port
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb_target_group" "green" {
  name        = "${var.name_prefix}-green"
  port        = var.container_port
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}