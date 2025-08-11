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

module "certificate" {
  source = "../../modules/certificate"

  domain_name    = var.domain_name
  hosted_zone_id = "Z06933453Q1O5OQ901X7P"
  tags           = var.tags
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
  ecs_cluster_name       = local.name_prefix
  ecs_service_name       = local.name_prefix
  target_group_name      = "${local.name_prefix}-blue"
  certificate_arn        = module.certificate.certificate_arn
  tags                   = var.tags
}

module "dns" {
  source = "../../modules/dns"

  domain_name  = var.domain_name
  subdomain    = var.subdomain
  alb_dns_name = module.container.alb_dns_name
  alb_zone_id  = module.container.alb_zone_id
  tags         = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix        = local.name_prefix
  aws_region         = var.aws_region
  ecs_service_name   = local.name_prefix
  ecs_cluster_name   = local.name_prefix
  alb_name           = module.container.alb_name
  target_group_name  = module.container.target_group_blue_name
  tags               = var.tags
}

module "parameter_store" {
  source = "../../modules/parameter-store"

  name_prefix         = local.name_prefix
  dynamodb_table_name = module.storage.dynamodb_table_name
  tags                = var.tags
}