output "alb_dns_name" {
  value       = module.alb_dmz.alb_dns_name
  description = "Public ALB DNS name"
}
