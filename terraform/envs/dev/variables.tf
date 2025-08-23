variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "subdomain" {
  type    = string
  default = "url"
}
