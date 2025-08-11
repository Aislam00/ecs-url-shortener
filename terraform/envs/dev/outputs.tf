output "alb_dns_name" {
  value       = module.container.alb_dns_name
}

output "alb_zone_id" {
  value       = module.container.alb_zone_id
}

output "ecr_repository_url" {
  value       = module.container.ecr_repository_url
}

output "ecs_cluster_name" {
  value       = module.container.ecs_cluster_name
}

output "ecs_service_name" {
  value       = module.container.ecs_service_name
}

output "dynamodb_table_name" {
  value       = module.storage.dynamodb_table_name
}

output "codedeploy_app_name" {
  value       = module.container.codedeploy_app_name
}

output "codedeploy_deployment_group_name" {
  value       = module.container.codedeploy_deployment_group_name
}

output "vpc_id" {
  value       = module.vpc.vpc_id
}

output "github_actions_role_arn" {
  value       = module.security.github_actions_role_arn
}

output "dashboard_url" {
  value       = module.monitoring.dashboard_url
}