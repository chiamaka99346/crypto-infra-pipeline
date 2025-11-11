variable "name" {
  description = "Name prefix for VPC resources"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "tags" {
  description = "Additional tags for VPC resources"
  type        = map(string)
  default     = {}
}