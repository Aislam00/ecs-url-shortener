output "alb_security_group_id" {
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  value       = aws_security_group.ecs.id
}

output "ecs_task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_execution_role_arn" {
  value       = aws_iam_role.ecs_execution_role.arn
}

output "codedeploy_role_arn" {
  value       = aws_iam_role.codedeploy_role.arn
}

output "waf_web_acl_arn" {
  value       = aws_wafv2_web_acl.main.arn
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
}