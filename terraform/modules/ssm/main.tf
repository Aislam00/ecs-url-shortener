resource "aws_ssm_parameter" "table_name" {
  name  = "/${var.name_prefix}/dynamodb/table-name"
  type  = "SecureString"
  value = var.dynamodb_table_name
  tags  = var.tags
}

resource "aws_ssm_parameter" "app_version" {
  name  = "/${var.name_prefix}/app/version"
  type  = "SecureString"
  value = "1.0.0"
  tags  = var.tags
}
