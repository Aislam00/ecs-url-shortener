variable "name_prefix" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "container_port" {
  type        = number
}

variable "tags" {
  type        = map(string)
}

variable "github_repo" {
  type        = string
}

variable "aws_region" {
  type        = string
}

variable "aws_account_id" {
  type        = string
}