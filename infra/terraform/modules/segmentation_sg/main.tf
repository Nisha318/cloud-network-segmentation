module "security_groups" {
  source = "../security_groups"

  name_prefix = var.name_prefix
  vpc_id      = var.vpc_id
  tags        = var.tags

  tiers = var.tiers
  rules = var.rules

  allow_app_https_egress = var.allow_app_https_egress
}
