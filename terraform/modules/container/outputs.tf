output "alb_dns_name" {
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value       = aws_lb.main.zone_id
}

output "alb_name" {
  value       = aws_lb.main.name
}

output "target_group_blue_name" {
  value       = aws_lb_target_group.blue.name
}

output "target_group_green_name" {
  value       = aws_lb_target_group.green.name
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value       = aws_ecs_service.app.name
}

output "codedeploy_app_name" {
  value       = aws_codedeploy_app.app.name
}

output "codedeploy_deployment_group_name" {
  value       = aws_codedeploy_deployment_group.app.deployment_group_name
}