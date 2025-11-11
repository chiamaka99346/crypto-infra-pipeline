variable "app_name" {
  description = "Application name used for secret and KMS key naming"
  type        = string
}

variable "tags" {
  description = "Additional tags for secrets resources"
  type        = map(string)
  default     = {}
}