output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.container.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.container.alb_zone_id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.container.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.container.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.container.ecs_service_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.storage.dynamodb_table_name
}

output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = module.container.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = module.container.codedeploy_deployment_group_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = module.security.github_actions_role_arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}