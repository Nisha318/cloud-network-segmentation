output "alb_dns_name" {
  value = module.alb_dmz.alb_dns_name
}

output "alb_target_group_arn" {
  value = module.alb_dmz.target_group_arn
}
