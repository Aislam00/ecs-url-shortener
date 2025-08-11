output "table_name_parameter" {
  description = "Parameter Store name for table name"
  value       = aws_ssm_parameter.table_name.name
}

output "app_version_parameter" {
  description = "Parameter Store name for app version"
  value       = aws_ssm_parameter.app_version.name
}