locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
  }
}

module "network_vpc" {
  source      = "../../modules/network_vpc"
  name_prefix = var.name_prefix
  tags        = local.common_tags

  # Use a different CIDR in dev
  vpc_cidr = "10.10.0.0/16"
}

module "flow_logs" {
  source      = "../../modules/flow_logs"
  name_prefix = var.name_prefix
  vpc_id      = module.network_vpc.vpc_id
  tags        = local.common_tags
}

module "microseg_sg" {
  source = "../../modules/security_groups"

  name_prefix = var.name_prefix
  vpc_id      = module.network_vpc.vpc_id
  tags        = local.common_tags

  tiers = var.policy_tiers
  rules = var.policy_rules

  allow_app_https_egress = var.allow_app_https_egress
}

module "alb_dmz" {
  source = "../../modules/alb_dmz"

  name_prefix     = var.name_prefix
  vpc_id          = module.network_vpc.vpc_id
  dmz_subnet_ids  = module.network_vpc.dmz_subnet_ids
  dmz_sg_id       = module.microseg_sg.sg_ids["dmz"]
  target_port     = 80
  tags            = local.common_tags
}
