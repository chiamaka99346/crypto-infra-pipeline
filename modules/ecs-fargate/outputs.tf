output "service_sg_id" {
  description = "Security group ID of the ECS service"
  value       = aws_security_group.service.id
}