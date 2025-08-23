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

data "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  aws_region           = var.aws_region
  tags                 = var.tags
}

module "security" {
  source = "../../modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  container_port    = var.container_port
  github_repo       = var.github_repo
  aws_region        = var.aws_region
  aws_account_id    = var.aws_account_id
  public_subnet_ids = module.vpc.public_subnet_ids
  tags              = var.tags
}
  source = "../../modules/security"

  name_prefix    = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
  github_repo    = var.github_repo
  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id
  tags           = var.tags
}

module "certificate" {
  count  = var.domain_name != "" ? 1 : 0
  source = "../../modules/certificate"

  domain_name    = var.domain_name
  hosted_zone_id = data.aws_route53_zone.main[0].zone_id
  tags           = var.tags
}

module "storage" {
  source = "../../modules/storage"

  name_prefix = local.name_prefix
  tags        = var.tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix = local.name_prefix
  tags        = var.tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix           = local.name_prefix
  alb_security_group_id = module.security.alb_security_group_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  vpc_id                = module.vpc.vpc_id
  container_port        = var.container_port
  health_check_path     = var.health_check_path
  certificate_arn       = var.domain_name != "" ? module.certificate[0].certificate_arn : ""
  waf_web_acl_arn       = module.security.waf_web_acl_arn
  tags                  = var.tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix            = local.name_prefix
  aws_account_id         = var.aws_account_id
  aws_region             = var.aws_region
  container_port         = var.container_port
  dynamodb_table_name    = module.storage.dynamodb_table_name
  health_check_path      = var.health_check_path
  ecs_execution_role_arn = module.security.ecs_execution_role_arn
  ecs_task_role_arn      = module.security.ecs_task_role_arn
  private_subnet_ids     = module.vpc.private_subnet_ids
  ecs_security_group_id  = module.security.ecs_security_group_id
  target_group_blue_arn  = module.alb.blue_target_group_arn
  https_listener_arn     = module.alb.https_listener_arn
  tags                   = var.tags
}

module "codedeploy" {
  source = "../../modules/codedeploy"

  name_prefix             = local.name_prefix
  codedeploy_role_arn     = module.security.codedeploy_role_arn
  target_group_blue_name  = module.alb.blue_target_group_arn
  target_group_green_name = module.alb.green_target_group_arn
  https_listener_arn      = module.alb.https_listener_arn
  ecs_cluster_name        = module.ecs.ecs_cluster_name
  ecs_service_name        = module.ecs.ecs_service_name
  tags                    = var.tags
}

module "dns" {
  count  = var.domain_name != "" ? 1 : 0
  source = "../../modules/dns"

  domain_name  = var.domain_name
  subdomain    = var.subdomain
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  tags         = var.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix       = local.name_prefix
  aws_region        = var.aws_region
  ecs_service_name  = module.ecs.ecs_service_name
  ecs_cluster_name  = module.ecs.ecs_cluster_name
  alb_name          = module.alb.alb_dns_name
  target_group_name = module.alb.blue_target_group_arn
  tags              = var.tags
}

module "ssm" {
  source = "../../modules/ssm"

  name_prefix         = local.name_prefix
  dynamodb_table_name = module.storage.dynamodb_table_name
  tags                = var.tags
}
