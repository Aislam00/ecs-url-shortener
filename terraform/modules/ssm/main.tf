resource "aws_kms_key" "ssm" {
  description         = "KMS key for SSM parameter encryption"
  enable_key_rotation = true
  tags                = var.tags
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
