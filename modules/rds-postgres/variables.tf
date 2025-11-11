variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "allow_from_sg_id" {
  description = "Security group ID to allow access from (optional)"
  type        = string
  default     = null
}

variable "master_username" {
  description = "Master username for RDS instance"
  type        = string
}

variable "master_password_arn" {
  description = "ARN of Secrets Manager secret containing master password JSON"
  type        = string
}

variable "tags" {
  description = "Additional tags for RDS resources"
  type        = map(string)
  default     = {}
}