output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "db_host" {
  value = "jdbc:postgresql://${aws_db_instance.app_db.endpoint}/${aws_db_instance.app_db.db_name}"
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.app_db.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.app_db.port
  sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.app_db.username
  sensitive   = true
}