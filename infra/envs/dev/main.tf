terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  tags                 = var.tags
}

module "security" {
  source = "../../modules/security"

  name_prefix    = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
  github_repo    = var.github_repo
  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id
  tags           = var.tags
}

module "storage" {
  source = "../../modules/storage"

  name_prefix = local.name_prefix
  tags        = var.tags
}

module "container" {
  source = "../../modules/container"

  name_prefix            = local.name_prefix
  aws_account_id         = var.aws_account_id
  aws_region             = var.aws_region
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  alb_security_group_id  = module.security.alb_security_group_id
  ecs_security_group_id  = module.security.ecs_security_group_id
  ecs_task_role_arn      = module.security.ecs_task_role_arn
  ecs_execution_role_arn = module.security.ecs_execution_role_arn
  codedeploy_role_arn    = module.security.codedeploy_role_arn
  waf_web_acl_arn        = module.security.waf_web_acl_arn
  dynamodb_table_name    = module.storage.dynamodb_table_name
  container_port         = var.container_port
  health_check_path      = var.health_check_path
  tags                   = var.tags
}