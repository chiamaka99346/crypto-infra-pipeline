output "alb_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "tg_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "alb_sg_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}