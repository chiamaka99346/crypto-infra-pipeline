output "db_password_name" {
  description = "Name of the database password secret"
  value       = aws_secretsmanager_secret.db_password.name
}

output "db_password_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}