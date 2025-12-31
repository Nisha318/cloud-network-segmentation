locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

module "network_vpc" {
  source = "../../modules/network_vpc"

  name_prefix = local.name_prefix
  aws_region  = var.aws_region

  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  # Subnet sizing: keep it simple and predictable
  dmz_subnet_cidrs       = var.dmz_subnet_cidrs
  app_subnet_cidrs       = var.app_subnet_cidrs
  data_subnet_cidrs      = var.data_subnet_cidrs
  endpoints_subnet_cidrs = var.endpoints_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway

  tags = local.common_tags
}

module "flow_logs" {
  source = "../../modules/flow_logs"

  name_prefix = local.name_prefix

  vpc_id = module.network_vpc.vpc_id
  tags   = local.common_tags

  # Keep it CloudWatch first (easy). You can switch to S3/Athena later.
  retention_in_days = var.flow_logs_retention_in_days
}

module "microseg_sg" {
  source = "../../modules/security_groups"

  name_prefix = local.name_prefix
  vpc_id      = module.network_vpc.vpc_id
  tags        = local.common_tags

  tiers = var.policy_tiers
  rules = var.policy_rules

  allow_app_https_egress = var.allow_app_https_egress

}

module "alb_dmz" {
  source = "../../modules/alb_dmz"

  name_prefix = local.name_prefix
  vpc_id      = module.network_vpc.vpc_id

  public_subnet_ids = module.network_vpc.dmz_subnet_ids
  dmz_sg_id         = module.microseg_sg.security_group_ids["dmz"]

  tags = local.common_tags
}

module "app_ec2" {
  source = "../../modules/app_ec2"

  name_prefix = local.name_prefix
  vpc_id      = module.network_vpc.vpc_id

  app_subnet_ids   = module.network_vpc.app_subnet_ids
  app_sg_id        = module.microseg_sg.security_group_ids["app"]
  target_group_arn = module.alb_dmz.target_group_arn

  tags = local.common_tags
}
