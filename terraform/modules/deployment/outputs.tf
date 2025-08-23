output "deployment_bucket_name" {
  description = "Name of the deployment S3 bucket"
  value       = aws_s3_bucket.deployment_bucket.bucket
}

output "deployment_bucket_arn" {
  description = "ARN of the deployment S3 bucket"
  value       = aws_s3_bucket.deployment_bucket.arn
}
