data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ssm" {
  description         = "KMS key for SSM parameter encryption"
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

resource "aws_kms_alias" "ssm" {
  name          = "alias/${var.name_prefix}-ssm"
  target_key_id = aws_kms_key.ssm.key_id
}

resource "aws_ssm_parameter" "table_name" {
  name   = "/${var.name_prefix}/dynamodb/table-name"
  type   = "SecureString"
  value  = var.dynamodb_table_name
  key_id = aws_kms_key.ssm.arn
  tags   = var.tags
}

resource "aws_ssm_parameter" "app_version" {
  name   = "/${var.name_prefix}/app/version"
  type   = "SecureString"
  value  = "1.0.0"
  key_id = aws_kms_key.ssm.arn
  tags   = var.tags
}
