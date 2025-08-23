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
