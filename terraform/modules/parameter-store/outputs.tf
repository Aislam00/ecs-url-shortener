output "table_name_parameter" {
  value       = aws_ssm_parameter.table_name.name
}

output "app_version_parameter" {
  value       = aws_ssm_parameter.app_version.name
}