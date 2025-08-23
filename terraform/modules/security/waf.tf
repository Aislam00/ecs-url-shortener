data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/wafv2/${var.name_prefix}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.waf.arn
  tags              = var.tags
}

resource "aws_kms_key" "waf" {
  description         = "KMS key for WAF logs encryption"
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
          Service = "logs.amazonaws.com"
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

resource "aws_wafv2_web_acl" "main" {
  name  = var.name_prefix
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "${var.name_prefix}-CommonRuleSetMetric"
      sampled_requests_enabled    = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            block {}
          }
          name = "Log4JRCE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "${var.name_prefix}-KnownBadInputsMetric"
      sampled_requests_enabled    = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "${var.name_prefix}-WebACL"
    sampled_requests_enabled    = true
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
}
