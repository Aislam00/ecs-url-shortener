data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "main" {}

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
            "aws:SourceArn" = "arn:aws:s3:::${var.name_prefix}-alb-logs"
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
            "aws:SourceArn" = "arn:aws:s3:::${var.name_prefix}-alb-logs-access-logs"
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
            "aws:SourceArn" = "arn:aws:s3:::${var.name_prefix}-alb-logs-replica"
          }
        }
      }
    ]
  })
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
          "arn:aws:s3:::${var.name_prefix}-alb-logs/*",
          "arn:aws:s3:::${var.name_prefix}-alb-logs-access-logs/*"
        ]
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-alb-logs",
          "arn:aws:s3:::${var.name_prefix}-alb-logs-access-logs"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect = "Allow"
        Resource = "arn:aws:s3:::${var.name_prefix}-alb-logs-replica/*"
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