variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS service will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ECS tasks"
  type        = list(string)
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "target_group_arn" {
  description = "ARN of the target group to attach the service to"
  type        = string
}

variable "environment" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets from Secrets Manager (map of name to ARN)"
  type        = map(string)
  default     = {}
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB to allow traffic from"
  type        = string
}

variable "tags" {
  description = "Additional tags for ECS resources"
  type        = map(string)
  default     = {}
}