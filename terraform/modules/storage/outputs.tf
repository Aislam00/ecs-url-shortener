output "dynamodb_table_name" {
  value = aws_dynamodb_table.urls.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.urls.arn
}

output "deployment_bucket_name" {
  description = "Name of the deployment bucket"
  value       = aws_s3_bucket.deployment_bucket.bucket
}