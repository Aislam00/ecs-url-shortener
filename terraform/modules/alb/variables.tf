variable "name_prefix" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "waf_web_acl_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}
