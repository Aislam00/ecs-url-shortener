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
