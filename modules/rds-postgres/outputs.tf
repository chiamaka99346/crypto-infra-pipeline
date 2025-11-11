output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "Name of the default database"
  value       = "postgres"
}

output "rds_sg_id" {
  description = "Security group ID of the RDS instance"
  value       = aws_security_group.rds.id
}