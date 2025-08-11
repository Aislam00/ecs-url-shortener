variable "name_prefix" {
  type        = string
}

variable "aws_account_id" {
  type        = string
}

variable "aws_region" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "private_subnet_ids" {
  type        = list(string)
}

variable "public_subnet_ids" {
  type        = list(string)
}

variable "alb_security_group_id" {
  type        = string
}

variable "ecs_security_group_id" {
  type        = string
}

variable "ecs_task_role_arn" {
  type        = string
}

variable "ecs_execution_role_arn" {
  type        = string
}

variable "codedeploy_role_arn" {
  type        = string
}

variable "waf_web_acl_arn" {
  type        = string
}

variable "dynamodb_table_name" {
  type        = string
}

variable "container_port" {
  type        = number
}

variable "health_check_path" {
  type        = string
}

variable "tags" {
  type        = map(string)
}

variable "ecs_cluster_name" {
  type        = string
}

variable "ecs_service_name" {
  type        = string
}

variable "target_group_name" {
  type        = string
}

variable "certificate_arn" {
  type        = string
}