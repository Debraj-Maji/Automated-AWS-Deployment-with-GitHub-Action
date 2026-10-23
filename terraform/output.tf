output "load_balancer_dns_name" {
  description = "The DNS name of the ALB to point Dynu record"
  value       = module.alb.dns_name
}

output "database_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.db.db_instance_endpoint
}