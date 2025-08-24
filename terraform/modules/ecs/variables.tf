variable "name_prefix" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "container_port" {
  type = number
}

variable "dynamodb_table_name" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "ecs_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "target_group_blue_arn" {
  type = string
}

variable "https_listener_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "project" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = ""
}

variable "container_insights_enabled" {
  type    = bool
  default = true
}

variable "task_cpu" {
  type    = string
  default = "256"
}

variable "task_memory" {
  type    = string
  default = "512"
}

variable "container_name" {
  type    = string
  default = "url-shortener"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "environment_variables" {
  type    = list(map(string))
  default = []
}

variable "secrets" {
  type    = list(map(string))
  default = []
}

variable "cloudwatch_log_group_name" {
  type    = string
  default = ""
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "platform_version" {
  type    = string
  default = "LATEST"
}

variable "health_check_grace_period" {
  type    = number
  default = 60
}

variable "ecs_security_groups" {
  type    = list(string)
  default = []
}

variable "blue_target_group_arn" {
  type    = string
  default = ""
}

variable "alb_listener_arn" {
  type    = string
  default = ""
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "ecr_repository_url" {
  type    = string
  default = ""
}